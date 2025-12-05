import { useReducer } from "react"
import { GRAPH_NAME_OPTIONS, LANG_OPTIONS } from "@/common"

// Define types for our settings state
export interface McpModel {
    model_id: string;
    model_name: string;
}

export interface McpServer {
    server_id: string;
    server_name: string;
}

export interface SettingsState {
    // General settings
    mode: string;
    graphName: string;
    lang: string;
    outputLanguage: string;
    partialStabilization: boolean;
    voice: string;
    maxMemoryLength: number,
    novaSonicWsUrl: string,
    polyglotVoiceEnabled: boolean,
    turnTakingPauseSensitivity: string,

    // Prompt settings
    greeting: string;
    systemPrompt: string;

    // MCP settings
    mcpApiKey: string;
    mcpApiBase: string;
    mcpConnected: boolean;
    mcpModels: McpModel[];
    mcpServers: McpServer[];
    mcpSelectedModel: string;
    mcpSelectedServers: string[];
}

export type SettingsAction =
    | { type: 'SET_GENERAL', payload: Partial<SettingsState> }
    | { type: 'SET_MCP_MODELS', payload: McpModel[] }
    | { type: 'SET_MCP_SERVERS', payload: McpServer[] }
    | { type: 'TOGGLE_MCP_SERVER', payload: string }
    | { type: 'LOAD_SETTINGS', payload: Partial<SettingsState> };

// Initial state
const initialSettingsState: SettingsState = {
    mode: "chat",
    graphName: GRAPH_NAME_OPTIONS[0]['value'],
    lang: LANG_OPTIONS[0]['value'],
    outputLanguage: LANG_OPTIONS[0]['value'],
    partialStabilization: false,
    voice: "male",
    greeting: "",
    systemPrompt: "",
    maxMemoryLength: 20,
    novaSonicWsUrl: "",
    polyglotVoiceEnabled: false,
    turnTakingPauseSensitivity: "medium",
    mcpApiKey: "",
    mcpApiBase: "http://localhost:7002",
    mcpConnected: false,
    mcpModels: [],
    mcpServers: [],
    mcpSelectedModel: "",
    mcpSelectedServers: []
};

// Reducer function
function settingsReducer(state: SettingsState, action: SettingsAction): SettingsState {
    switch (action.type) {
        case 'SET_GENERAL':
            return { ...state, ...action.payload };
        case 'SET_MCP_MODELS':
            return { ...state, mcpModels: action.payload };
        case 'SET_MCP_SERVERS':
            return { ...state, mcpServers: action.payload };
        case 'TOGGLE_MCP_SERVER':
            return {
                ...state,
                mcpSelectedServers: state.mcpSelectedServers.includes(action.payload)
                    ? state.mcpSelectedServers.filter(id => id !== action.payload)
                    : [...state.mcpSelectedServers, action.payload]
            };
        case 'LOAD_SETTINGS':
            return { ...state, ...action.payload };
        default:
            return state;
    }
}

export const useSettingsState = () => {
    const [settings, dispatch] = useReducer(settingsReducer, initialSettingsState);

    const loadSettings = () => {
        const storedSettings = localStorage.getItem('astra-settings')
        if (storedSettings) {
            try {
                const parsedSettings = JSON.parse(storedSettings)
                // Fix potential issue with selectedModel vs mcpSelectedModel
                if (parsedSettings.selectedModel && !parsedSettings.mcpSelectedModel) {
                    parsedSettings.mcpSelectedModel = parsedSettings.selectedModel
                }
                dispatch({ type: 'LOAD_SETTINGS', payload: parsedSettings })
            } catch (error) {
                console.error('Failed to parse stored settings:', error)
            }
        }
    }

    const saveSettings = (settings: SettingsState) => {
        // Persist all settings including mcpModels and mcpServers
        localStorage.setItem('astra-settings', JSON.stringify(settings))

        // Dispatch custom event for real-time updates
        const event = new CustomEvent('astra-settings-changed', { detail: settings })
        window.dispatchEvent(event)
    }

    return { settings, dispatch, loadSettings, saveSettings };
}
