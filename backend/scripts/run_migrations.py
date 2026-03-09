"""
Simple wrapper to run create_all (dev mode).
Run from backend/ directory:
    python -m scripts.run_migrations
"""
import asyncio
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.logging import setup_logging
from app.database.init_db import init_db

setup_logging()

if __name__ == "__main__":
    asyncio.run(init_db())
