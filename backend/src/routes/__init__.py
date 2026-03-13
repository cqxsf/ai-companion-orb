from src.routes.auth import router as auth_router
from src.routes.devices import router as devices_router
from src.routes.conversation import router as conversation_router
from src.routes.family import router as family_router
from src.routes.behavior import router as behavior_router
from src.routes.alerts import router as alerts_router

__all__ = [
    "auth_router",
    "devices_router",
    "conversation_router",
    "family_router",
    "behavior_router",
    "alerts_router",
]
