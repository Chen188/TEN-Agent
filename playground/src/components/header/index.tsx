"use client"

import { useAppSelector, GITHUB_URL, useSmallScreen } from "@/common"
import Network from "./network"
import { GithubIcon, LogoIcon } from "@/components/icons"
import { InfoCircleOutlined, QuestionCircleOutlined, LogoutOutlined, UserOutlined, DownOutlined, MailOutlined } from "@ant-design/icons"
import { Popover, Dropdown } from "antd"
import type { MenuProps } from "antd"
import InfoPopup from "./InfoPopup"
import DescriptionPopup from "./DescriptionPopup"
import SettingsDialog from "./SettingsDialog"
import ConnectButton, { ConnectButtonRef } from "./ConnectButton"
import { useAuth } from "@/providers/AuthProvider"

import styles from "./index.module.scss"
import { useMemo, useState, useRef } from "react"

const Header = () => {
  const options = useAppSelector(state => state.global.options)
  const { channel } = options
  const { isSmallScreen } = useSmallScreen()
  const [settingsOpen, setSettingsOpen] = useState(false)
  const [settingsOpenForConnect, setSettingsOpenForConnect] = useState(false)
  const { user, oauthEnabled, logout } = useAuth()
  const connectButtonRef = useRef<ConnectButtonRef>(null)

  const channelNameText = useMemo(() => {
    return !isSmallScreen ? `Channel Name：${channel}` : channel
  }, [isSmallScreen, channel])

  // Clean username by removing "midway_" prefix
  const displayName = useMemo(() => {
    if (!user?.username) return ''
    return user.username.replace(/^midway_/i, '')
  }, [user?.username])

  const onClickGithub = () => {
    if (typeof window !== "undefined") {
      window.open(GITHUB_URL, "_blank")
    }
  }

  // Handler for when Connect button is clicked while disconnected
  // Opens the settings dialog with connectMode=true instead of connecting directly
  const handleConnectClick = () => {
    setSettingsOpenForConnect(true)
    setSettingsOpen(true)
  }

  // Handler for when Connect is clicked in the settings dialog
  // Triggers the actual connection via ConnectButton's triggerConnect
  const handleSettingsConnect = () => {
    if (connectButtonRef.current) {
      connectButtonRef.current.triggerConnect()
    }
  }

  // Handler for closing the settings dialog
  const handleSettingsClose = () => {
    setSettingsOpen(false)
    setSettingsOpenForConnect(false)
  }

  // User dropdown menu items with user info header
  const userMenuItems: MenuProps['items'] = [
    {
      key: 'user-info',
      label: (
        <div className={styles.userMenuHeader}>
          {user?.email && <div className={styles.userMenuEmail}><MailOutlined /> {user.email}</div>}
        </div>
      ),
      disabled: true,
    },
    { type: 'divider' },
    {
      key: 'logout',
      icon: <LogoutOutlined />,
      label: 'Logout',
      onClick: () => logout(),
    },
  ]

  return <div className={styles.header}>
    <span className={styles.logoWrapper}>
      <LogoIcon></LogoIcon>
    </span>
    <span className={styles.content}>{channelNameText}</span>
    <div className={styles.rightSection}>
      <span onClick={onClickGithub} className={styles.githubWrapper}>
        <GithubIcon></GithubIcon>
      </span>
      <Network></Network>
      <Popover content={<InfoPopup />} trigger="click" placement="bottom">
        <span className={styles.iconWrapper}>
          <InfoCircleOutlined />
        </span>
      </Popover>
      <Popover content={<DescriptionPopup />} trigger="click" placement="bottom">
        <span className={styles.iconWrapper}>
          <QuestionCircleOutlined />
        </span>
      </Popover>
      {/* User dropdown with logout when OAuth is enabled */}
      {oauthEnabled && user && (
        <Dropdown menu={{ items: userMenuItems }} trigger={['click']} placement="bottomRight">
          <span className={styles.userDropdown}>
            <UserOutlined />
            <span className={styles.userName}>{displayName}</span>
            <DownOutlined className={styles.dropdownArrow} />
          </span>
        </Dropdown>
      )}
      <ConnectButton ref={connectButtonRef} onConnectClick={handleConnectClick} />
    </div>
    <SettingsDialog
      open={settingsOpen}
      onClose={handleSettingsClose}
      connectMode={settingsOpenForConnect}
      onConnect={handleSettingsConnect}
    />
  </div>
}


export default Header
