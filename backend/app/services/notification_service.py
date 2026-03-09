import logging
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, func
from fastapi import HTTPException, status

from app.models.notification import Notification, NotificationType
from app.utils.helpers import new_uuid

logger = logging.getLogger(__name__)


async def create_notification(
    db: AsyncSession,
    user_id: str,
    type: NotificationType,
    title: str,
    message: str,
    related_evaluation_id: str = None,
    related_post_id: str = None,
    related_user_id: str = None,
) -> Notification:
    notification = Notification(
        id=new_uuid(),
        user_id=user_id,
        type=type,
        title=title,
        message=message,
        related_evaluation_id=related_evaluation_id,
        related_post_id=related_post_id,
        related_user_id=related_user_id,
    )
    db.add(notification)
    await db.flush()
    logger.debug("Notification created for user %s: %s", user_id, type)
    return notification


async def get_notifications(
    user_id: str,
    db: AsyncSession,
    unread_only: bool = False,
    limit: int = 50,
) -> list[Notification]:
    query = select(Notification).where(Notification.user_id == user_id)
    if unread_only:
        query = query.where(Notification.is_read == False)  # noqa: E712
    query = query.order_by(Notification.created_at.desc()).limit(limit)
    result = await db.execute(query)
    return list(result.scalars().all())


async def mark_read(notification_id: str, user_id: str, db: AsyncSession) -> None:
    result = await db.execute(
        select(Notification).where(
            Notification.id == notification_id,
            Notification.user_id == user_id,
        )
    )
    notification = result.scalar_one_or_none()
    if not notification:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")
    notification.is_read = True
    db.add(notification)
    await db.flush()


async def mark_all_read(user_id: str, db: AsyncSession) -> None:
    await db.execute(
        update(Notification)
        .where(Notification.user_id == user_id, Notification.is_read == False)  # noqa: E712
        .values(is_read=True)
    )


async def get_unread_count(user_id: str, db: AsyncSession) -> int:
    result = await db.execute(
        select(func.count()).where(
            Notification.user_id == user_id,
            Notification.is_read == False,  # noqa: E712
        )
    )
    return result.scalar_one()
