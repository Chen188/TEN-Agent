from threading import Thread
from rte import (
    Addon,
    Extension,
    register_addon_as_extension,
    RteEnv,
    Cmd,
    Data,
    StatusCode,
    CmdResult,
    MetadataInfo,
)
from .bedrock_llm import BedrockLLM, BedrockLLMConfig
from .data_parser import *
from .log import logger
from .property import *
from .utils import *

class BedrockLLMExtension(Extension):
    memory = []
    max_memory_length = 10
    outdate_ts = 0
    bedrock_llm = None

    def on_start(self, rte: RteEnv) -> None:
        logger.info("BedrockLLMExtension on_start")
        # Prepare configuration
        bedrock_llm_config = BedrockLLMConfig.default_config()

        for optional_str_param in [PROPERTY_REGION, PROPERTY_ACCESS_KEY, PROPERTY_SECRET_KEY,
            PROPERTY_MODEL, PROPERTY_PROMPT, PROPERTY_MODE, PROPERTY_INPUT_LANGUAGE,
            PROPERTY_OUTPUT_LANGUAGE, PROPERTY_USER_TEMPLATE]:
            try:
                value = rte.get_property_string(optional_str_param).strip()
                if value:
                    bedrock_llm_config.__setattr__(optional_str_param, value)
            except Exception as err:
                logger.debug(f"GetProperty optional {optional_str_param} failed, err: {err}. Using default value: {bedrock_llm_config.__getattribute__(optional_str_param)}")

        for optional_float_param in [PROPERTY_TEMPERATURE, PROPERTY_TOP_P]:
            try:
                value = rte.get_property_float(optional_float_param)
                if value:
                    bedrock_llm_config.__setattr__(optional_float_param, value)
            except Exception as err:
                logger.debug(f"GetProperty optional {optional_float_param} failed, err: {err}. Using default value: {bedrock_llm_config.__getattribute__(optional_float_param)}")

        try:
            max_tokens = rte.get_property_int(PROPERTY_MAX_TOKENS)
            if max_tokens > 0:
                bedrock_llm_config.max_tokens = int(max_tokens)
        except Exception as err:
            logger.debug(
                f"GetProperty optional {PROPERTY_MAX_TOKENS} failed, err: {err}. Using default value: {bedrock_llm_config.max_tokens}"
            )

        try:
            greeting = rte.get_property_string(PROPERTY_GREETING)
        except Exception as err:
            logger.debug(
                f"GetProperty optional {PROPERTY_GREETING} failed, err: {err}."
            )

        try:
            prop_max_memory_length = rte.get_property_int(PROPERTY_MAX_MEMORY_LENGTH)
            if prop_max_memory_length >= 0:
                self.max_memory_length = int(prop_max_memory_length)
        except Exception as err:
            logger.debug(
                f"GetProperty optional {PROPERTY_MAX_MEMORY_LENGTH} failed, err: {err}."
            )

        bedrock_llm_config.validate()

        # Create bedrockLLM instance
        try:
            self.bedrock_llm = BedrockLLM(bedrock_llm_config)
            logger.info(
                f"newBedrockLLM succeed with max_tokens: {bedrock_llm_config.max_tokens}, model: {bedrock_llm_config.model}"
            )
        except Exception as err:
            logger.exception(f"newBedrockLLM failed, err: {err}")

        if bedrock_llm_config.mode == 'translate':
            self.input_data_parser = DataParserTranslate(user_template=bedrock_llm_config.user_template)
        else:
            self.input_data_parser = DataParserChat(user_template=bedrock_llm_config.user_template)

        # Send greeting if available
        if greeting:
            try:
                output_data = Data.create("text_data")
                output_data.set_property_string(
                    DATA_OUT_TEXT_DATA_PROPERTY_TEXT, greeting
                )
                output_data.set_property_bool(
                    DATA_OUT_TEXT_DATA_PROPERTY_TEXT_END_OF_SEGMENT, True
                )
                rte.send_data(output_data)
                logger.info(f"greeting [{greeting}] sent")
            except Exception as err:
                logger.info(f"greeting [{greeting}] send failed, err: {err}")
        rte.on_start_done()

    def on_stop(self, rte: RteEnv) -> None:
        logger.info("BedrockLLMExtension on_stop")
        rte.on_stop_done()

    def on_cmd(self, rte: RteEnv, cmd: Cmd) -> None:
        logger.info("BedrockLLMExtension on_cmd")
        cmd_json = cmd.to_json()
        logger.info("BedrockLLMExtension on_cmd json: " + cmd_json)

        cmd_name = cmd.get_name()

        if cmd_name == CMD_IN_FLUSH:
            if self.bedrock_llm.config.mode != 'translate':
                self.outdate_ts = get_current_time()
                cmd_out = Cmd.create(CMD_OUT_FLUSH)
                rte.send_cmd(cmd_out, None)
                logger.info(f"BedrockLLMExtension on_cmd sent flush")
            else:
                logger.info(f"BedrockLLMExtension on_cmd ignore flush in '{self.bedrock_llm.config.mode}' mode.")
        else:
            logger.info(f"BedrockLLMExtension on_cmd unknown cmd: {cmd_name}")
            cmd_result = CmdResult.create(StatusCode.ERROR)
            cmd_result.set_property_string("detail", "unknown cmd")
            rte.return_result(cmd_result, cmd)
            return

        cmd_result = CmdResult.create(StatusCode.OK)
        cmd_result.set_property_string("detail", "success")
        rte.return_result(cmd_result, cmd)

    def on_data(self, rte: RteEnv, data: Data) -> None:
        """
        on_data receives data from rte graph.
        current supported data:
          - name: text_data
            example:
            {name: text_data, properties: {text: "hello"}}
        """
        logger.info(f"BedrockLLMExtension on_data")
        # logger.info(data.to_json())

        input_text = self.input_data_parser.parse(data, self.bedrock_llm)
        if not input_text:
            return

        # Prepare memory. A conversation must alternate between user and assistant roles
        while len(self.memory):
            if len(self.memory) > self.max_memory_length:
                logger.debug(
                    f"pop out first message, reason: memory length limit: `{self.memory[0]}`"
                )
                self.memory.pop(0)
            elif self.memory[0]["role"] == "assistant":
                logger.debug(
                    f"pop out first message, reason: messages can not start with assistant: `{self.memory[0]}`"
                )
                self.memory.pop(0)
            else:
                break

        if len(self.memory) and self.memory[-1]["role"] == "user":
            # if last user input got empty response, append current user input.
            logger.debug(
                f"found last message with role `user`, will append this input into last user input"
            )
            self.memory[-1]["content"].append({"text": input_text})
        else:
            self.memory.append({"role": "user", "content": [{"text": input_text}]})

        if self.bedrock_llm.config.mode == 'translate':
            self.memory.append({"role": "assistant", "content": [{"text": "Sure, here's the translation result: <translation>"}]})

        def converse_stream_worker(start_time, input_text, memory, raw_text):
            try:
                logger.info(f"GetConverseStream for input text: [{raw_text}], memory: [{memory}], full prompt: [{input_text}]")

                # Get result from Bedrock
                resp = self.bedrock_llm.get_converse_resp(memory)
                if resp is None or resp.get("stream") is None:
                    logger.info(
                        f"GetConverseStream for input text: [{raw_text}] failed"
                    )
                    return

                stream = resp.get("stream")
                sentence = ""
                full_content = ""
                first_sentence_sent = False

                for event in stream:
                    # allow 100ms buffer time, in case interruptor's flush cmd comes just after on_data event
                    if (start_time + 100_000) < self.outdate_ts:
                        logger.info(f"GetConverseStream recv interrupt and flushing for input text: [{input_text}], startTs: {start_time}, outdateTs: {self.outdate_ts}, delta > 100ms")
                        break

                    if "contentBlockDelta" in event:
                        delta_types = event["contentBlockDelta"]["delta"].keys()
                        # ignore other types of content: e.g toolUse
                        if "text" in delta_types:
                            content = event["contentBlockDelta"]["delta"]["text"]
                    elif (
                        "internalServerException" in event
                        or "modelStreamErrorException" in event
                        or "throttlingException" in event
                        or "validationException" in event
                    ):
                        logger.error(f"GetConverseStream Error occured: {event}")
                        break
                    else:
                        # ingore other events
                        continue

                    full_content += content

                    while True:
                        sentence, content, sentence_is_final = parse_sentence(
                            sentence, content
                        )
                        if not sentence or not sentence_is_final:
                            # logger.info(f"sentence [{sentence}] is empty or not final")
                            break
                        logger.info(
                            f"GetConverseStream recv for input text: [{raw_text}] got sentence: [{sentence}]"
                        )

                        # send sentence
                        try:
                            output_data = Data.create("text_data")
                            output_data.set_property_string(
                                DATA_OUT_TEXT_DATA_PROPERTY_TEXT, sentence
                            )
                            output_data.set_property_bool(
                                DATA_OUT_TEXT_DATA_PROPERTY_TEXT_END_OF_SEGMENT, False
                            )
                            rte.send_data(output_data)
                            logger.info(
                                f"GetConverseStream recv for input text: [{raw_text}] sent sentence [{sentence}]"
                            )
                        except Exception as err:
                            logger.info(
                                f"GetConverseStream recv for input text: [{raw_text}] send sentence [{sentence}] failed, err: {err}"
                            )
                            break

                        sentence = ""
                        if not first_sentence_sent:
                            first_sentence_sent = True
                            logger.info(
                                f"GetConverseStream recv for input text: [{raw_text}] first sentence sent, model's first_sentence_latency {get_current_time() - start_time}ms"
                            )

                if len(full_content.strip()):
                    # remember response as assistant content in memory
                    if memory and memory[-1]['role'] == 'assistant':
                        memory[-1]['content'].append({"text": full_content})
                    else:
                        memory.append(
                        {"role": "assistant", "content": [{"text": full_content}]}
                    )
                else:
                    # can not put empty model response into memory
                    logger.error(
                        f"GetConverseStream recv for input text: [{raw_text}] failed: empty response [{full_content}]"
                    )
                    return

                # send end of segment
                try:
                    output_data = Data.create("text_data")
                    output_data.set_property_string(
                        DATA_OUT_TEXT_DATA_PROPERTY_TEXT, sentence
                    )
                    output_data.set_property_bool(
                        DATA_OUT_TEXT_DATA_PROPERTY_TEXT_END_OF_SEGMENT, True
                    )
                    rte.send_data(output_data)
                    logger.info(
                        f"GetConverseStream for input text: [{raw_text}] end of segment with sentence [{sentence}] sent"
                    )
                except Exception as err:
                    logger.info(
                        f"GetConverseStream for input text: [{input_text}] end of segment with sentence [{sentence}] send failed, err: {err}"
                    )

            except Exception as e:
                logger.info(
                    f"GetConverseStream for input text: [{input_text}] failed, err: {e}"
                )

        # Start thread to request and read responses from OpenAI
        start_time = get_current_time()
        thread = Thread(
            target=converse_stream_worker, args=(start_time, input_text, self.memory, data.get_property_string(DATA_IN_TEXT_DATA_PROPERTY_TEXT))
        )
        thread.start()
        logger.info(f"BedrockLLMExtension on_data end")


@register_addon_as_extension("bedrock_llm_python")
class BedrockLLMExtensionAddon(Addon):
    def on_create_instance(self, rte: RteEnv, addon_name: str, context) -> None:
        logger.info("on_create_instance")
        rte.on_create_instance_done(BedrockLLMExtension(addon_name), context)
