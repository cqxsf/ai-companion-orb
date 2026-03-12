from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://orb:orb_password@localhost:5432/orb_db"
    REDIS_URL: str = "redis://localhost:6379/0"

    # JWT
    SECRET_KEY: str = "change-me-to-a-random-secret-key-at-least-32-chars"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 hours

    # LLM providers
    DASHSCOPE_API_KEY: str = ""
    DEEPSEEK_API_KEY: str = ""

    # Push notifications (JPush)
    JPUSH_APP_KEY: str = ""
    JPUSH_MASTER_SECRET: str = ""

    # AES-256 encryption key for conversation content (base64-encoded 32 bytes)
    ENCRYPTION_KEY: str = ""

    # OTA
    OTA_SERVER_URL: str = "https://ota.example.com"

    # Rate limiting
    RATE_LIMIT_PER_MINUTE: int = 60

    # LLM context window (number of turns to keep)
    LLM_CONTEXT_WINDOW: int = 20

    # Speech services
    COSYVOICE_API_URL: str = "https://dashscope.aliyuncs.com/api/v1/services/audio/tts"
    PARAFORMER_API_URL: str = "https://dashscope.aliyuncs.com/api/v1/services/audio/asr"


settings = Settings()
