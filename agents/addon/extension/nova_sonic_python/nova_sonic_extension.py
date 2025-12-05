from rte import (
    Extension,
    RteEnv,
    Cmd,
    PcmFrame,
    StatusCode,
    CmdResult,
    Data,
)

import json
import asyncio
import threading
from datetime import datetime

from .log import logger
from .nova_sonic_client import AsyncNovaSonicClient, NovaSonicConfig

PROPERTY_REGION = "region"  # Optional
PROPERTY_ACCESS_KEY = "access_key"  # Optional
PROPERTY_SECRET_KEY = "secret_key"  # Optional
PROPERTY_SAMPLE_RATE_IN = 'sample_rate_in'  # Optional
PROPERTY_SAMPLE_RATE_OUT = 'sample_rate_out'  # Optional
PROPERTY_WEBSOCKET_URL = 'websocket_url' 
PROPERTY_LANG_CODE   = 'lang_code'  # Optional
PROPERTY_GREETING   = 'greeting'  # Optional
PROPERTY_PROMPT     = 'prompt'  # Optional
PROPERTY_VOICE      = 'voice'  # Optional
PROPERTY_POLYGLOT_VOICE_ENABLED = 'polyglot_voice_enabled'  # Optional
PROPERTY_TURN_TAKING_PAUSE_SENSITIVITY = 'turn_taking_pause_sensitivity'  # Optional

class NovaSonicExtension(Extension):
    def __init__(self, name: str):
        super().__init__(name)

        self.stopped = False
        self.queue = asyncio.Queue(maxsize=3000)  # about 3000 * 10ms = 30s input
        self.sonic_client = None
        self.thread = None

        self.loop = asyncio.new_event_loop()
        asyncio.set_event_loop(self.loop)

        self.outdateTs = datetime.now()
        self.text_queue = asyncio.Queue()

    def on_start(self, rte: RteEnv) -> None:
        logger.info("NovaSonicExtension on_start")

        sonic_config = NovaSonicConfig.default_config()

        for optional_param in [PROPERTY_REGION, PROPERTY_SAMPLE_RATE_IN, PROPERTY_SAMPLE_RATE_OUT, 
                PROPERTY_ACCESS_KEY, PROPERTY_SECRET_KEY, PROPERTY_WEBSOCKET_URL,
                PROPERTY_LANG_CODE, PROPERTY_GREETING, PROPERTY_PROMPT, PROPERTY_VOICE,
                PROPERTY_POLYGLOT_VOICE_ENABLED, PROPERTY_TURN_TAKING_PAUSE_SENSITIVITY]:
            try:
                value = rte.get_property_string(optional_param).strip()
                # logger.info(f'param: {optional_param}, value: {value}')
                if value:
                    sonic_config.__setattr__(optional_param, value)
            except Exception as err:
                logger.info(f"GetProperty optional {optional_param} failed, err: {err}. Using default value: {sonic_config.__getattribute__(optional_param)}")

        sonic_config.validate_config()
        logger.info(f"Nova Sonic config - voice: {sonic_config.voice}, lang_code: {sonic_config.lang_code}, "
                   f"polyglot_voice_enabled: {sonic_config.polyglot_voice_enabled}, "
                   f"turn_taking_pause_sensitivity: {sonic_config.turn_taking_pause_sensitivity}")

        self.sonic_client = AsyncNovaSonicClient(sonic_config, self.queue, rte, self.loop)

        logger.info("Starting AsyncNovaSonicClient thread")
        self.thread = threading.Thread(target=self.sonic_client.run, args=[])
        self.thread.start()

        rte.on_start_done()

    def put_pcm_frame(self, pcm_frame: PcmFrame) -> None:
        if self.loop.is_closed():
            logger.warning("Event loop is closed, cannot enqueue frame")
            return

        try:
            asyncio.run_coroutine_threadsafe(self.queue.put(pcm_frame), self.loop).result(timeout=0.1)
        except asyncio.QueueFull:
            logger.exception("Queue is full, dropping frame")
        except asyncio.TimeoutError:
            logger.warning("Timeout while putting frame in queue")
        except Exception as e:
            logger.exception(f"Error putting frame in queue: {e}")

    def on_pcm_frame(self, rte: RteEnv, pcm_frame: PcmFrame) -> None:
        self.put_pcm_frame(pcm_frame=pcm_frame)

    def on_data(self, rte: RteEnv, data: Data) -> None:
        """Handle text data that should be processed by the WebSocket server"""
        logger.info("NovaSonicExtension on_data")
        
        try:
            # Extract text from the data object
            input_text = data.get_property_string("text")
            is_end = data.get_property_bool("end_of_segment")
            
            logger.info(f"Received text data: {input_text}, is_end: {is_end}")
            
            # Currently, the WebSocket server doesn't support direct text input
            # This is where we would handle text input if supported
            logger.warning("Direct text input not supported by Nova Sonic WebSocket server")
            
        except Exception as e:
            logger.exception(f"Error processing text data: {e}")

    def need_interrupt(self, ts: datetime) -> bool:
        return (self.outdateTs - ts).total_seconds() > 1

    def flush(self):
        logger.info("NovaSonicExtension flush")
        # Clear the queue
        while not self.queue.empty():
            try:
                asyncio.run_coroutine_threadsafe(self.queue.get(), self.loop).result(timeout=0.1)
            except Exception:
                pass

    def on_stop(self, rte: RteEnv) -> None:
        logger.info("NovaSonicExtension on_stop")

        # put an empty frame to stop the client
        self.put_pcm_frame(None)
        self.stopped = True
        
        if self.sonic_client:
            self.sonic_client.stop()
            
        if self.thread:
            self.thread.join()
            
        self.loop.stop()
        self.loop.close()

        rte.on_stop_done()

    def on_cmd(self, rte: RteEnv, cmd: Cmd) -> None:
        logger.info("NovaSonicExtension on_cmd")
        cmd_json = cmd.to_json()
        logger.info(f"NovaSonicExtension on_cmd json: {cmd_json}")
        
        try:
            cmd_json = json.loads(cmd_json)

            cmd_name = cmd.get_name()
            logger.info(f"got cmd {cmd_name}")
            
            if cmd_name == "on_user_joined":
                # Set user ID in the sonic client
                self.sonic_client.set_user_id(cmd_json.get('user_id', '0'), cmd_json.get('remote_user_id', '0'))
            elif cmd_name == "flush":
                # Handle flush command - clear the queue and update timestamp
                self.outdateTs = datetime.now()
                self.flush()

            cmd_result = CmdResult.create(StatusCode.OK)
            cmd_result.set_property_string("detail", "success")
            rte.return_result(cmd_result, cmd)
        except Exception as e:
            logger.exception(f"Error handling cmd: {e}")
            cmd_result = CmdResult.create(StatusCode.ERROR)
            cmd_result.set_property_string("detail", str(e))
            rte.return_result(cmd_result, cmd)