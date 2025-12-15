# Nova Sonic Python Addon

This addon integrates Amazon Nova Sonic v2 speech-to-speech functionality into the ASTRA.ai framework via a WebSocket connection.

## Overview

Nova Sonic v2 is Amazon's audio-to-audio generative AI model that enables direct speech-to-speech communication. This addon replaces the traditional ASR (Automatic Speech Recognition) + TTS (Text-to-Speech) pipeline with a single integrated solution. It:

1. Captures audio input from the ASTRA.ai framework
2. Sends the audio to a Nova Sonic WebSocket server
3. Receives text and audio output from the server
4. Forwards the output back to the ASTRA.ai framework

### Nova Sonic v2 Features

- **Multi-language Support**: English (US/UK), Spanish, French, German, Italian, Portuguese, and Hindi
- **Auto Language Mode**: Automatically detects input language when set to "auto" (defaults to English)
- **Turn-Taking Controllability**: Configure conversation pause sensitivity with three levels:
  - **LOW**: Longer pause before interrupting (less responsive)
  - **MEDIUM**: Balanced pause sensitivity (default)
  - **HIGH**: Shorter pause, more responsive turn-taking
- **Polyglot Voice Support**: Voice IDs natively support multiple languages without requiring separate configuration

## Setup

### Prerequisites

- ASTRA.ai framework
- Node.js and npm (for the WebSocket server)
- Python 3.7+
- AWS credentials with access to Amazon Bedrock

### Installation

1. Set up the Nova Sonic WebSocket server:
   ```bash
   cd /home/ubuntu/ASTRA.ai/nova-sonic-server
   npm install
   npm start
   ```

2. Configure the addon in your ASTRA.ai properties file:
   ```json
   {
     "region": "us-east-1",
     "access_key": "YOUR_AWS_ACCESS_KEY",
     "secret_key": "YOUR_AWS_SECRET_KEY",
     "sample_rate_in": "16000",
     "sample_rate_out": "24000",
     "websocket_url": "ws://localhost:3333",
     "lang_code": "en-US",
     "voice": "tiffany",
     "turn_taking_pause_sensitivity": "MEDIUM"
   }
   ```

### Configuration Options

- **region**: AWS region (default: "us-east-1")
- **access_key**: AWS access key ID
- **secret_key**: AWS secret access key
- **sample_rate_in**: Input audio sample rate (default: "16000")
- **sample_rate_out**: Output audio sample rate (default: "24000")
- **websocket_url**: WebSocket server URL (e.g., "ws://localhost:3333")
- **lang_code**: Input language code. Options:
  - `auto` - Auto-detect language (defaults to English)
  - `en-US` - English (US)
  - `en-UK` - English (UK)
  - `es-ES` - Spanish
  - `pt-BR` - Portuguese (Brazil)
  - `hi-IN` - Hindi
  - `fr-FR` - French
  - `de-DE` - German
  - `it-IT` - Italian
- **voice**: Voice ID (e.g., "tiffany", "matthew", "lupe", "carlos", "camila", "thiago", "kajal", "karan", "lea", "remi", "daniel", "vicki", "bianca", "adriano", "amy")
- **turn_taking_pause_sensitivity**: Turn-taking sensitivity. Options:
  - `LOW` - Longer pause before interrupting
  - `MEDIUM` - Balanced pause sensitivity (default)
  - `HIGH` - Shorter pause, more responsive
- **greeting**: Optional greeting message
- **prompt**: System prompt for the conversation

## Usage

The addon automatically handles:
- Converting audio input to the required format and sending it to the WebSocket server
- Processing text and audio output from the WebSocket server
- Forwarding the processed output to the ASTRA.ai framework

## Developer Information

This addon consists of two main components:

1. **Nova Sonic WebSocket Server**: A Node.js server that handles communication with Amazon Bedrock Nova Sonic API.
2. **Nova Sonic Python Addon**: The ASTRA.ai addon that bridges between the framework and the WebSocket server.

### Key Files

- `nova_sonic_extension.py`: Main extension implementation
- `nova_sonic_client.py`: WebSocket client to communicate with the server

## Troubleshooting

- Ensure the WebSocket server is running and accessible
- Check AWS credentials are properly configured
- Verify the correct region is set in both addon properties and WebSocket server
- Check logs for detailed error messages