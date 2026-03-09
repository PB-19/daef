from sqlalchemy import Column, String, Text, DECIMAL, DateTime, ForeignKey
from sqlalchemy.sql import func

from app.database.base import Base


class EvaluationMetric(Base):
    __tablename__ = "evaluation_metrics"

    id = Column(String(36), primary_key=True)
    evaluation_id = Column(String(36), ForeignKey("evaluations.id", ondelete="CASCADE"), nullable=False, index=True)

    metric_name = Column(String(100), nullable=False, index=True)
    metric_category = Column(String(100))
    score = Column(DECIMAL(5, 2), nullable=False, index=True)
    max_score = Column(DECIMAL(5, 2), default=100)
    weight = Column(DECIMAL(3, 2))
    reasoning = Column(Text)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
