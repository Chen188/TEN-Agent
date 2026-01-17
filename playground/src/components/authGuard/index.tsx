'use client';

import React, { ReactNode } from 'react';
import { useAuth } from '../../providers/AuthProvider';
import LoginPage from '../loginPage';

interface AuthGuardProps {
    children: ReactNode;
    fallback?: ReactNode;
}

/**
 * AuthGuard component that protects routes when OAuth is enabled
 * - When OAuth is disabled: renders children immediately
 * - When OAuth is enabled and authenticated: renders children
 * - When OAuth is enabled and not authenticated: renders LoginPage
 * - While loading: shows fallback or loading indicator
 */
export function AuthGuard({ children, fallback }: AuthGuardProps) {
    const { isAuthenticated, isLoading, oauthEnabled } = useAuth();

    // Show loading state
    if (isLoading) {
        return fallback || <LoadingSpinner />;
    }

    // If OAuth is disabled, allow access
    if (!oauthEnabled) {
        return <>{children}</>;
    }

    // If authenticated, render children
    if (isAuthenticated) {
        return <>{children}</>;
    }

    // Render LoginPage for unauthenticated users (instead of auto-redirecting)
    return <LoginPage />;
}

/**
 * Simple loading spinner component
 */
function LoadingSpinner() {
    return (
        <div
            style={{
                display: 'flex',
                justifyContent: 'center',
                alignItems: 'center',
                height: '100vh',
                width: '100vw',
                background: 'linear-gradient(180deg, #0F0F11 0%, #1A1A1F 100%)',
            }}
        >
            <style>
                {`
                    @keyframes authguard-spin {
                        0% { transform: rotate(0deg); }
                        100% { transform: rotate(360deg); }
                    }
                `}
            </style>
            <div
                style={{
                    width: '40px',
                    height: '40px',
                    border: '4px solid #272A2F',
                    borderTop: '4px solid #0888FF',
                    borderRadius: '50%',
                    animation: 'authguard-spin 1s linear infinite',
                }}
            />
        </div>
    );
}

export default AuthGuard;
