from pydantic import BaseModel


class WebSocketMessage(BaseModel):
    type: str          # "audio_chunk"
    data: str          # base64-encoded Opus audio
    seq: int = 0


class AIResponse(BaseModel):
    type: str = "ai_response"
    text: str
    audio: str         # base64-encoded Opus audio
    mood: str = "calm"


class MoodUpdate(BaseModel):
    type: str = "mood_update"
    mood: str
    transition_ms: int = 500
