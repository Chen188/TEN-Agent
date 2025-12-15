import asyncio
import base64
import json
import time
import threading
import socketio
import requests
from typing import Optional, Dict, Any, List, Callable, Tuple
from enum import Enum
import urllib.parse
from rte import Data, RteEnv, PcmFrame, PcmFrameDataFmt, Cmd

from .log import logger

CMD_NAME_FLUSH="flush"

LANG_MAP = {
    "en-US": ['tiffany', 'matthew'],
    "en-UK": ['amy'],
    "es-ES": ['lupe', 'carlos'],
    "pt-BR": ['camila', 'thiago'],
    "hi-IN": ['kajal', 'karan'],
    "fr-FR": ['lea', 'remi'],
    "de-DE": ['vicki', 'daniel'],
    "it-IT": ['bianca', 'adriano'],
}

class NovaSonicConfig:
    def __init__(self,
                 region: str = "us-east-1",
                 access_key: str = "",
                 secret_key: str = "",
                 sample_rate_in: str = "16000",
                 sample_rate_out: str = "24000",
                 websocket_url: str = "ws://localhost:3333",
                 lang_code: str = 'en-US',
                 voice: str = 'tiffany',
                 greeting: str = '',
                 prompt: str = '',
                 turn_taking_pause_sensitivity: str = 'MEDIUM',
                 ):
        self.region = region
        self.access_key = access_key
        self.secret_key = secret_key
        self.sample_rate_in = sample_rate_in
        self.sample_rate_out = sample_rate_out
        self.websocket_url = websocket_url
        self.lang_code = lang_code
        self.voice = voice
        self.greeting = greeting
        self.prompt = prompt
        self.inference_config = {
            "maxTokens": 2048,
            "topP": 0.95,
            "temperature": 0.8
        }
        self.turn_taking_pause_sensitivity =turn_taking_pause_sensitivity.upper()

    @classmethod
    def default_config(cls):
        return cls()
    
    def validate_config(self):
        # Handle "auto" language mode - default to en-US
        if self.lang_code == 'auto':
            logger.info("Auto language mode selected, defaulting to en-US")
            self.lang_code = 'en-US'
        
        if self.lang_code not in LANG_MAP.keys():
            logger.warning(f"invalid lang_code: [{self.lang_code}], fallback to 'en-US'")
            self.lang_code = 'en-US'
        if self.voice not in LANG_MAP[self.lang_code]:
            logger.warning(f"invalid voice: [{self.voice}], fallback to {LANG_MAP[self.lang_code][0]}")
            self.voice = LANG_MAP[self.lang_code][0]

        if len(self.prompt) < 1:
            logger.warning("using default system prompt")
            self.prompt = "You are a helpful AI assistant. You communicate clearly and concisely." \
                            "Please respond to the user's questions or requests in a friendly manner."
        
        # Validate turn-taking pause sensitivity (uppercase)
        if self.turn_taking_pause_sensitivity not in ['LOW', 'MEDIUM', 'HIGH']:
            logger.warning(f"invalid turn_taking_pause_sensitivity: [{self.turn_taking_pause_sensitivity}], fallback to 'MEDIUM'")
            self.turn_taking_pause_sensitivity = 'MEDIUM'

class TextGenerationStage(Enum):
    SPECULATIVE = 'SPECULATIVE'
    FINAL = 'FINAL'

class AsyncNovaSonicClient:
    def __init__(self, config: NovaSonicConfig, queue: asyncio.Queue, rte: RteEnv, loop: asyncio.BaseEventLoop):
        self.config = config
        self.queue = queue
        self.rte = rte
        self.loop = loop
        self.stopped = False
        self.is_connected = False
        self.sio = socketio.Client()
        self.user_id = "0"
        self.remote_user_id = "0"
        self.session_started = False

        self._credentials_need_update = True
        self.text_generation_stage = TextGenerationStage.SPECULATIVE
        
        # Set up Socket.IO event handlers
        self.setup_socket_handlers()
    
    def set_user_id(self, user_id: str = "0", remote_user_id: str = "0"):
        logger.info(f"set_user_id: {user_id}, {remote_user_id}")
        self.user_id = user_id
        self.remote_user_id = remote_user_id
    
    def send_flush_cmd(self):
        flush_cmd = Cmd.create(CMD_NAME_FLUSH)
        self.rte.send_cmd(
            flush_cmd,
            lambda rte, result: print(
                "send_cmd flush done"
            ),
        )

        logger.info(f"sent cmd: {CMD_NAME_FLUSH}")
        
    def setup_socket_handlers(self):
        # Define handlers for Socket.IO events
        self.sio.on('connect', self._on_connect)
        self.sio.on('disconnect', self._on_disconnect)
        self.sio.on('connect_error', self._on_connect_error)
        self.sio.on('contentStart', self._on_content_start)
        self.sio.on('textOutput', self._on_text_output)
        self.sio.on('contentEnd', self._on_content_end)
        self.sio.on('audioOutput', self._on_audio_output)
        self.sio.on('error', self._on_error)
        self.sio.on('streamComplete', self._on_stream_complete)
        
    def _on_connect(self):
        logger.info("Connected to WebSocket server")
        self.is_connected = True
        self._start_session()

    def _start_session(self):
        # Start a new session with Nova Sonic v2 configuration
        session_config = {
            "voiceId": self.config.voice
        }
        
        self.sio.emit('promptStart')
        
        # Use a default system prompt
        system_prompt = self.config.prompt
        self.sio.emit('systemPrompt', system_prompt)
        
        # Start audio streaming
        self.sio.emit('audioStart')
        self.session_started = True

    def _on_disconnect(self):
        logger.info("Disconnected from WebSocket server")
        self.is_connected = False
        self.session_started = False
    
    def _on_connect_error(self, data):
        logger.error(f"Connection error: {data}")
        self.is_connected = False
    
    def _on_content_start(self, data):
        logger.info(f"Content start: {data}")
        
        if data['type'] == "TEXT" and data.get('additionalModelFields'):
            try:
                additional_fields = json.loads(data.get('additionalModelFields'))
                self.text_generation_stage = additional_fields.get('generationStage', TextGenerationStage.SPECULATIVE)
            except Exception as e:
                logger.error(f"Error parsing additionalModelFields: {e}")
                self.text_generation_stage = TextGenerationStage.SPECULATIVE
    
    def _on_text_output(self, data):
        logger.info(f"Text output: {data}")
        # Forward text output to the system
        asyncio.run_coroutine_threadsafe(self.handle_text_output(data), self.loop)
    
    def _on_content_end(self, data):
        # logger.info(f"Content end: {data}")
        if data.get('stopReason') == 'INTERRUPTED':
            logger.info("User interrupt")
            self.send_flush_cmd()
    
    def _on_audio_output(self, data):
        # logger.info("Audio output received")
        # Forward audio output to the system
        asyncio.run_coroutine_threadsafe(self.handle_audio_output(data), self.loop)
    
    def _on_error(self, data):
        logger.error(f"Error from WebSocket server: {data}")
    
    def _on_stream_complete(self):
        logger.info("Stream completed")

    async def handle_text_output(self, data):
        try:
            # Create text data to forward to the system
            rte_text_data = Data.create("text_data")

            if data['role'] == 'ASSISTANT':
                rte_text_data.set_property_string("text", data.get("content", "") + f' [{self.text_generation_stage}]')
            else:
                rte_text_data.set_property_string("text", data.get("content", ""))

            rte_text_data.set_property_bool("is_final", True)
            rte_text_data.set_property_bool("end_of_segment", True)
            rte_text_data.set_property_int("stream_id", int(self.remote_user_id))
            rte_text_data.set_property_string("language", "")
            rte_text_data.set_property_int("time", int(time.time() * 1000))
            rte_text_data.set_property_int("duration_ms", 0)

            self.rte.send_data(rte_text_data)
        except Exception as e:
            logger.exception(f"Error handling text output: {e}")

    async def handle_audio_output(self, data):
        try:
            audio_content = data.get("content", "")
            if not audio_content:
                logger.warning("Empty audio content received")
                return

            # Decode base64 audio data
            audio_bytes = base64.b64decode(audio_content)
            
            if len(audio_bytes) == 0:
                logger.warning("Empty audio bytes after decoding")
                return
            
            # Get the sample rate from config
            sample_rate_out = int(self.config.sample_rate_out)
            bytes_per_sample = 2  # 16-bit audio
            channels = 1  # mono
            
            # Calculate actual samples from received data
            actual_samples = len(audio_bytes) // (bytes_per_sample * channels)
            
            # Create PCM frame with actual received data size (no padding)
            f = PcmFrame.create("pcm_frame")
            f.set_sample_rate(sample_rate_out)
            f.set_bytes_per_sample(bytes_per_sample)
            f.set_number_of_channels(channels)
            f.set_data_fmt(PcmFrameDataFmt.INTERLEAVE)
            f.set_samples_per_channel(actual_samples)
            f.alloc_buf(len(audio_bytes))

            buff = f.lock_buf()
            buff[:] = audio_bytes
            f.unlock_buf(buff)

            # Send PCM frame as-is without chunking or padding
            self.rte.send_pcm_frame(f)
        except Exception as e:
            logger.exception(f"Error handling audio output: {e}")
    
    def connect(self):
        """Connect to the WebSocket server"""
        try:
            # Remove ws:// or wss:// prefix if present for socketio
            url = self.config.websocket_url
            if url.startswith("ws://"):
                url = url[5:]
            elif url.startswith("wss://"):
                url = url[6:]

            session_config = {
                "inferenceConfig": self.config.inference_config,
                "turnDetectionConfiguration": {
                    "endpointingSensitivity": self.config.turn_taking_pause_sensitivity
                }
            };

            config_param = urllib.parse.urlencode({'config': json.dumps(session_config)})
            url = f"http://{url}?{config_param}"
            # logger.info(f"Connecting to WebSocket server at {url}")
            self.sio.connect(url)
            return True
        except Exception as e:
            logger.exception(f"Failed to connect to WebSocket server: {e}")
            return False
            
    def disconnect(self):
        """Disconnect from the WebSocket server"""
        if self.is_connected:
            try:
                self.sio.disconnect()
            except Exception as e:
                logger.exception(f"Error during disconnect: {e}")
        
    async def send_frame(self):
        """Process audio frames from the queue and send to the WebSocket server"""
        logger.info("Starting audio frame processing")
        
        while not self.stopped:
            try:
                # Get PCM frame from queue with timeout
                pcm_frame = await asyncio.wait_for(self.queue.get(), timeout=10.0)
                
                if pcm_frame is None:
                    logger.warning("Empty PCM frame received, continuing...")
                    self.queue.task_done()
                    continue
                
                # If not connected or session not started, attempt to reconnect
                if not self.is_connected or not self.session_started:
                    if not self.connect():
                        await asyncio.sleep(1)  # Wait before retrying
                        self.queue.task_done()
                        continue
                
                # Process PCM frame
                frame_buf = pcm_frame.get_buf()
                if not frame_buf:
                    logger.warning("Empty PCM frame buffer received")
                    self.queue.task_done()
                    continue
                
                # Convert to base64 for WebSocket transmission
                audio_b64 = base64.b64encode(frame_buf).decode('utf-8')
                
                # Send audio data
                self.sio.emit('audioInput', audio_b64)
                self.queue.task_done()
                
            except asyncio.TimeoutError:
                logger.debug("Timeout waiting for PCM frame, continuing...")
            except Exception as e:
                logger.exception(f"Error in send_frame: {e}")
                # Brief pause to prevent rapid retries in case of error
                await asyncio.sleep(0.5)
                
        logger.info("Audio frame processing stopped")
    
    async def send_text(self, text):
        """Send text input to the WebSocket server"""
        if self.is_connected:
            try:
                # Implementation for direct text input if needed
                logger.info(f"Sending text input: {text}")
                # Note: The current WebSocket server doesn't support direct text input
            except Exception as e:
                logger.exception(f"Error sending text input: {e}")
    
    async def nova_sonic_loop(self):
        """Main processing loop"""
        try:
            # Connect to WebSocket server
            if not self.connect():
                raise RuntimeError("Failed to connect to WebSocket server")
            
            if self.config.greeting:
                await self.handle_text_output({
                    "role": "USER",
                    "content": "/// Greeting message not supported, will update later ///"
                })

            # Process frames
            await self.send_frame()
        except Exception as e:
            logger.exception(f"Error in nova_sonic_loop: {e}")
        finally:
            self.disconnect()
    
    def run(self):
        """Run the WebSocket client in the event loop"""
        self.loop.run_until_complete(self.nova_sonic_loop())
        logger.info("WebSocket client thread completed")
    
    def stop(self):
        """Stop the WebSocket client"""
        self.stopped = True
        self.disconnect()
