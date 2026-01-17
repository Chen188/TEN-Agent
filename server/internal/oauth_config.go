package internal

import (
	"errors"
	"fmt"
	"os"
	"strings"
)

// OAuthConfig holds all OAuth/Cognito configuration parameters
type OAuthConfig struct {
	Enabled       bool   `json:"oauth_enabled"`
	AuthorizeURL  string `json:"oauth_authorize_url"`
	TokenURL      string `json:"oauth_token_url"`
	UserInfoURL   string `json:"oauth_userinfo_url"`
	LogoutURL     string `json:"oauth_logout_url"`
	ClientID      string `json:"cognito_client_id"`
	ClientSecret  string `json:"cognito_client_secret"`
	UserPoolID    string `json:"cognito_user_pool_id"`
	CognitoDomain string `json:"cognito_domain"`
	RedirectURL   string `json:"oauth_redirect_url"`
	FrontendURL   string `json:"frontend_url"`
	Region        string `json:"cognito_region"`
	JwksURL       string `json:"jwks_url"`
}

// LoadOAuthConfig loads OAuth configuration from environment variables
func LoadOAuthConfig() *OAuthConfig {
	config := &OAuthConfig{
		Enabled:       getEnvBool("OAUTH_ENABLED", false),
		AuthorizeURL:  getEnv("OAUTH_AUTHORIZE_URL", ""),
		TokenURL:      getEnv("OAUTH_TOKEN_URL", ""),
		UserInfoURL:   getEnv("OAUTH_USERINFO_URL", ""),
		LogoutURL:     getEnv("OAUTH_LOGOUT_URL", ""),
		ClientID:      getEnv("COGNITO_CLIENT_ID", ""),
		ClientSecret:  getEnv("COGNITO_CLIENT_SECRET", ""),
		UserPoolID:    getEnv("COGNITO_USER_POOL_ID", ""),
		CognitoDomain: getEnv("COGNITO_DOMAIN", ""),
		RedirectURL:   getEnv("OAUTH_REDIRECT_URL", ""),
		FrontendURL:   getEnv("FRONTEND_URL", "http://localhost:3000"),
		Region:        getEnv("COGNITO_REGION", "us-east-1"),
	}

	// Build JWKS URL from user pool ID and region if not explicitly set
	if config.UserPoolID != "" && config.Region != "" {
		config.JwksURL = fmt.Sprintf(
			"https://cognito-idp.%s.amazonaws.com/%s/.well-known/jwks.json",
			config.Region,
			config.UserPoolID,
		)
	}

	// Build default URLs from Cognito domain if not explicitly set
	if config.CognitoDomain != "" {
		if config.AuthorizeURL == "" {
			config.AuthorizeURL = fmt.Sprintf("https://%s/oauth2/authorize", config.CognitoDomain)
		}
		if config.TokenURL == "" {
			config.TokenURL = fmt.Sprintf("https://%s/oauth2/token", config.CognitoDomain)
		}
		if config.UserInfoURL == "" {
			config.UserInfoURL = fmt.Sprintf("https://%s/oauth2/userInfo", config.CognitoDomain)
		}
		if config.LogoutURL == "" {
			config.LogoutURL = fmt.Sprintf("https://%s/logout", config.CognitoDomain)
		}
	}

	return config
}

// Validate checks if all required OAuth parameters are present when enabled
func (c *OAuthConfig) Validate() error {
	if !c.Enabled {
		return nil
	}

	var missingFields []string

	if c.AuthorizeURL == "" {
		missingFields = append(missingFields, "oauth_authorize_url")
	}
	if c.ClientID == "" {
		missingFields = append(missingFields, "cognito_client_id")
	}
	if c.UserPoolID == "" {
		missingFields = append(missingFields, "cognito_user_pool_id")
	}
	if c.RedirectURL == "" {
		missingFields = append(missingFields, "oauth_redirect_url")
	}

	if len(missingFields) > 0 {
		return errors.New("missing required OAuth configuration: " + strings.Join(missingFields, ", "))
	}

	return nil
}

// GetIssuerURL returns the expected JWT issuer URL for the configured Cognito user pool
func (c *OAuthConfig) GetIssuerURL() string {
	if c.UserPoolID == "" || c.Region == "" {
		return ""
	}
	return fmt.Sprintf("https://cognito-idp.%s.amazonaws.com/%s", c.Region, c.UserPoolID)
}

// getEnv retrieves an environment variable with a default fallback
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// getEnvBool retrieves a boolean environment variable with a default fallback
func getEnvBool(key string, defaultValue bool) bool {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return strings.ToLower(value) == "true" || value == "1"
}
