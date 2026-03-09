import enum
from sqlalchemy import Column, String, Text, Enum, DateTime, Integer, DECIMAL, JSON, ForeignKey
from sqlalchemy.sql import func

from app.database.base import Base


class TaskType(str, enum.Enum):
    RAG = "rag"
    TUNING = "tuning"
    SINGLE_CALL = "single_call"


class EvaluationStatus(str, enum.Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"


class Evaluation(Base):
    __tablename__ = "evaluations"

    id = Column(String(36), primary_key=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    # Input data
    domain = Column(String(100), nullable=False)
    task_description = Column(Text, nullable=False)
    task_type = Column(Enum(TaskType), nullable=False)
    focus_areas = Column(JSON)
    mandatory_metrics = Column(JSON)
    avoided_metrics = Column(JSON)
    custom_metrics = Column(JSON)

    # Evaluation input
    prompt = Column(Text, nullable=False)
    llm_output = Column(Text, nullable=False)
    context_data = Column(Text)
    attached_files = Column(JSON)

    # Evaluation results
    overall_score = Column(DECIMAL(5, 2), index=True)
    evaluation_report = Column(JSON)
    agent_insights = Column(Text)

    # Metadata
    status = Column(Enum(EvaluationStatus), default=EvaluationStatus.PENDING, index=True)
    error_message = Column(Text)
    retry_count = Column(Integer, default=0)
    processing_time_seconds = Column(Integer)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
