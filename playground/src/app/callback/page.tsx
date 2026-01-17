'use client';

import { Suspense, useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';

/**
 * OAuth Callback Content Component
 * Separated to be wrapped in Suspense boundary
 */
function CallbackContent() {
    const router = useRouter();
    const searchParams = useSearchParams();
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        // Check for OAuth error in URL
        const errorParam = searchParams.get('error');
        const errorDescription = searchParams.get('error_description');
        const authError = searchParams.get('auth_error');

        if (errorParam || authError) {
            setError(errorDescription || authError || errorParam || 'Authentication failed');
            return;
        }

        // If there's a code, the old flow was used - redirect to home
        // The backend should be handling this now
        const code = searchParams.get('code');
        if (code) {
            // Old flow - redirect to home, user needs to login again
            console.warn('Received OAuth code at frontend callback - backend should handle this');
            router.push('/');
            return;
        }

        // No error and no code - just redirect to home
        router.push('/');
    }, [searchParams, router]);

    if (error) {
        return (
            <div style={styles.card}>
                <h2 style={styles.errorTitle}>Authentication Error</h2>
                <p style={styles.errorText}>{error}</p>
                <button
                    style={styles.button}
                    onClick={() => router.push('/')}
                >
                    Return to Home
                </button>
            </div>
        );
    }

    // Show loading while redirecting
    return (
        <div style={styles.card}>
            <style>
                {`
                    @keyframes callback-spin {
                        0% { transform: rotate(0deg); }
                        100% { transform: rotate(360deg); }
                    }
                `}
            </style>
            <div style={{
                width: '40px',
                height: '40px',
                border: '4px solid #272A2F',
                borderTop: '4px solid #0888FF',
                borderRadius: '50%',
                animation: 'callback-spin 1s linear infinite',
                margin: '0 auto 20px',
            }} />
            <h2 style={styles.title}>Redirecting...</h2>
        </div>
    );
}

/**
 * Loading fallback for Suspense
 */
function LoadingFallback() {
    return (
        <div style={styles.card}>
            <style>
                {`
                    @keyframes callback-spin {
                        0% { transform: rotate(0deg); }
                        100% { transform: rotate(360deg); }
                    }
                `}
            </style>
            <div style={{
                width: '40px',
                height: '40px',
                border: '4px solid #272A2F',
                borderTop: '4px solid #0888FF',
                borderRadius: '50%',
                animation: 'callback-spin 1s linear infinite',
                margin: '0 auto 20px',
            }} />
            <h2 style={styles.title}>Loading...</h2>
        </div>
    );
}

/**
 * OAuth Callback Page
 * 
 * With the new flow, backend handles the OAuth callback at /oauth/callback
 * and redirects to frontend root (/) with tokens in URL fragment.
 * 
 * This page is kept for backwards compatibility and error handling.
 * If user lands here with an error, we display it.
 * Otherwise, redirect to home where AuthProvider handles tokens.
 */
export default function CallbackPage() {
    return (
        <div style={styles.container}>
            <Suspense fallback={<LoadingFallback />}>
                <CallbackContent />
            </Suspense>
        </div>
    );
}

const styles: { [key: string]: React.CSSProperties } = {
    container: {
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        minHeight: '100vh',
        background: 'linear-gradient(180deg, #0F0F11 0%, #1A1A1F 100%)',
    },
    card: {
        backgroundColor: '#181A1D',
        padding: '40px',
        borderRadius: '20px',
        border: '1px solid #20272D',
        boxShadow: '0px 4px 48px 0px rgba(0, 7, 72, 0.12)',
        textAlign: 'center',
        maxWidth: '400px',
    },
    title: {
        margin: '0 0 10px',
        color: '#EAECF0',
        fontSize: '20px',
        fontWeight: 600,
    },
    errorTitle: {
        margin: '0 0 10px',
        color: '#e74c3c',
        fontSize: '20px',
    },
    errorText: {
        margin: '0 0 20px',
        color: '#98A2B3',
        fontSize: '14px',
    },
    button: {
        backgroundColor: '#0888FF',
        color: 'white',
        border: 'none',
        padding: '12px 24px',
        borderRadius: '8px',
        cursor: 'pointer',
        fontSize: '14px',
        fontWeight: 500,
    },
};
