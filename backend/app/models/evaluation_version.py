import enum
from sqlalchemy import Column, String, Enum, DECIMAL, DateTime, JSON, ForeignKey
from sqlalchemy.sql import func

from app.database.base import Base


class PerformanceChange(str, enum.Enum):
    BETTER = "better"
    WORSE = "worse"
    SIMILAR = "similar"


class EvaluationVersion(Base):
    __tablename__ = "evaluation_versions"

    id = Column(String(36), primary_key=True)
    base_evaluation_id = Column(String(36), ForeignKey("evaluations.id", ondelete="CASCADE"), nullable=False, index=True)
    new_evaluation_id = Column(String(36), ForeignKey("evaluations.id", ondelete="CASCADE"), nullable=False, index=True)

    comparison_report = Column(JSON)
    performance_change = Column(Enum(PerformanceChange))
    score_difference = Column(DECIMAL(5, 2))

    created_at = Column(DateTime(timezone=True), server_default=func.now())
