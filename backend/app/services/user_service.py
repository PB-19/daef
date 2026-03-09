import logging
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException, status

from app.models.user import User
from app.schemas.user import UserUpdate
from app.utils.encryption import encrypt

logger = logging.getLogger(__name__)


async def get_user_by_id(user_id: str, db: AsyncSession) -> User:
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return user


async def update_user(user: User, data: UserUpdate, db: AsyncSession) -> User:
    if data.full_name is not None:
        user.full_name = data.full_name
    if data.notifications_enabled is not None:
        user.notifications_enabled = data.notifications_enabled
    if data.theme_mode is not None:
        user.theme_mode = data.theme_mode
    if data.google_api_key is not None:
        user.google_api_key_encrypted = encrypt(data.google_api_key)

    db.add(user)
    await db.flush()
    await db.refresh(user)
    logger.info("User profile updated: %s", user.id)
    return user
