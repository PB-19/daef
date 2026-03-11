"""
Drops all tables, recreates schema, and seeds users only.

Run from backend/ directory:
    python -m scripts.reset_db
"""
import asyncio
import sys
import os
import logging

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())

from app.core.logging import setup_logging
from app.database.base import Base, engine, async_session_maker
from app.core.security import hash_password
from app.utils.helpers import new_uuid

setup_logging()
logger = logging.getLogger(__name__)

SEED_USERS = [
    {"email": "alice@example.com", "username": "alice", "full_name": "Alice Chen", "password": "alice123@"},
    {"email": "bob@example.com", "username": "bob", "full_name": "Bob Smith", "password": "bob123@"},
    {"email": "charlie@example.com", "username": "charlie", "full_name": "Charlie Park", "password": "charlie123@"},
    {"email": "diana@example.com", "username": "diana", "full_name": "Diana Patel", "password": "diana123@"},
    {"email": "evan@example.com", "username": "evan", "full_name": "Evan Torres", "password": "evan123@"},
]


async def reset() -> None:
    # Import all models so metadata is populated
    from app.models import (  # noqa: F401
        User, Evaluation, EvaluationMetric, EvaluationVersion,
        SocialPost, Like, Comment, Notification,
    )
    from app.models.user import User as UserModel

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        logger.info("All tables dropped")
        await conn.run_sync(Base.metadata.create_all)
        logger.info("All tables recreated")

    async with async_session_maker() as db:
        for u in SEED_USERS:
            user = UserModel(
                id=new_uuid(),
                email=u["email"],
                username=u["username"],
                full_name=u["full_name"],
                password_hash=hash_password(u["password"]),
            )
            db.add(user)
            logger.info("Seeded user: %s", u["email"])
        await db.commit()

    logger.info("Database reset complete — %d users seeded", len(SEED_USERS))
    logger.info("")
    logger.info("  %-28s  %s", "Email", "Password")
    logger.info("  " + "-" * 45)
    for u in SEED_USERS:
        logger.info("  %-28s  %s", u["email"], u["password"])


if __name__ == "__main__":
    asyncio.run(reset())
