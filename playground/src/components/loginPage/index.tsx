"use client"

import { LogoIcon } from "@/components/icons"
import { useAuth } from "@/providers/AuthProvider"
import styles from "./index.module.scss"

/**
 * LoginPage Component
 * 
 * Displays a login page for OAuth users with a "Login with Midway" button.
 * This page is shown when OAuth is enabled and the user is not authenticated,
 * instead of auto-redirecting to the OAuth provider.
 * 
 * Property 10: For any click on the "Login with Midway" button, the system 
 * SHALL call the login function which redirects to the OAuth provider.
 * 
 * Requirements: 5.1, 5.2, 5.3
 */
const LoginPage = () => {
    const { login, clearLogoutState } = useAuth()

    const handleLogin = () => {
        // Clear logout state before initiating login (Property 7)
        clearLogoutState()
        // Redirect to OAuth provider (Property 10)
        login()
    }

    return (
        <div className={styles.loginPage}>
            <div className={styles.container}>
                <div className={styles.logoWrapper}>
                    <LogoIcon transform="scale(2 2)" />
                </div>
                <h1 className={styles.title}>Welcome to TEN Playground</h1>
                <p className={styles.subtitle}>Please sign in to continue</p>
                <button className={styles.loginButton} onClick={handleLogin}>
                    Login with Midway
                </button>
            </div>
        </div>
    )
}

export default LoginPage
