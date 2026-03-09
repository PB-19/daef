from fastapi import APIRouter

from app.api.routes import (
    auth,
    users,
    evaluations,
    comparisons,
    social,
    interactions,
    notifications,
    files,
    health,
)

api_router = APIRouter()

api_router.include_router(auth.router)
api_router.include_router(users.router)
api_router.include_router(evaluations.router)
api_router.include_router(comparisons.router)
api_router.include_router(social.router)
api_router.include_router(interactions.router)
api_router.include_router(notifications.router)
api_router.include_router(files.router)
api_router.include_router(health.router)

__all__ = ["api_router"]
