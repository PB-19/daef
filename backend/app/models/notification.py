import enum
from sqlalchemy import Column, String, Text, Boolean, Enum, DateTime, ForeignKey
from sqlalchemy.sql import func

from app.database.base import Base


class NotificationType(str, enum.Enum):
    EVAL_COMPLETE = "eval_complete"
    LIKE = "like"
    COMMENT = "comment"


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(String(36), primary_key=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    type = Column(Enum(NotificationType), nullable=False)
    title = Column(String(200), nullable=False)
    message = Column(Text, nullable=False)

    # Related entities
    related_evaluation_id = Column(String(36))
    related_post_id = Column(String(36))
    related_user_id = Column(String(36))

    is_read = Column(Boolean, default=False, index=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)
