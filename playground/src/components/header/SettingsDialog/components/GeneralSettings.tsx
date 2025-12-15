import { Select, Checkbox, Input } from "antd"
import { InfoCircleOutlined, WarningFilled } from "@ant-design/icons"
import {
    LANG_OPTIONS,
    LANG_OPTIONS_SONIC,
    VOICE_OPTIONS,
    MODE_OPTIONS,
    MODE_OPTIONS_SONIC,
    GRAPH_NAME_OPTIONS,
    TURN_TAKING_PAUSE_SENSITIVITY_OPTIONS
} from "@/common"
import { SettingsState, SettingsAction } from "../hooks/useSettingsState"
import styles from "../index.module.scss"

interface GeneralSettingsProps {
    settings: SettingsState;
    dispatch: React.Dispatch<SettingsAction>;
    agentConnected: boolean;
}

const GeneralSettings = ({ settings, dispatch, agentConnected }: GeneralSettingsProps) => {
    return (
        <div className={styles.settingGroup}>
            <div className={styles.settingItem}>
                <div className={styles.label}>GRAPH NAME</div>
                <div className={styles.desc}>
                    <InfoCircleOutlined className={styles.infoIcon} /> {GRAPH_NAME_OPTIONS.find(o => o.value === settings.graphName)?.desc}
                </div>
                <Select
                    disabled={agentConnected}
                    className={`${styles.select} dark`}
                    value={settings.graphName}
                    options={GRAPH_NAME_OPTIONS}
                    onChange={v => {
                        const newMode = v.includes('translate')
                            ? MODE_OPTIONS[1].value
                            : MODE_OPTIONS[0].value;

                        const newLang = v.includes('nova.sonic')
                            ? LANG_OPTIONS_SONIC[0].value
                            : LANG_OPTIONS[0].value

                        const newOutputLang = v.includes('translate')
                            ? settings.outputLanguage
                            : settings.lang;

                        dispatch({
                            type: 'SET_GENERAL',
                            payload: {
                                graphName: v,
                                mode: newMode,
                                lang: newLang,
                                outputLanguage: newOutputLang
                            }
                        })
                    }}
                />
            </div>

            {
                settings.graphName.includes('nova.sonic') &&
                <div className={styles.settingItem}>
                    <div className={styles.label}>NOVA SONIC WEBSOCKET URL</div>
                    <Input
                        className={`${styles.input} dark`}
                        disabled={agentConnected}
                        value={settings.novaSonicWsUrl}
                        placeholder="WebSocket URL for Nova Sonic(ws://)"
                        onChange={e => dispatch({ type: 'SET_GENERAL', payload: { novaSonicWsUrl: e.target.value } })}
                        style={{ flex: 1 }}
                    />
                </div>
            }

            {
                settings.graphName.includes('nova.sonic') &&
                <div className={styles.settingItem}>
                    <div className={styles.label}>TURN-TAKING PAUSE SENSITIVITY</div>
                    <div className={styles.desc}>
                        <InfoCircleOutlined className={styles.infoIcon} /> {TURN_TAKING_PAUSE_SENSITIVITY_OPTIONS.find(o => o.value === settings.turnTakingPauseSensitivity)?.desc}
                    </div>
                    <Select
                        disabled={agentConnected}
                        className={`${styles.select} dark`}
                        value={settings.turnTakingPauseSensitivity}
                        options={TURN_TAKING_PAUSE_SENSITIVITY_OPTIONS}
                        onChange={v => dispatch({ type: 'SET_GENERAL', payload: { turnTakingPauseSensitivity: v } })}
                    />
                </div>
            }

            <div className={styles.settingItem}>
                <div className={styles.label}>AGENT MODE</div>
                {
                    ((settings.graphName.includes('translate') && settings.mode !== 'translate') ||
                        (!settings.graphName.includes('translate') && settings.mode !== 'chat')) &&
                    (
                        <div className={styles.warn}>
                            <WarningFilled /> Agent mode may not consist with Graph selected.
                        </div>
                    )
                }
                <Select
                    disabled={agentConnected}
                    className={`${styles.select} dark`}
                    value={settings.mode}
                    options={settings.graphName.includes('nova.sonic') ? MODE_OPTIONS_SONIC : MODE_OPTIONS}
                    onChange={v => dispatch({ type: 'SET_GENERAL', payload: { mode: v } })}
                />
            </div>

            <div className={styles.settingItem}>
                <div className={styles.label}>INPUT LANGUAGE</div>
                <Select
                    disabled={agentConnected}
                    className={`${styles.select} dark`}
                    value={settings.lang}
                    options={settings.graphName.includes('nova.sonic') ? LANG_OPTIONS_SONIC : LANG_OPTIONS}
                    onChange={v => {
                        const payload: Partial<SettingsState> = { lang: v };
                        if (settings.mode === "chat") {
                            payload.outputLanguage = v;
                        }
                        dispatch({ type: 'SET_GENERAL', payload })
                    }}
                />
            </div>

            {settings.mode === "translate" && (
                <>
                    <div className={styles.settingItem}>
                        <div className={styles.label}>OUTPUT LANGUAGE</div>
                        <Select
                            disabled={agentConnected}
                            className={`${styles.select} dark`}
                            value={settings.outputLanguage}
                            options={LANG_OPTIONS}
                            onChange={v => dispatch({ type: 'SET_GENERAL', payload: { outputLanguage: v } })}
                        />
                    </div>

                    <div className={styles.settingItem}>
                        <div className={styles.label}>ASR PARTIAL STABILIZATION</div>
                        <Checkbox
                            disabled={agentConnected}
                            className={`${styles.checkbox} dark`}
                            checked={settings.partialStabilization}
                            onChange={e => dispatch({
                                type: 'SET_GENERAL',
                                payload: { partialStabilization: e.target.checked }
                            })}
                        >
                            Enable(May reduce accuracy)
                        </Checkbox>
                    </div>
                </>
            )}

            <div className={styles.settingItem}>
                <div className={styles.label}>VOICE</div>
                <Select
                    disabled={agentConnected}
                    value={settings.voice}
                    className={`${styles.select} dark`}
                    options={VOICE_OPTIONS}
                    onChange={v => dispatch({ type: 'SET_GENERAL', payload: { voice: v } })}
                />
            </div>

            {
                !settings.graphName.includes('nova.sonic') &&
                <>
                    <div className={styles.settingItem}>
                        <div className={styles.label}>MEMORY LENGTH</div>
                        <Input
                            className={`${styles.input} dark`}
                            disabled={agentConnected}
                            value={settings.maxMemoryLength}
                            placeholder="max chat histories preserved"
                            onChange={e => dispatch({ type: 'SET_GENERAL', payload: { maxMemoryLength: +e.target.value } })}
                            style={{ flex: 1 }}
                        />
                    </div>
                </>
            }
        </div>
    )
}

export default GeneralSettings
