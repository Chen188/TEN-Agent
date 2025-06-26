from rte import *
from .nova_sonic_extension import NovaSonicExtension
from .extension import EXTENSION_NAME
from .log import logger

@register_addon_as_extension(EXTENSION_NAME)
class NovaSonicExtensionAddon(Addon):
    def on_create_instance(self, rte: RteEnv, addon_name: str, context) -> None:
        logger.info("on_create_instance")

        rte.on_create_instance_done(NovaSonicExtension(addon_name), context)
