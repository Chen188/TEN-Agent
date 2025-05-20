import { Input } from "antd"
import { SettingsState, SettingsAction } from "../hooks/useSettingsState"
import styles from "../index.module.scss"

const { TextArea } = Input

interface PromptSettingsProps {
    settings: SettingsState;
    dispatch: React.Dispatch<SettingsAction>;
    agentConnected: boolean;
}

const PromptSettings = ({ settings, dispatch, agentConnected }: PromptSettingsProps) => {
    return (
        <div className={styles.settingGroup}>
            {
                !settings.graphName.includes('dify') && (
                    <div className={styles.settingItem}>
                        <div className={styles.label}>SYSTEM PROMPT</div>
                        <TextArea
                            className={`${styles.textarea} dark`}
                            disabled={agentConnected}
                            value={settings.systemPrompt}
                            rows={4}
                            placeholder="Customize system prompt, leave blank to use default"
                            onChange={e => dispatch({ type: 'SET_GENERAL', payload: { systemPrompt: e.target.value } })}
                        />
                    </div>
                )
            }
            <div className={styles.settingItem}>
                <div className={styles.label}>GREETING</div>
                <TextArea
                    className={`${styles.textarea} dark`}
                    disabled={agentConnected}
                    value={settings.greeting}
                    rows={2}
                    placeholder="Enter a greeting message"
                    onChange={e => dispatch({ type: 'SET_GENERAL', payload: { greeting: e.target.value } })}
                />
            </div>
        </div>
    )
}

export default PromptSettings
