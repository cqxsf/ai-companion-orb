"""
AES-256-GCM encryption helpers for conversation content (CLAUDE.md §十二).

The ENCRYPTION_KEY setting must be a URL-safe base64-encoded 32-byte value.
If the key is not configured a fallback no-op codec is used so that the server
can start without encryption during local development.
"""

from __future__ import annotations

import base64
import logging
import os

from src.config import settings

logger = logging.getLogger(__name__)


def _get_key() -> bytes | None:
    raw = settings.ENCRYPTION_KEY
    if not raw:
        return None
    try:
        key = base64.urlsafe_b64decode(raw + "==")
        if len(key) != 32:
            logger.warning("ENCRYPTION_KEY must decode to exactly 32 bytes; encryption disabled")
            return None
        return key
    except Exception:
        logger.warning("Invalid ENCRYPTION_KEY; encryption disabled")
        return None


def encrypt_text(plaintext: str) -> bytes:
    """
    Encrypt *plaintext* with AES-256-GCM.

    Returns  nonce (12 bytes) + ciphertext + tag (16 bytes) as raw bytes.
    Falls back to UTF-8 bytes when the key is not configured.
    """
    key = _get_key()
    if key is None:
        return plaintext.encode()

    from cryptography.hazmat.primitives.ciphers.aead import AESGCM

    nonce = os.urandom(12)
    aesgcm = AESGCM(key)
    ciphertext = aesgcm.encrypt(nonce, plaintext.encode(), None)
    return nonce + ciphertext


def decrypt_text(ciphertext: bytes) -> str:
    """
    Decrypt bytes produced by :func:`encrypt_text`.

    Falls back to UTF-8 decoding when the key is not configured.
    """
    key = _get_key()
    if key is None:
        return ciphertext.decode()

    from cryptography.hazmat.primitives.ciphers.aead import AESGCM

    nonce = ciphertext[:12]
    data = ciphertext[12:]
    aesgcm = AESGCM(key)
    return aesgcm.decrypt(nonce, data, None).decode()
