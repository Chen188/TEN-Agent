package internal

import (
	"crypto"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/sha512"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
)

// AuthMiddleware handles JWT token validation for protected endpoints
type AuthMiddleware struct {
	config    *OAuthConfig
	jwksCache *JWKSCache
}

// UserClaims represents the authenticated user information extracted from JWT
type UserClaims struct {
	Subject   string   `json:"sub"`
	Email     string   `json:"email"`
	Username  string   `json:"cognito:username"`
	Groups    []string `json:"cognito:groups"`
	ExpiresAt int64    `json:"exp"`
	IssuedAt  int64    `json:"iat"`
	Issuer    string   `json:"iss"`
	Audience  string   `json:"aud"`
	TokenUse  string   `json:"token_use"`
}

// AuthError represents an authentication error response
type AuthError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Details string `json:"details,omitempty"`
}

// ValidationError represents a token validation error
type ValidationError struct {
	Code    string
	Message string
}

func (e *ValidationError) Error() string {
	return e.Message
}

// Error codes
const (
	AuthMissingToken     = "AUTH_MISSING_TOKEN"
	AuthInvalidFormat    = "AUTH_INVALID_FORMAT"
	AuthInvalidSignature = "AUTH_INVALID_SIGNATURE"
	AuthTokenExpired     = "AUTH_TOKEN_EXPIRED"
	AuthInvalidIssuer    = "AUTH_INVALID_ISSUER"
	AuthInvalidAudience  = "AUTH_INVALID_AUDIENCE"
	AuthJWKSError        = "AUTH_JWKS_ERROR"
)

// Context key for user claims
const UserClaimsKey = "user_claims"

// NewAuthMiddleware creates a new authentication middleware instance
func NewAuthMiddleware(config *OAuthConfig) *AuthMiddleware {
	var jwksCache *JWKSCache
	if config.JwksURL != "" {
		jwksCache = NewJWKSCache(config.JwksURL)
	}

	return &AuthMiddleware{
		config:    config,
		jwksCache: jwksCache,
	}
}

// Authenticate is the Gin middleware handler for JWT validation
func (m *AuthMiddleware) Authenticate() gin.HandlerFunc {
	return func(c *gin.Context) {
		// If OAuth is disabled, allow all requests
		if !m.config.Enabled {
			c.Next()
			return
		}

		// Extract token from Authorization header
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			slog.Error("Missing Authorization header", logTag)
			m.abortWithAuthError(c, AuthMissingToken, "Authorization token required", "")
			return
		}

		slog.Info("Received Authorization header", "length", len(authHeader), logTag)

		// Validate Bearer token format
		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
			slog.Error("Invalid token format", "parts", len(parts), logTag)
			m.abortWithAuthError(c, AuthInvalidFormat, "Invalid token format", "Expected: Bearer <token>")
			return
		}

		tokenString := parts[1]
		slog.Info("Token received", "tokenLength", len(tokenString), logTag)

		// Validate token and extract claims
		claims, err := m.ValidateToken(tokenString)
		if err != nil {
			m.handleValidationError(c, err)
			return
		}

		// Store claims in context for downstream handlers
		c.Set(UserClaimsKey, claims)

		// Log authenticated user for audit
		slog.Info("authenticated request",
			"user", claims.Username,
			"email", claims.Email,
			"subject", claims.Subject,
			logTag,
		)

		c.Next()
	}
}

// ValidateToken validates a JWT token and returns claims
func (m *AuthMiddleware) ValidateToken(tokenString string) (*UserClaims, error) {
	// Parse JWT without verification first to get header
	parts := strings.Split(tokenString, ".")
	if len(parts) != 3 {
		return nil, &ValidationError{Code: AuthInvalidFormat, Message: "Invalid JWT format"}
	}

	// Decode header to get key ID
	headerJSON, err := base64.RawURLEncoding.DecodeString(parts[0])
	if err != nil {
		return nil, &ValidationError{Code: AuthInvalidFormat, Message: "Failed to decode JWT header"}
	}

	var header struct {
		Kid string `json:"kid"`
		Alg string `json:"alg"`
	}
	if err := json.Unmarshal(headerJSON, &header); err != nil {
		return nil, &ValidationError{Code: AuthInvalidFormat, Message: "Failed to parse JWT header"}
	}

	// Get public key from JWKS cache
	if m.jwksCache == nil {
		return nil, &ValidationError{Code: AuthJWKSError, Message: "JWKS not configured"}
	}

	publicKey, err := m.jwksCache.GetKey(header.Kid)
	if err != nil {
		return nil, &ValidationError{Code: AuthJWKSError, Message: "Unable to verify token"}
	}

	// Verify signature
	if err := m.verifySignature(tokenString, publicKey, header.Alg); err != nil {
		return nil, &ValidationError{Code: AuthInvalidSignature, Message: "Token signature verification failed"}
	}

	// Decode and validate claims
	claimsJSON, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return nil, &ValidationError{Code: AuthInvalidFormat, Message: "Failed to decode JWT claims"}
	}

	var claims UserClaims
	if err := json.Unmarshal(claimsJSON, &claims); err != nil {
		return nil, &ValidationError{Code: AuthInvalidFormat, Message: "Failed to parse JWT claims"}
	}

	// Validate expiration
	if time.Now().Unix() > claims.ExpiresAt {
		return nil, &ValidationError{Code: AuthTokenExpired, Message: "Token has expired"}
	}

	// Validate issuer
	expectedIssuer := m.config.GetIssuerURL()
	if expectedIssuer != "" && claims.Issuer != expectedIssuer {
		slog.Error("Token issuer mismatch", "expected", expectedIssuer, "got", claims.Issuer, logTag)
		return nil, &ValidationError{Code: AuthInvalidIssuer, Message: "Token issuer mismatch"}
	}

	// Note: Cognito access tokens have audience set to user pool ID, not client ID
	// So we skip audience validation for access tokens
	// The issuer validation is sufficient for security

	return &claims, nil
}

// verifySignature verifies the JWT signature using the public key
func (m *AuthMiddleware) verifySignature(tokenString string, publicKey *rsa.PublicKey, alg string) error {
	parts := strings.Split(tokenString, ".")
	if len(parts) != 3 {
		return errors.New("invalid token format")
	}

	// The message to verify is header.payload
	message := parts[0] + "." + parts[1]

	// Decode signature
	signature, err := base64.RawURLEncoding.DecodeString(parts[2])
	if err != nil {
		return fmt.Errorf("failed to decode signature: %w", err)
	}

	// Verify based on algorithm
	switch alg {
	case "RS256":
		return verifyRS256([]byte(message), signature, publicKey)
	case "RS384":
		return verifyRS384([]byte(message), signature, publicKey)
	case "RS512":
		return verifyRS512([]byte(message), signature, publicKey)
	default:
		return fmt.Errorf("unsupported algorithm: %s", alg)
	}
}

// verifyRS256 verifies an RS256 signature
func verifyRS256(message, signature []byte, publicKey *rsa.PublicKey) error {
	hash := sha256.Sum256(message)
	return rsa.VerifyPKCS1v15(publicKey, crypto.SHA256, hash[:], signature)
}

// verifyRS384 verifies an RS384 signature
func verifyRS384(message, signature []byte, publicKey *rsa.PublicKey) error {
	hash := sha512.Sum384(message)
	return rsa.VerifyPKCS1v15(publicKey, crypto.SHA384, hash[:], signature)
}

// verifyRS512 verifies an RS512 signature
func verifyRS512(message, signature []byte, publicKey *rsa.PublicKey) error {
	hash := sha512.Sum512(message)
	return rsa.VerifyPKCS1v15(publicKey, crypto.SHA512, hash[:], signature)
}

// abortWithAuthError sends an authentication error response
func (m *AuthMiddleware) abortWithAuthError(c *gin.Context, code, message, details string) {
	c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
		"code":    code,
		"message": message,
		"details": details,
	})
}

// handleValidationError handles validation errors and sends appropriate response
func (m *AuthMiddleware) handleValidationError(c *gin.Context, err error) {
	var validationErr *ValidationError
	if errors.As(err, &validationErr) {
		slog.Error("Token validation failed", "code", validationErr.Code, "message", validationErr.Message, logTag)
		m.abortWithAuthError(c, validationErr.Code, validationErr.Message, "")
		return
	}
	slog.Error("Token validation failed", "error", err.Error(), logTag)
	m.abortWithAuthError(c, AuthInvalidSignature, "Token validation failed", err.Error())
}

// GetUserClaims retrieves user claims from the Gin context
func GetUserClaims(c *gin.Context) (*UserClaims, bool) {
	claims, exists := c.Get(UserClaimsKey)
	if !exists {
		return nil, false
	}
	userClaims, ok := claims.(*UserClaims)
	return userClaims, ok
}
