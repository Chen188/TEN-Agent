import { useState, useEffect, useImperativeHandle, forwardRef } from "react"
import {
    useAppSelector,
    useAppDispatch,
    apiStartService,
    apiStopService,
    apiPing,
    GRAPH_NAME_OPTIONS,
    LANG_OPTIONS
} from "@/common"
import { setAgentConnected } from "@/store/reducers/global"
import { LoadingOutlined } from "@ant-design/icons"
import { Modal } from "antd"
import styles from "./index.module.scss"

let intervalId: any

interface ConnectButtonProps {
    onConnectClick?: () => void;  // Override default connect behavior
}

export interface ConnectButtonRef {
    triggerConnect: () => Promise<void>;
}

const ConnectButton = forwardRef<ConnectButtonRef, ConnectButtonProps>(({ onConnectClick }, ref) => {
    const dispatch = useAppDispatch()
    const agentConnected = useAppSelector(state => state.global.agentConnected)
    const channel = useAppSelector(state => state.global.options.channel)
    const userId = useAppSelector(state => state.global.options.userId)
    const options = useAppSelector(state => state.global.options)
    const [loading, setLoading] = useState(false)
    const [mode, setMode] = useState("chat")
    const [graphName, setGraphName] = useState(GRAPH_NAME_OPTIONS[0]['value'])
    const [lang, setLang] = useState(LANG_OPTIONS[0]['value'])
    const [outputLanguage, setOutputLanguage] = useState(lang)
    const [partialStabilization, setPartialStabilization] = useState(false)
    const [voice, setVoice] = useState("male")
    const [greeting, setGreeting] = useState("")
    const [mcpSelectedServers, setMcpSelectedServers] = useState<string[]>([])
    const [mcpApiBase, setMcpApiBase] = useState("")
    const [mcpApiKey, setMcpApiKey] = useState("")
    const [mcpSelectedModel, setMcpSelectedModel] = useState("")
    const [systemPrompt, setSystemPrompt] = useState("")
    const [novaSonicWsUrl, setNovaSonicWsUrl] = useState("")
    const [turnTakingPauseSensitivity, setTurnTakingPauseSensitivity] = useState("MEDIUM")

    // Load initial settings and listen for changes
    useEffect(() => {
        const loadSettings = () => {
            const storedSettings = localStorage.getItem('astra-settings')
            if (storedSettings) {
                const settings = JSON.parse(storedSettings)
                setMode(settings.mode || "chat")
                setGraphName(settings.graphName || GRAPH_NAME_OPTIONS[0]['value'])
                setLang(settings.lang || LANG_OPTIONS[0]['value'])
                setOutputLanguage(settings.outputLanguage || lang)
                setPartialStabilization(settings.partialStabilization || false)
                setVoice(settings.voice || "male")
                setGreeting(settings.greeting || "")
                setMcpSelectedServers(settings.mcpSelectedServers || [])
                setMcpApiBase(settings.mcpApiBase || "")
                setMcpApiKey(settings.mcpApiKey || "")
                setMcpSelectedModel(settings.mcpSelectedModel || "")
                setSystemPrompt(settings.systemPrompt || "")
                setNovaSonicWsUrl(settings.novaSonicWsUrl || "")
                setTurnTakingPauseSensitivity(settings.turnTakingPauseSensitivity || "MEDIUM")
            }
        }

        // Load initial settings
        loadSettings()

        // Listen for settings changes
        const handleSettingsChange = (e: CustomEvent<any>) => {
            const settings = e.detail
            setMode(settings.mode)
            setGraphName(settings.graphName)
            setLang(settings.lang)
            setOutputLanguage(settings.outputLanguage)
            setPartialStabilization(settings.partialStabilization)
            setVoice(settings.voice)
            setGreeting(settings.greeting)
            setMcpSelectedServers(settings.mcpSelectedServers || [])
            setMcpApiBase(settings.mcpApiBase || "")
            setMcpApiKey(settings.mcpApiKey || "")
            setMcpSelectedModel(settings.mcpSelectedModel || "")
            setSystemPrompt(settings.systemPrompt || "")
            setNovaSonicWsUrl(settings.novaSonicWsUrl || "")
            setTurnTakingPauseSensitivity(settings.turnTakingPauseSensitivity || "MEDIUM")
        }

        window.addEventListener('astra-settings-changed', handleSettingsChange as EventListener)
        return () => {
            window.removeEventListener('astra-settings-changed', handleSettingsChange as EventListener)
        }
    }, [])

    // Extracted connect logic that can be called externally
    const triggerConnect = async () => {
        if (loading) return

        setLoading(true)
        try {
            const res = await apiStartService({
                channel,
                userId,
                language: lang,
                voiceType: voice,
                graphName: graphName,
                mode: mode,
                outputLanguage: outputLanguage,
                partialStabilization: partialStabilization,
                greeting: greeting,
                mcpSelectedServers: mcpSelectedServers.join(','),
                mcpApiBase: mcpApiBase,
                mcpApiKey: mcpApiKey,
                mcpModel: mcpSelectedModel,
                systemPrompt: systemPrompt,
                novaSonicWsUrl: novaSonicWsUrl,
                turnTakingPauseSensitivity: turnTakingPauseSensitivity
            })

            if (res?.code != 0) {
                if (res?.code == "10001") {
                    Modal.error({
                        title: "Error",
                        content: "The number of users experiencing the program simultaneously has exceeded the limit. Please try again later."
                    })
                } else {
                    Modal.error({
                        title: "Error",
                        content: `code:${res?.code},msg:${res?.msg}`
                    })
                }
                throw new Error(res?.msg)
            }

            dispatch(setAgentConnected(true))
            startPing()
        } finally {
            setLoading(false)
        }
    }

    // Expose triggerConnect via ref for external use
    useImperativeHandle(ref, () => ({
        triggerConnect
    }))

    const onClickConnect = async () => {
        if (loading) return

        if (agentConnected) {
            // Disconnect immediately without showing settings dialog
            setLoading(true)
            await apiStopService(channel)
            dispatch(setAgentConnected(false))
            stopPing()
            setLoading(false)
        } else {
            // When disconnected, check if we should override the connect behavior
            if (onConnectClick) {
                // Call the override handler (opens settings dialog)
                onConnectClick()
            } else {
                // Default behavior: connect directly
                await triggerConnect()
            }
        }
    }

    const startPing = () => {
        if (intervalId) stopPing()
        intervalId = setInterval(() => {
            apiPing(channel)
        }, 3000)
    }

    const stopPing = () => {
        if (intervalId) {
            clearInterval(intervalId)
            intervalId = null
        }
    }

    return (
        <div className={`${styles.btnConnect} ${agentConnected ? styles.disconnect : ''}`} onClick={onClickConnect}>
            <span className={`${styles.btnText} ${agentConnected ? styles.disconnect : ''}`}>
                {!agentConnected ? "Connect" : "Disconnect"}
                {loading && <LoadingOutlined className={styles.loading} />}
            </span>
        </div>
    )
})

ConnectButton.displayName = 'ConnectButton'

export default ConnectButton
