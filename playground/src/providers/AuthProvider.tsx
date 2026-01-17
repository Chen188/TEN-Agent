'use client';

import React, {
    createContext,
    useContext,
    useState,
    useEffect,
    useCallback,
    ReactNode,
} from 'react';
import {
    getAccessToken,
    getIdToken,
    clearTokens,
    isTokenExpired,
    getRefreshToken,
} from '../services/tokenStorage';
import {
    fetchOAuthConfig,
    getLoginUrl,
    getLogoutUrl,
    refreshAccessToken,
    generateState,
    storeState,
    parseTokensFromFragment,
    getAuthError,
} from '../services/oauthService';

export interface UserInfo {
    sub: string;
    email: string;
    username: string;
    groups: string[];
}

interface AuthContextType {
    isAuthenticated: boolean;
    user: UserInfo | null;
    isLoading: boolean;
    oauthEnabled: boolean;
    hasLoggedOut: boolean;
    login: () => void;
    logout: () => void;
    clearLogoutState: () => void;
    getAccessToken: () => string | null;
    refreshToken: () => Promise<boolean>;
}

// Key for tracking logout state across page reloads
const LOGOUT_STATE_KEY = 'astra-has-logged-out';

const AuthContext = createContext<AuthContextType | undefined>(undefined);

interface AuthProviderProps {
    children: ReactNode;
}

/**
 * Parse JWT token to extract user info
 */
function parseJwtPayload(token: string): UserInfo | null {
    try {
        const parts = token.split('.');
        if (parts.length !== 3) return null;

        const payload = JSON.parse(atob(parts[1]));
        return {
            sub: payload.sub || '',
            email: payload.email || '',
            username: payload['cognito:username'] || payload.email || '',
            groups: payload['cognito:groups'] || [],
        };
    } catch (error) {
        console.error('Failed to parse JWT:', error);
        return null;
    }
}


export function AuthProvider({ children }: AuthProviderProps) {
    const [isAuthenticated, setIsAuthenticated] = useState(false);
    const [user, setUser] = useState<UserInfo | null>(null);
    const [isLoading, setIsLoading] = useState(true);
    const [oauthEnabled, setOauthEnabled] = useState(false);
    const [hasLoggedOut, setHasLoggedOut] = useState(false);

    // Initialize hasLoggedOut from sessionStorage on mount
    useEffect(() => {
        try {
            const storedLogoutState = sessionStorage.getItem(LOGOUT_STATE_KEY);
            if (storedLogoutState === 'true') {
                setHasLoggedOut(true);
            }
        } catch (error) {
            // sessionStorage unavailable (e.g., private browsing), fall back to in-memory state
            console.warn('sessionStorage unavailable, using in-memory state for hasLoggedOut');
        }
    }, []);

    // Persist hasLoggedOut to sessionStorage when it changes
    useEffect(() => {
        try {
            if (hasLoggedOut) {
                sessionStorage.setItem(LOGOUT_STATE_KEY, 'true');
            } else {
                sessionStorage.removeItem(LOGOUT_STATE_KEY);
            }
        } catch (error) {
            // sessionStorage unavailable, state will only persist in memory
            console.warn('sessionStorage unavailable, hasLoggedOut state will not persist');
        }
    }, [hasLoggedOut]);

    // Initialize auth state
    useEffect(() => {
        const initAuth = async () => {
            try {
                // Check for auth error in URL (from failed OAuth)
                const authError = getAuthError();
                if (authError) {
                    console.error('OAuth error:', authError);
                    // Continue to show login page
                }

                // Check for tokens in URL fragment (from successful OAuth callback)
                // Backend redirects here with tokens in hash after exchanging code
                const fragmentTokens = parseTokensFromFragment();
                if (fragmentTokens) {
                    // Tokens were parsed and stored, now set user info
                    const userInfo = parseJwtPayload(fragmentTokens.idToken);
                    setUser(userInfo);
                    setIsAuthenticated(true);
                    setHasLoggedOut(false);
                    try {
                        sessionStorage.removeItem(LOGOUT_STATE_KEY);
                    } catch (e) {
                        // Ignore sessionStorage errors
                    }

                    // Fetch OAuth config for future use
                    try {
                        const config = await fetchOAuthConfig();
                        setOauthEnabled(config.oauthEnabled);
                    } catch (e) {
                        // Ignore config fetch errors, we already have tokens
                    }
                    setIsLoading(false);
                    return;
                }

                // Fetch OAuth config from server (only returns oauth_enabled)
                const config = await fetchOAuthConfig();
                setOauthEnabled(config.oauthEnabled);

                if (!config.oauthEnabled) {
                    // OAuth disabled, allow access without authentication
                    setIsAuthenticated(true);
                    setIsLoading(false);
                    return;
                }

                // Check for existing valid token
                const token = getAccessToken();
                if (token && !isTokenExpired()) {
                    const idToken = getIdToken();
                    if (idToken) {
                        const userInfo = parseJwtPayload(idToken);
                        setUser(userInfo);
                    }
                    setIsAuthenticated(true);
                } else if (getRefreshToken()) {
                    // Try to refresh the token via backend
                    try {
                        await refreshAccessToken(getRefreshToken()!);
                        const idToken = getIdToken();
                        if (idToken) {
                            const userInfo = parseJwtPayload(idToken);
                            setUser(userInfo);
                        }
                        setIsAuthenticated(true);
                    } catch (error) {
                        console.error('Token refresh failed:', error);
                        clearTokens();
                        setIsAuthenticated(false);
                    }
                }
            } catch (error) {
                console.error('Failed to initialize auth:', error);
                // If we can't fetch config, assume OAuth is disabled
                setOauthEnabled(false);
                setIsAuthenticated(true);
            } finally {
                setIsLoading(false);
            }
        };

        initAuth();
    }, []);

    // Login function - redirect to backend which redirects to Cognito
    const login = useCallback(() => {
        const state = generateState();
        storeState(state);
        window.location.href = getLoginUrl(state);
    }, []);

    // Logout function - clear tokens and redirect to backend which redirects to Cognito logout
    const logout = useCallback(() => {
        // Set hasLoggedOut flag BEFORE clearing tokens (Property 5)
        // This ensures the flag is persisted to sessionStorage before redirect
        setHasLoggedOut(true);
        try {
            sessionStorage.setItem(LOGOUT_STATE_KEY, 'true');
        } catch (error) {
            // sessionStorage unavailable, state will only persist in memory
            console.warn('sessionStorage unavailable during logout');
        }

        clearTokens();
        setIsAuthenticated(false);
        setUser(null);

        if (oauthEnabled) {
            window.location.href = getLogoutUrl();
        }
    }, [oauthEnabled]);

    // Clear logout state - called when user initiates login from LoginPage (Property 7)
    const clearLogoutState = useCallback(() => {
        setHasLoggedOut(false);
        try {
            sessionStorage.removeItem(LOGOUT_STATE_KEY);
        } catch (error) {
            // sessionStorage unavailable, state will only be cleared in memory
            console.warn('sessionStorage unavailable, clearLogoutState only cleared in memory');
        }
    }, []);

    // Get access token for API requests
    const getToken = useCallback((): string | null => {
        return getAccessToken();
    }, []);

    // Refresh token via backend
    const refreshToken = useCallback(async (): Promise<boolean> => {
        const refresh = getRefreshToken();
        if (!refresh) return false;

        try {
            await refreshAccessToken(refresh);
            const idToken = getIdToken();
            if (idToken) {
                const userInfo = parseJwtPayload(idToken);
                setUser(userInfo);
            }
            setIsAuthenticated(true);
            return true;
        } catch (error) {
            console.error('Token refresh failed:', error);
            clearTokens();
            setIsAuthenticated(false);
            setUser(null);
            return false;
        }
    }, []);

    const value: AuthContextType = {
        isAuthenticated,
        user,
        isLoading,
        oauthEnabled,
        hasLoggedOut,
        login,
        logout,
        clearLogoutState,
        getAccessToken: getToken,
        refreshToken,
    };

    return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextType {
    const context = useContext(AuthContext);
    if (context === undefined) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
}
