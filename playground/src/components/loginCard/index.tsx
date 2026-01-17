"use client"

import { version } from "../../../package.json"
import { useRouter } from 'next/navigation'
import { message } from "antd"
import { ChangeEvent, InputHTMLAttributes, useState } from "react"
import { GithubIcon, LogoIcon } from "../icons"
import { GITHUB_URL, getRandomUserId, useAppDispatch, getRandomChannel } from "@/common"
import { setOptions } from "@/store/reducers/global"
import { useAuth } from "@/providers/AuthProvider"
import styles from "./index.module.scss"

const LoginCard = () => {
  const dispatch = useAppDispatch()
  const router = useRouter()
  const [userName, setUserName] = useState("")
  const { oauthEnabled, isAuthenticated, user, login, isLoading } = useAuth()

  const onClickGithub = () => {
    if (typeof window !== "undefined") {
      window.open(GITHUB_URL, "_blank")
    }
  }

  const onUserNameChange = (e: any) => {
    let value = e.target.value
    value = value.replace(/\s/g, "");
    setUserName(value)
  }

  const onClickOAuthLogin = () => {
    login()
  }

  const onClickJoin = () => {
    // If OAuth is enabled, use the authenticated user's name
    const effectiveUserName = oauthEnabled && user ? user.username : userName

    if (!effectiveUserName) {
      message.error("please input user name")
      return
    }
    const userId = getRandomUserId()
    dispatch(setOptions({
      userName: effectiveUserName,
      channel: getRandomChannel(),
      userId
    }))
    router.push("/home")
  }

  // Show loading state
  if (isLoading) {
    return <div className={styles.card}>
      <section className={styles.content}>
        <div className={styles.title}>
          <LogoIcon transform="scale(1.5 1.5)"></LogoIcon>
          <span className={styles.text}>Loading...</span>
        </div>
      </section>
    </div>
  }


  return <div className={styles.card}>
    <section className={styles.top}>
      <span className={styles.github} onClick={onClickGithub}>
        <GithubIcon></GithubIcon>
        <span className={styles.text}>GitHub</span>
      </span>
    </section>
    <section className={styles.content}>
      <div className={styles.title}>
        <LogoIcon transform="scale(1.5 1.5)"></LogoIcon>
        <span className={styles.text}>ASTRA.ai Agents Playground</span>
      </div>
      {/* Show OAuth login button when OAuth is enabled and not authenticated */}
      {oauthEnabled && !isAuthenticated ? (
        <div className={styles.section}>
          <div className={styles.btn} onClick={onClickOAuthLogin}>
            <span className={styles.btnText}>Sign in with SSO</span>
          </div>
        </div>
      ) : (
        <>
          {/* Show username input only when OAuth is disabled */}
          {!oauthEnabled && (
            <div className={styles.section}>
              <input placeholder="User Name" value={userName} onChange={onUserNameChange} ></input>
            </div>
          )}
          {/* Show welcome message when OAuth authenticated */}
          {oauthEnabled && user && (
            <div className={styles.section}>
              <span className={styles.welcomeText}>Welcome, {user.username}</span>
            </div>
          )}
          <div className={styles.section}>
            <div className={styles.btn} onClick={onClickJoin}>
              <span className={styles.btnText}>Join</span>
            </div>
          </div>
        </>
      )}
      <div className={styles.version}>Version {version}</div>
    </section >
  </div >
}

export default LoginCard
