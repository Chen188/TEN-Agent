import { IOptions, ColorItem } from "@/types"

export const REQUEST_URL = process.env.NEXT_PUBLIC_REQUEST_URL ?? ""
export const GITHUB_URL = "https://github.com/Chen188/TEN-Agent"
export const OPTIONS_KEY = "__options__"
export const DEFAULT_OPTIONS: IOptions = {
  channel: "",
  userName: "",
  userId: 0
}
export const DESCRIPTION = "This is an AI voice assistant powered by TEN framework, Agora, Amazon Bedrock, Amazon Transcribe and Amazon SageMaker."
export const MODE_OPTIONS = [
  {
    label: "Chat",
    value: "chat"
  },
  {
    label: "Translate",
    value: "translate"
  }
]

export const MODE_OPTIONS_SONIC = [
  {
    label: "Chat",
    value: "chat"
  }
]

export const GRAPH_NAME_OPTIONS = [
  {
    label: "S2S/Amazon Nova Sonic",
    value: "va.nova.sonic",
    desc: "[Chat Mode] audio to audio model using Amazon Nova Sonic v2 with turn-taking controllability and support for 7 languages."
  },
  {
    label: "MCP/Bedrock Base",
    value: "va.transcribe-bedrock_mcp.polly",
    desc: "[Chat Mode] Transcribe ASR -> Bedrock MCP -> Polly TTS. Configure and Connect to MCP first."
  },
  {
    label: "Dify Knowledge Base",
    value: "va.dify.polly",
    desc: "[Chat Mode] Transcribe ASR -> Dify KB -> Polly TTS. System Prompt is not enabled for this graph."
  },
  {
    label: "Bedrock Base - Chat",
    value: "va.transcribe-bedrock.polly",
    desc: "[Chat Mode] Transcribe ASR -> Bedrock LLM -> Polly TTS"
  },
  {
    label: "Bedrock Base - Translate",
    value: "translate.transcribe-bedrock.polly",
    desc: "[Translation Mode] Transcribe ASR -> Bedrock LLM -> Polly TTS"
  },
  {
    label: "[Customize] Bedrock + SM TTS - Translate",
    value: "translate.transcribe-bedrock.sagemaker-tts",
    desc: "[Translation Mode] Transcribe ASR -> Bedrock LLM -> SageMaker TTS(You should deploy TTS model first)"
  },
  {
    label: "[Customize] Bedrock + SM TTS - Chat",
    value: "va.transcribe-bedrock.sagemaker-tts",
    desc: "[Chat Mode] Transcribe ASR -> Bedrock LLM -> SageMaker TTS(deploy TTS model first)"
  },
  {
    label: "[Customize] Bedrock + FishAudio TTS - Chat",
    value: "va.transcribe-bedrock.fish",
    desc: "[Chat Mode] Transcribe ASR -> Bedrock LLM -> Fish Audio TTS"
  },
  {
    label: "[Customize] SM LLM - Chat",
    value: "va.transcribe-sm_llm.polly",
    desc: "[Chat Mode] Transcribe ASR -> SageMaker LLM(deploy LLM first) -> Polly TTS"
  },
  {
    label: "[Customize] SM LLM + SM TTS - Chat",
    value: "va.transcribe-sm_llm.sm_tts",
    desc: "[Chat Mode] Transcribe ASR -> SageMaker LLM(deploy LLM first) -> SageMaker TTS(deploy TTS model first)"
  }
]
export const LANG_OPTIONS = [
  {
    label: "English",
    value: "en-US"
  },
  {
    label: "Chinese Simplified",
    value: "zh-CN"
  },
  {
    label: "Chinese Cantonese",
    value: "zh-HK"
  },
  {
    label: "Chinese Traditional",
    value: "zh-TW"
  },
  {
    label: "Japanese",
    value: "ja-JP"
  },
  {
    label: "French",
    value: "fr-FR"
  },
  {
    label: "Hindi",
    value: "hi-IN"
  }
]

export const LANG_OPTIONS_SONIC = [
  {
    label: "Auto",
    value: "auto"
  },
  {
    label: "English(US)",
    value: "en-US"
  },
  {
    label: "English(UK)",
    value: "en-UK"
  },
  {
    label: "Spanish",
    value: "es-ES"
  },
  {
    label: "Portuguese",
    value: "pt-BR"
  },
  {
    label: "Hindi",
    value: "hi-IN"
  },
  {
    label: "French",
    value: "fr-FR"
  },
  {
    label: "German",
    value: "de-DE"
  },
  {
    label: "Italian",
    value: "it-IT"
  },
]

export const VOICE_OPTIONS = [
  {
    label: "Male",
    value: "male"
  },
  {
    label: "Female",
    value: "female"
  }
]

export const TURN_TAKING_PAUSE_SENSITIVITY_OPTIONS = [
  {
    label: "Low",
    value: "LOW",
    desc: "Longer pause before interrupting"
  },
  {
    label: "Medium",
    value: "MEDIUM",
    desc: "Balanced pause sensitivity"
  },
  {
    label: "High",
    value: "HIGH",
    desc: "Shorter pause, more responsive"
  }
]

export const COLOR_LIST: ColorItem[] = [{
  active: "#0888FF",
  default: "#112941"
}, {
  active: "#563FD8",
  default: "#221C40"
},
{
  active: "#18A957",
  default: "#112A1E"
}, {
  active: "#FFAB08",
  default: "#392B13"
}, {
  active: "#FD5C63",
  default: "#3C2023"
}, {
  active: "#E225B2",
  default: "#371530"
}]

