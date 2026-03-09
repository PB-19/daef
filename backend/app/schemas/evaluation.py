from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, List, Dict, Any
from datetime import datetime


class CustomMetric(BaseModel):
    name: str
    description: str


class EvaluationCreate(BaseModel):
    domain: str
    task_description: str
    task_type: str = Field(..., pattern="^(rag|tuning|single_call)$")
    focus_areas: List[str] = Field(..., max_length=3)
    mandatory_metrics: Optional[List[str]] = []
    avoided_metrics: Optional[List[str]] = []
    custom_metrics: Optional[List[CustomMetric]] = []

    prompt: str
    llm_output: str
    context_data: Optional[str] = None
    attached_files: Optional[List[str]] = []  # GCS paths


class EvaluationCompare(BaseModel):
    base_evaluation_id: str
    new_evaluation_id: str


class MetricResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    metric_name: str
    metric_category: Optional[str]
    score: float
    max_score: float
    weight: Optional[float]
    reasoning: Optional[str]


class EvaluationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    domain: str
    task_description: str
    task_type: str
    focus_areas: Optional[List[str]]

    prompt: str
    llm_output: str
    context_data: Optional[str]

    overall_score: Optional[float]
    evaluation_report: Optional[Dict[str, Any]]
    agent_insights: Optional[str]

    status: str
    error_message: Optional[str]
    processing_time_seconds: Optional[int]

    created_at: datetime
    updated_at: datetime


class EvaluationDetailResponse(EvaluationResponse):
    metrics: List[MetricResponse] = []


class VersionComparisonResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    base_evaluation_id: str
    new_evaluation_id: str
    comparison_report: Optional[Dict[str, Any]]
    performance_change: Optional[str]
    score_difference: Optional[float]
    created_at: datetime
