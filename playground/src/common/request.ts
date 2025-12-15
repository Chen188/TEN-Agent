import { REQUEST_URL } from "./constant"
import { genUUID } from "./utils"

interface StartRequestConfig {
  channel: string
  userId: number,
  language: string
  voiceType: string
  graphName: string,
  mode: string,
  outputLanguage: string,
  partialStabilization: boolean,
  greeting: string,
  maxMemoryLength?: number,
  mcpSelectedServers?: string,
  mcpApiBase?: string,
  mcpApiKey?: string,
  mcpModel?: string,
  systemPrompt?: string,
  novaSonicWsUrl?: string,
  turnTakingPauseSensitivity?: string,
}

interface GenAgoraDataConfig {
  userId: string | number
  channel: string
}

export const apiGenAgoraData = async (config: GenAgoraDataConfig) => {
  const url = `${REQUEST_URL}/token/generate`
  const { userId, channel } = config
  const data = {
    request_id: genUUID(),
    uid: userId,
    channel_name: channel
  }
  let resp: any = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(data),
  })
  resp = (await resp.json()) || {}
  return resp
}

export const apiStartService = async (config: StartRequestConfig): Promise<any> => {
  const url = `${REQUEST_URL}/start`
  const {
    language,
    channel,
    userId,
    voiceType,
    graphName,
    mode,
    outputLanguage,
    partialStabilization,
    greeting,
    mcpSelectedServers,
    mcpApiBase,
    mcpApiKey,
    mcpModel,
    maxMemoryLength,
    systemPrompt,
    novaSonicWsUrl,
    turnTakingPauseSensitivity
  } = config
  const data = {
    request_id: genUUID(),
    agora_asr_language: language,
    channel_name: channel,
    openai_proxy_url: "",
    remote_stream_id: userId,
    voice_type: voiceType,
    graph_name: graphName,
    mode: mode,
    output_language: outputLanguage,
    enable_partial_results_stabilization: partialStabilization,
    greeting: greeting.trim(),
    max_memory_length: maxMemoryLength,
    mcp_selected_servers: mcpSelectedServers,
    mcp_api_base: mcpApiBase || "",
    mcp_api_key: mcpApiKey || "",
    mcp_model: mcpModel || "",
    system_prompt: systemPrompt || "",
    nova_sonic_ws_url: novaSonicWsUrl || "",
    turn_taking_pause_sensitivity: turnTakingPauseSensitivity || "MEDIUM",
  }
  let resp: any = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(data),
  })
  resp = (await resp.json()) || {}
  return resp
}

export const apiStopService = async (channel: string) => {
  const url = `${REQUEST_URL}/stop`
  const data = {
    request_id: genUUID(),
    channel_name: channel
  }
  let resp = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(data),
  })
  resp = (await resp.json()) || {}
  return resp
}

// ping/pong 
export const apiPing = async (channel: string) => {
  const url = `${REQUEST_URL}/ping`
  const data = {
    request_id: genUUID(),
    channel_name: channel
  }
  let resp = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(data),
  })
  resp = (await resp.json()) || {}
  return resp
}

// mcp info
export const apiMcpInfo = async (api_base: string, api_key: string, sub_path: string): Promise<any> => {
  const url = `${REQUEST_URL}/mcp/info`
  const data = {
    api_base: api_base,
    api_key: api_key,
    sub_path: sub_path
  }
  let resp = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(data),
  })
  resp = (await resp.json()) || {}
  return resp
}
