/**
 * OAuth Service
 * Handles OAuth 2.0 authorization code flow with Cognito
 * Backend handles all OAuth - frontend only needs oauth_enabled flag
 */

import { storeTokens, TokenData } from './tokenStorage';

export interface OAuthConfig {
    oauthEnabled: boolean;
}

// Cache for OAuth config
let cachedConfig: OAuthConfig | null = null;

// Get base URL for API requests
const getBaseUrl = () => process.env.NEXT_PUBLIC_REQUEST_URL || 'http://localhost:8080';

/**
 * Fetch OAuth configuration from the server
 * Only returns oauth_enabled - all OAuth URLs are handled by backend
 */
export async function fetchOAuthConfig(): Promise<OAuthConfig> {
    if (cachedConfig) {
        return cachedConfig;
    }

    const response = await fetch(`${getBaseUrl()}/oauth/config`);

    if (!response.ok) {
        throw new Error('Failed to fetch OAuth configuration');
    }

    const result = await response.json();

    if (result.code !== '0') {
        throw new Error(result.msg || 'Failed to fetch OAuth configuration');
    }

    cachedConfig = {
        oauthEnabled: result.data.oauth_enabled,
    };

    return cachedConfig;
}

/**
 * Clear cached OAuth config (useful for testing or config changes)
 */
export function clearOAuthConfigCache(): void {
    cachedConfig = null;
}

/**
 * Get the login URL - backend handles the redirect to Cognito
 */
export function getLoginUrl(state?: string): string {
    const params = new URLSearchParams();
    if (state) {
        params.append('state', state);
    }
    const queryString = params.toString();
    return `${getBaseUrl()}/oauth/login${queryString ? `?${queryString}` : ''}`;
}

/**
 * Get the logout URL - backend handles the redirect to Cognito
 */
export function getLogoutUrl(): string {
    return `${getBaseUrl()}/oauth/logout`;
}

/**
 * Parse tokens from URL fragment (hash)
 * Backend redirects here with tokens after successful OAuth
 */
export function parseTokensFromFragment(): TokenData | null {
    if (typeof window === 'undefined') return null;

    const hash = window.location.hash.substring(1); // Remove the #
    if (!hash) return null;

    const params = new URLSearchParams(hash);
    const accessToken = params.get('access_token');
    const idToken = params.get('id_token');
    const refreshToken = params.get('refresh_token');
    const expiresIn = params.get('expires_in');

    if (!accessToken || !idToken) return null;

    const expiresAt = Math.floor(Date.now() / 1000) + (parseInt(expiresIn || '3600', 10));

    const tokenData: TokenData = {
        accessToken,
        idToken,
        refreshToken: refreshToken || '',
        expiresAt,
    };

    // Store tokens
    storeTokens(tokenData);

    // Clear the hash from URL (security - don't leave tokens in URL)
    window.history.replaceState(null, '', window.location.pathname + window.location.search);

    return tokenData;
}

/**
 * Check for auth error in URL query params
 */
export function getAuthError(): string | null {
    if (typeof window === 'undefined') return null;

    const params = new URLSearchParams(window.location.search);
    const error = params.get('auth_error');

    if (error) {
        // Clear the error from URL
        window.history.replaceState(null, '', window.location.pathname);
    }

    return error;
}

/**
 * Refresh access token using refresh token via backend
 */
export async function refreshAccessToken(refreshToken: string): Promise<TokenData> {
    const response = await fetch(`${getBaseUrl()}/oauth/refresh`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ refresh_token: refreshToken }),
    });

    if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Token refresh failed: ${errorText}`);
    }

    const result = await response.json();

    if (result.code !== '0') {
        throw new Error(result.msg || 'Token refresh failed');
    }

    const tokenResponse = result.data;

    // Calculate expiration timestamp
    const expiresAt = Math.floor(Date.now() / 1000) + tokenResponse.expires_in;

    const tokenData: TokenData = {
        accessToken: tokenResponse.access_token,
        refreshToken: tokenResponse.refresh_token || refreshToken,
        idToken: tokenResponse.id_token,
        expiresAt,
    };

    // Store updated tokens
    storeTokens(tokenData);

    return tokenData;
}

/**
 * Generate a random state parameter for CSRF protection
 */
export function generateState(): string {
    const array = new Uint8Array(32);
    crypto.getRandomValues(array);
    return Array.from(array, (byte) => byte.toString(16).padStart(2, '0')).join('');
}

/**
 * Store state in sessionStorage for verification
 */
export function storeState(state: string): void {
    sessionStorage.setItem('oauth_state', state);
}

/**
 * Verify and clear state from sessionStorage
 */
export function verifyState(state: string): boolean {
    const storedState = sessionStorage.getItem('oauth_state');
    sessionStorage.removeItem('oauth_state');
    return storedState === state;
}
