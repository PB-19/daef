import logging
from sqlalchemy.ext.asyncio import AsyncEngine

from app.database.base import Base, engine

logger = logging.getLogger(__name__)


async def init_db() -> None:
    from app.models import (  # noqa: F401
        User,
        Evaluation,
        EvaluationMetric,
        EvaluationVersion,
        SocialPost,
        Like,
        Comment,
        Notification,
    )

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    logger.info("Database tables created / verified")


async def close_db(db_engine: AsyncEngine = engine) -> None:
    await db_engine.dispose()
    logger.info("Database engine disposed")
