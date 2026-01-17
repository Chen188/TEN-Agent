"use client"

import { useMemo, useState, useRef, useEffect } from "react"
import dynamic from "next/dynamic"
import Chat from "@/components/chat"
import AuthInitializer from "@/components/authInitializer"
import { AuthGuard } from "@/components/authGuard"
import Menu from "@/components/menu"
import { getRandomUserId, getRandomChannel, useAppDispatch, useSmallScreen, useAppSelector } from "@/common"
import { setOptions } from "@/store/reducers/global"
import styles from "./index.module.scss"

const Rtc = dynamic(() => import("@/components/rtc"), {
  ssr: false,
})
const Header = dynamic(() => import("@/components/header"), {
  ssr: false,
})

export default function Home() {
  const dispatch = useAppDispatch()
  const chatItems = useAppSelector(state => state.global.chatItems)
  const wrapperRef = useRef<HTMLDivElement | null>(null)
  const [activeMenu, setActiveMenu] = useState("Chat")
  const { isSmallScreen } = useSmallScreen()

  useEffect(() => {
    // Set default user on initial load
    const defaultUsername = "DefaultUser"
    const userId = getRandomUserId()
    dispatch(setOptions({
      userName: defaultUsername,
      channel: getRandomChannel(),
      userId
    }))
  }, [dispatch])

  useEffect(() => {
    if (!wrapperRef.current) {
      return
    }
    if (!isSmallScreen) {
      return
    }
    wrapperRef.current.scrollTop = wrapperRef.current.scrollHeight
  }, [isSmallScreen, chatItems])

  const onMenuChange = (item: string) => {
    setActiveMenu(item)
  }

  return (
    <AuthGuard>
      <AuthInitializer>
        <main className={styles.home} style={{
          minHeight: isSmallScreen ? "auto" : "830px"
        }}>
          <Header></Header>
          {isSmallScreen ?
            <div className={styles.smallScreen}>
              <div className={styles.menuWrapper}>
                <Menu onChange={onMenuChange}></Menu>
              </div>
              <div className={styles.bodyWrapper}>
                <div className={styles.item} style={{
                  visibility: activeMenu == "Agent" ? "visible" : "hidden",
                  zIndex: activeMenu == "Agent" ? 1 : -1
                }}>
                  <Rtc></Rtc>
                </div>
                <div className={styles.item}
                  ref={wrapperRef}
                  style={{
                    visibility: activeMenu == "Chat" ? "visible" : "hidden",
                    zIndex: activeMenu == "Chat" ? 1 : -1
                  }}>
                  <Chat></Chat>
                </div>
              </div>
            </div>
            :
            <div className={styles.content} suppressHydrationWarning={true}>
              <Rtc></Rtc>
              <Chat></Chat>
            </div>
          }
        </main>
      </AuthInitializer>
    </AuthGuard>
  )
}
