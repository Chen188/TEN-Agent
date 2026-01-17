package internal

import (
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"math/big"
	"net/http"
	"sync"
	"time"
)

// JWKSCache caches JWKS keys from Cognito for JWT verification
type JWKSCache struct {
	keys      map[string]*rsa.PublicKey
	jwksURL   string
	mutex     sync.RWMutex
	expiresAt time.Time
	cacheTTL  time.Duration
}

// JWKS represents the JSON Web Key Set structure
type JWKS struct {
	Keys []JWK `json:"keys"`
}

// JWK represents a single JSON Web Key
type JWK struct {
	Kty string `json:"kty"`
	Kid string `json:"kid"`
	Use string `json:"use"`
	N   string `json:"n"`
	E   string `json:"e"`
	Alg string `json:"alg"`
}

// NewJWKSCache creates a new JWKS cache instance
func NewJWKSCache(jwksURL string) *JWKSCache {
	return &JWKSCache{
		keys:     make(map[string]*rsa.PublicKey),
		jwksURL:  jwksURL,
		cacheTTL: 1 * time.Hour, // Cache keys for 1 hour
	}
}

// GetKey retrieves a public key by key ID (kid)
func (c *JWKSCache) GetKey(kid string) (*rsa.PublicKey, error) {
	c.mutex.RLock()
	key, exists := c.keys[kid]
	expired := time.Now().After(c.expiresAt)
	c.mutex.RUnlock()

	if exists && !expired {
		return key, nil
	}

	// Refresh cache if key not found or cache expired
	if err := c.Refresh(); err != nil {
		return nil, fmt.Errorf("failed to refresh JWKS: %w", err)
	}

	c.mutex.RLock()
	key, exists = c.keys[kid]
	c.mutex.RUnlock()

	if !exists {
		return nil, fmt.Errorf("key with kid %s not found in JWKS", kid)
	}

	return key, nil
}

// Refresh fetches the latest JWKS from Cognito and updates the cache
func (c *JWKSCache) Refresh() error {
	if c.jwksURL == "" {
		return errors.New("JWKS URL not configured")
	}

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Get(c.jwksURL)
	if err != nil {
		return fmt.Errorf("failed to fetch JWKS: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("JWKS endpoint returned status %d", resp.StatusCode)
	}

	var jwks JWKS
	if err := json.NewDecoder(resp.Body).Decode(&jwks); err != nil {
		return fmt.Errorf("failed to decode JWKS: %w", err)
	}

	newKeys := make(map[string]*rsa.PublicKey)
	for _, jwk := range jwks.Keys {
		if jwk.Kty != "RSA" {
			continue
		}

		pubKey, err := jwkToRSAPublicKey(jwk)
		if err != nil {
			continue // Skip invalid keys
		}
		newKeys[jwk.Kid] = pubKey
	}

	c.mutex.Lock()
	c.keys = newKeys
	c.expiresAt = time.Now().Add(c.cacheTTL)
	c.mutex.Unlock()

	return nil
}

// jwkToRSAPublicKey converts a JWK to an RSA public key
func jwkToRSAPublicKey(jwk JWK) (*rsa.PublicKey, error) {
	// Decode the modulus (n)
	nBytes, err := base64.RawURLEncoding.DecodeString(jwk.N)
	if err != nil {
		return nil, fmt.Errorf("failed to decode modulus: %w", err)
	}

	// Decode the exponent (e)
	eBytes, err := base64.RawURLEncoding.DecodeString(jwk.E)
	if err != nil {
		return nil, fmt.Errorf("failed to decode exponent: %w", err)
	}

	// Convert exponent bytes to int
	var e int
	for _, b := range eBytes {
		e = e<<8 + int(b)
	}

	return &rsa.PublicKey{
		N: new(big.Int).SetBytes(nBytes),
		E: e,
	}, nil
}

// SetCacheTTL sets the cache time-to-live duration
func (c *JWKSCache) SetCacheTTL(ttl time.Duration) {
	c.mutex.Lock()
	c.cacheTTL = ttl
	c.mutex.Unlock()
}

// Clear clears the cache
func (c *JWKSCache) Clear() {
	c.mutex.Lock()
	c.keys = make(map[string]*rsa.PublicKey)
	c.expiresAt = time.Time{}
	c.mutex.Unlock()
}
