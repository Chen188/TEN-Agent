package internal

import "log/slog"

type Prop struct {
	ExtensionName string
	Property      string
}

const (
	// Extension name
	extensionNameAgoraRTC      = "agora_rtc"
	extensionNameBedrockLLM    = "bedrock_llm"
	extensionNameBedrockMCP    = "bedrock_mcp"
	extensionNameDify          = "dify"
	extensionNameAzureTTS      = "azure_tts"
	extensionNameCosyTTS       = "cosy_tts"
	extensionNameElevenlabsTTS = "elevenlabs_tts"
	extensionNameLiteLLM       = "litellm"
	extensionNameNovaSonic     = "nova_sonic"
	extensionNameOpenaiChatgpt = "openai_chatgpt"
	extensionNamePollyTTS      = "polly_tts"
	extensionNameQwenLLM       = "qwen_llm"
	extensionNameSageMakerLLM  = "sagemaker_llm"
	extensionNameSageMakerTTS  = "sagemaker_tts"
	extensionNameTranscribeAsr = "transcribe_asr"

	// Language
	languageChinese            = "zh-CN"
	languageChineseTraditional = "zh-TW"
	languageChineseCantonese   = "zh-HK"
	languageEnglish            = "en-US"
	languageEnglishGB          = "en-UK"
	languageJapenese           = "ja-JP"
	languageFrench             = "fr-FR"
	languageGerman             = "de-DE"
	languageSpanish            = "es-ES"
	languagePortuguese         = "pt-BR"
	languageKorean             = "ko-KR"
	languageHindi              = "hi-IN"
	languageItalian            = "it-IT"

	// Default graph name
	graphNameDefault = "va.openai.azure"
	// Property json
	PropertyJsonFile = "./agents/property.json"
	// Token expire time
	tokenExpirationInSeconds = uint32(86400)
	// Voice type
	voiceTypeMale   = "male"
	voiceTypeFemale = "female"
)

var (
	logTag = slog.String("service", "HTTP_SERVER")

	// Retrieve configuration information from environment variables and map it to the property.json file
	EnvPropMap = map[string][]Prop{
		"AGORA_APP_ID": {
			{ExtensionName: extensionNameAgoraRTC, Property: "app_id"},
		},
		"AWS_ACCESS_KEY_ID": {
			{ExtensionName: extensionNameBedrockLLM, Property: "access_key"},
			{ExtensionName: extensionNamePollyTTS, Property: "access_key"},
			{ExtensionName: extensionNameSageMakerTTS, Property: "access_key"},
			{ExtensionName: extensionNameTranscribeAsr, Property: "access_key"},
			{ExtensionName: extensionNameSageMakerLLM, Property: "access_key"},
			{ExtensionName: extensionNameNovaSonic, Property: "access_key"},
		},
		"AWS_SECRET_ACCESS_KEY": {
			{ExtensionName: extensionNameBedrockLLM, Property: "secret_key"},
			{ExtensionName: extensionNamePollyTTS, Property: "secret_key"},
			{ExtensionName: extensionNameTranscribeAsr, Property: "secret_key"},
			{ExtensionName: extensionNameSageMakerTTS, Property: "secret_key"},
			{ExtensionName: extensionNameSageMakerLLM, Property: "secret_key"},
			{ExtensionName: extensionNameNovaSonic, Property: "secret_key"},
		},
		"AWS_BEDROCK_MODEL": {
			{ExtensionName: extensionNameBedrockLLM, Property: "model"},
		},
		"AWS_REGION": {
			{ExtensionName: extensionNameBedrockLLM, Property: "region"},
			{ExtensionName: extensionNamePollyTTS, Property: "region"},
			{ExtensionName: extensionNameTranscribeAsr, Property: "region"},
			{ExtensionName: extensionNameSageMakerTTS, Property: "region"},
			{ExtensionName: extensionNameSageMakerLLM, Property: "region"},
			{ExtensionName: extensionNameNovaSonic, Property: "region"},
		},
		"AZURE_STT_KEY": {
			{ExtensionName: extensionNameAgoraRTC, Property: "agora_asr_vendor_key"},
		},
		"AZURE_STT_REGION": {
			{ExtensionName: extensionNameAgoraRTC, Property: "agora_asr_vendor_region"},
		},
		"AZURE_TTS_KEY": {
			{ExtensionName: extensionNameAzureTTS, Property: "azure_subscription_key"},
		},
		"AZURE_TTS_REGION": {
			{ExtensionName: extensionNameAzureTTS, Property: "azure_subscription_region"}},
		"COSY_TTS_KEY": {
			{ExtensionName: extensionNameCosyTTS, Property: "api_key"},
		},
		"ELEVENLABS_TTS_KEY": {
			{ExtensionName: extensionNameElevenlabsTTS, Property: "api_key"},
		},
		"OPENAI_API_KEY": {
			{ExtensionName: extensionNameOpenaiChatgpt, Property: "api_key"},
		},
		"LITELLM_API_KEY": {
			{ExtensionName: extensionNameLiteLLM, Property: "api_key"},
		},
		"LITELLM_MODEL": {
			{ExtensionName: extensionNameLiteLLM, Property: "model"},
		},
		"LITELLM_PROVIDER": {
			{ExtensionName: extensionNameLiteLLM, Property: "provider"},
		},
		"OPENAI_BASE_URL": {
			{ExtensionName: extensionNameOpenaiChatgpt, Property: "base_url"},
		},
		"OPENAI_MODEL": {
			{ExtensionName: extensionNameOpenaiChatgpt, Property: "model"},
		},
		"OPENAI_PROXY_URL": {
			{ExtensionName: extensionNameOpenaiChatgpt, Property: "proxy_url"},
		},
		"QWEN_API_KEY": {
			{ExtensionName: extensionNameQwenLLM, Property: "api_key"},
		},
	}

	// Retrieve parameters from the request and map them to the property.json file
	startPropMap = map[string][]Prop{
		"AgoraAsrLanguage": {
			{ExtensionName: extensionNameAgoraRTC, Property: "agora_asr_language"},
			{ExtensionName: extensionNameTranscribeAsr, Property: "lang_code"},
			{ExtensionName: extensionNameBedrockLLM, Property: "input_language"},
			{ExtensionName: extensionNameSageMakerLLM, Property: "input_language"},
			{ExtensionName: extensionNameNovaSonic, Property: "lang_code"},
		},
		"NovaSonicWsUrl": {
			{ExtensionName: extensionNameNovaSonic, Property: "websocket_url"},
		},
		"ChannelName": {
			{ExtensionName: extensionNameAgoraRTC, Property: "channel"},
		},
		"RemoteStreamId": {
			{ExtensionName: extensionNameAgoraRTC, Property: "remote_stream_id"},
		},
		"Token": {
			{ExtensionName: extensionNameAgoraRTC, Property: "token"},
		},
		"Mode": {
			{ExtensionName: extensionNameBedrockLLM, Property: "mode"},
			{ExtensionName: extensionNameSageMakerLLM, Property: "mode"},
		},
		"OutputLanguage": {
			{ExtensionName: extensionNameBedrockLLM, Property: "output_language"},
			{ExtensionName: extensionNameSageMakerTTS, Property: "output_language"},
			{ExtensionName: extensionNameSageMakerLLM, Property: "output_language"},
		},
		"VoiceType": {
			{ExtensionName: extensionNameAzureTTS, Property: "azure_synthesis_voice_name"},
			{ExtensionName: extensionNameElevenlabsTTS, Property: "voice_id"},
			{ExtensionName: extensionNamePollyTTS, Property: "voice"},
			{ExtensionName: extensionNameNovaSonic, Property: "voice"},
		},
		"PartialStabilization": {
			{ExtensionName: extensionNameTranscribeAsr, Property: "enable_partial_results_stabilization"},
		},
		"Greeting": {
			{ExtensionName: extensionNameBedrockLLM, Property: "greeting"},
			{ExtensionName: extensionNameDify, Property: "greeting"},
			{ExtensionName: extensionNameBedrockMCP, Property: "greeting"},
			{ExtensionName: extensionNameNovaSonic, Property: "greeting"},
		},
		"SystemPrompt": {
			{ExtensionName: extensionNameBedrockLLM, Property: "prompt"},
			{ExtensionName: extensionNameBedrockMCP, Property: "prompt"},
			{ExtensionName: extensionNameNovaSonic, Property: "prompt"},
		},
		"MaxMemoryLength": {
			{ExtensionName: extensionNameBedrockLLM, Property: "max_memory_length"},
			{ExtensionName: extensionNameDify, Property: "max_history"},
			{ExtensionName: extensionNameBedrockMCP, Property: "max_memory_length"},
		},
		"McpApiBase": {
			{ExtensionName: extensionNameBedrockMCP, Property: "base_url"},
		},
		"McpApiKey": {
			{ExtensionName: extensionNameBedrockMCP, Property: "api_key"},
		},
		"McpSelectedServers": {
			{ExtensionName: extensionNameBedrockMCP, Property: "mcp_server_ids"},
		},
		"McpModel": {
			{ExtensionName: extensionNameBedrockMCP, Property: "model"},
		},
		"PolyglotVoiceEnabled": {
			{ExtensionName: extensionNameNovaSonic, Property: "polyglot_voice_enabled"},
		},
		"TurnTakingPauseSensitivity": {
			{ExtensionName: extensionNameNovaSonic, Property: "turn_taking_pause_sensitivity"},
		},
	}

	// Map the voice name to the voice type
	voiceNameMap = map[string]map[string]map[string]string{
		languageChinese: {
			extensionNameAzureTTS: {
				voiceTypeMale:   "zh-CN-YunxiNeural",
				voiceTypeFemale: "zh-CN-XiaoxiaoNeural",
			},
			extensionNameElevenlabsTTS: {
				voiceTypeMale:   "pNInz6obpgDQGcFmaJgB", // Adam
				voiceTypeFemale: "Xb7hH8MSUJpSbSDYk0k2", // Alice
			},
			extensionNamePollyTTS: {
				voiceTypeMale:   "Zhiyu",
				voiceTypeFemale: "Zhiyu",
			},
		},
		languageEnglish: {
			extensionNameAzureTTS: {
				voiceTypeMale:   "en-US-BrianNeural",
				voiceTypeFemale: "en-US-JaneNeural",
			},
			extensionNameElevenlabsTTS: {
				voiceTypeMale:   "pNInz6obpgDQGcFmaJgB", // Adam
				voiceTypeFemale: "Xb7hH8MSUJpSbSDYk0k2", // Alice
			},
			extensionNamePollyTTS: {
				voiceTypeMale:   "Matthew",
				voiceTypeFemale: "Ruth",
			},
			extensionNameNovaSonic: {
				voiceTypeMale:   "matthew",
				voiceTypeFemale: "tiffany",
			},
		},
		languageEnglishGB: {
			extensionNameNovaSonic: {
				voiceTypeMale:   "amy",
				voiceTypeFemale: "amy",
			},
		},
		languageJapenese: {
			extensionNameAzureTTS: {
				voiceTypeMale:   "ja-JP-KeitaNeural",
				voiceTypeFemale: "ja-JP-NanamiNeural",
			},
			extensionNameElevenlabsTTS: {
				voiceTypeMale:   "pNInz6obpgDQGcFmaJgB", // Adam
				voiceTypeFemale: "Xb7hH8MSUJpSbSDYk0k2", // Alice
			},
			extensionNamePollyTTS: {
				voiceTypeMale:   "Takumi",
				voiceTypeFemale: "Kazuha",
			},
		},
		languageFrench: {
			extensionNameAzureTTS: {
				voiceTypeMale:   "fr-FR-HenriNeural",
				voiceTypeFemale: "fr-FR-DeniseNeural",
			},
			extensionNameElevenlabsTTS: {
				voiceTypeMale:   "pNInz6obpgDQGcFmaJgB", // Adam
				voiceTypeFemale: "EXAVITQu4vr4xnSDxMaL", // Sarah
			},
			extensionNamePollyTTS: {
				voiceTypeMale:   "Remi",
				voiceTypeFemale: "Lea",
			},
			extensionNameNovaSonic: {
				voiceTypeMale:   "remi",
				voiceTypeFemale: "lea",
			},
		},
		languageKorean: {
			extensionNameAzureTTS: {
				voiceTypeMale:   "ko-KR-SunHiNeural",
				voiceTypeFemale: "ko-KR-InJoonNeural",
			},
			extensionNameElevenlabsTTS: {
				voiceTypeMale:   "pNInz6obpgDQGcFmaJgB", // Adam
				voiceTypeFemale: "Xb7hH8MSUJpSbSDYk0k2", // Alice
			},
			extensionNamePollyTTS: {
				voiceTypeMale:   "Seoyeon",
				voiceTypeFemale: "Seoyeon",
			},
		},
		languageHindi: {
			extensionNamePollyTTS: {
				voiceTypeMale:   "Kajal",
				voiceTypeFemale: "Kajal",
			},
			extensionNameNovaSonic: {
				voiceTypeMale:   "karan",
				voiceTypeFemale: "kajal",
			},
		},
		languageChineseTraditional: {
			extensionNamePollyTTS: {
				voiceTypeMale:   "Hiujin",
				voiceTypeFemale: "Hiujin",
			},
		},
		languageChineseCantonese: {
			extensionNamePollyTTS: {
				voiceTypeMale:   "Hiujin",
				voiceTypeFemale: "Hiujin",
			},
		},
		languageSpanish: {
			extensionNameNovaSonic: {
				voiceTypeMale:   "carlos",
				voiceTypeFemale: "lupe",
			},
		},
		languagePortuguese: {
			extensionNameNovaSonic: {
				voiceTypeMale:   "thiago",
				voiceTypeFemale: "camila",
			},
		},
		languageGerman: {
			extensionNameNovaSonic: {
				voiceTypeMale:   "daniel",
				voiceTypeFemale: "vicki",
			},
		},
		languageItalian: {
			extensionNameNovaSonic: {
				voiceTypeMale:   "adriano",
				voiceTypeFemale: "bianca",
			},
		},
	}
)
