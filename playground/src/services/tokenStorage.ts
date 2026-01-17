/**
 * Token Storage Service
 * Handles secure storage and retrieval of OAuth tokens in browser storage
 */

const TOKEN_STORAGE_KEY = 'oauth_tokens';
const TOKEN_EXPIRY_BUFFER = 60; // 60 seconds buffer before expiry

export interface TokenData {
    accessToken: string;
    refreshToken: string;
    idToken: string;
    expiresAt: number; // Unix timestamp in seconds
}

/**
 * Store tokens securely in localStorage
 */
export function storeTokens(tokens: TokenData): void {
    try {
        const tokenString = JSON.stringify(tokens);
        localStorage.setItem(TOKEN_STORAGE_KEY, tokenString);
    } catch (error) {
        console.error('Failed to store tokens:', error);
    }
}

/**
 * Retrieve access token from storage
 * Returns null if no token exists or if token is expired
 */
export function getAccessToken(): string | null {
    try {
        const tokenString = localStorage.getItem(TOKEN_STORAGE_KEY);
        if (!tokenString) {
            return null;
        }

        const tokens: TokenData = JSON.parse(tokenString);

        // Check if token is expired (with buffer)
        if (isTokenExpired()) {
            return null;
        }

        return tokens.accessToken;
    } catch (error) {
        console.error('Failed to retrieve access token:', error);
        return null;
    }
}

/**
 * Retrieve refresh token from storage
 */
export function getRefreshToken(): string | null {
    try {
        const tokenString = localStorage.getItem(TOKEN_STORAGE_KEY);
        if (!tokenString) {
            return null;
        }

        const tokens: TokenData = JSON.parse(tokenString);
        return tokens.refreshToken;
    } catch (error) {
        console.error('Failed to retrieve refresh token:', error);
        return null;
    }
}

/**
 * Retrieve ID token from storage
 */
export function getIdToken(): string | null {
    try {
        const tokenString = localStorage.getItem(TOKEN_STORAGE_KEY);
        if (!tokenString) {
            return null;
        }

        const tokens: TokenData = JSON.parse(tokenString);
        return tokens.idToken;
    } catch (error) {
        console.error('Failed to retrieve ID token:', error);
        return null;
    }
}

/**
 * Retrieve all tokens from storage
 */
export function getTokens(): TokenData | null {
    try {
        const tokenString = localStorage.getItem(TOKEN_STORAGE_KEY);
        if (!tokenString) {
            return null;
        }

        return JSON.parse(tokenString);
    } catch (error) {
        console.error('Failed to retrieve tokens:', error);
        return null;
    }
}

/**
 * Clear all tokens from storage (for logout)
 */
export function clearTokens(): void {
    try {
        localStorage.removeItem(TOKEN_STORAGE_KEY);
    } catch (error) {
        console.error('Failed to clear tokens:', error);
    }
}

/**
 * Check if the access token is expired
 * Returns true if expired or no token exists
 */
export function isTokenExpired(): boolean {
    try {
        const tokenString = localStorage.getItem(TOKEN_STORAGE_KEY);
        if (!tokenString) {
            return true;
        }

        const tokens: TokenData = JSON.parse(tokenString);
        const currentTime = Math.floor(Date.now() / 1000);

        // Consider token expired if within buffer time of expiry
        return currentTime >= (tokens.expiresAt - TOKEN_EXPIRY_BUFFER);
    } catch (error) {
        console.error('Failed to check token expiry:', error);
        return true;
    }
}

/**
 * Get time until token expires in seconds
 * Returns 0 if token is expired or doesn't exist
 */
export function getTimeUntilExpiry(): number {
    try {
        const tokenString = localStorage.getItem(TOKEN_STORAGE_KEY);
        if (!tokenString) {
            return 0;
        }

        const tokens: TokenData = JSON.parse(tokenString);
        const currentTime = Math.floor(Date.now() / 1000);
        const timeRemaining = tokens.expiresAt - currentTime;

        return Math.max(0, timeRemaining);
    } catch (error) {
        console.error('Failed to get time until expiry:', error);
        return 0;
    }
}
