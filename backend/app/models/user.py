import enum
from sqlalchemy import Column, String, Boolean, Enum, DateTime, Text
from sqlalchemy.sql import func

from app.database.base import Base


class ThemeMode(str, enum.Enum):
    LIGHT = "light"
    DARK = "dark"


class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    username = Column(String(50), unique=True, nullable=False, index=True)
    full_name = Column(String(100))
    google_api_key_encrypted = Column(Text)
    notifications_enabled = Column(Boolean, default=True)
    theme_mode = Column(Enum(ThemeMode), default=ThemeMode.LIGHT)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
