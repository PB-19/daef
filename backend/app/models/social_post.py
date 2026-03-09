from sqlalchemy import Column, String, Text, Integer, DECIMAL, DateTime, ForeignKey, Enum
from sqlalchemy.sql import func

from app.database.base import Base
from app.models.evaluation import TaskType


class SocialPost(Base):
    __tablename__ = "social_posts"

    id = Column(String(36), primary_key=True)
    evaluation_id = Column(String(36), ForeignKey("evaluations.id", ondelete="CASCADE"), nullable=False, unique=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    title = Column(String(200))
    description = Column(Text)

    # Denormalized for performance
    overall_score = Column(DECIMAL(5, 2), index=True)
    domain = Column(String(100))
    task_type = Column(Enum(TaskType))

    # Engagement metrics
    likes_count = Column(Integer, default=0, index=True)
    comments_count = Column(Integer, default=0, index=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
