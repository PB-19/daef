"""
Run from backend/ directory:
    python -m scripts.create_dummy_users
"""
import asyncio
import sys
import os
import logging

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())

from app.core.logging import setup_logging
from app.database.base import async_session_maker
from app.database.init_db import init_db
from app.models.user import User
from app.core.security import hash_password
from app.utils.helpers import new_uuid
from sqlalchemy import select

setup_logging()
logger = logging.getLogger(__name__)

DUMMY_USERS = [
    {"email": "alice@example.com", "username": "alice", "full_name": "Alice Chen", "password": "alice123@"},
    {"email": "bob@example.com", "username": "bob", "full_name": "Bob Smith", "password": "bob123@"},
    {"email": "charlie@example.com", "username": "charlie", "full_name": "Charlie Park", "password": "charlie123@"},
    {"email": "diana@example.com", "username": "diana", "full_name": "Diana Patel", "password": "diana123@"},
    {"email": "evan@example.com", "username": "evan", "full_name": "Evan Torres", "password": "evan123@"},
]


async def create_dummy_users() -> None:
    await init_db()

    async with async_session_maker() as db:
        for u in DUMMY_USERS:
            result = await db.execute(select(User).where(User.email == u["email"]))
            if result.scalar_one_or_none():
                logger.info("User already exists: %s", u["email"])
                continue

            user = User(
                id=new_uuid(),
                email=u["email"],
                username=u["username"],
                full_name=u["full_name"],
                password_hash=hash_password(u["password"]),
            )
            db.add(user)
            logger.info("Created user: %s", u["email"])

        await db.commit()
    logger.info("Dummy users created successfully")


if __name__ == "__main__":
    asyncio.run(create_dummy_users())
