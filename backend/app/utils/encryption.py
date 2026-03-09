import logging
from cryptography.fernet import Fernet

from app.core.config import settings

logger = logging.getLogger(__name__)

_fernet = Fernet(settings.ENCRYPTION_KEY.encode())


def encrypt(value: str) -> str:
    encrypted = _fernet.encrypt(value.encode()).decode()
    logger.debug("Value encrypted")
    return encrypted


def decrypt(value: str) -> str:
    decrypted = _fernet.decrypt(value.encode()).decode()
    logger.debug("Value decrypted")
    return decrypted
