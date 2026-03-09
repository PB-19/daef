from sqlalchemy import Column, String, Text, DateTime, ForeignKey
from sqlalchemy.sql import func

from app.database.base import Base


class Comment(Base):
    __tablename__ = "comments"

    id = Column(String(36), primary_key=True)
    post_id = Column(String(36), ForeignKey("social_posts.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    content = Column(Text, nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
