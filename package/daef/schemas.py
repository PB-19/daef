from __future__ import annotations
from typing import Literal
from pydantic import BaseModel, Field


class EvaluationRequest(BaseModel):
    domain: str
    task_description: str
    task_type: Literal["rag", "tuning", "single_call"]
    focus_areas: list[str] = Field(default_factory=list)
    prompt: str = ""
    llm_output: str = ""
    context_data: str | None = None
    mandatory_metrics: list[str] = Field(default_factory=list)
    avoided_metrics: list[str] = Field(default_factory=list)
    custom_metrics: list[str] = Field(default_factory=list)


class MetricScore(BaseModel):
    metric_name: str
    metric_category: str
    score: float = Field(ge=0.0, le=100.0)
    max_score: float = 100.0
    weight: float = Field(ge=0.0, le=1.0)
    reasoning: str


class EvaluationResult(BaseModel):
    overall_score: float
    summary: str
    metrics: list[MetricScore]
    agent_insights: str
    scoring_guides: dict[str, str] = Field(default_factory=dict)


class MetricComparison(BaseModel):
    metric_name: str
    base_score: float
    new_score: float
    change: float
    analysis: str


class ComparisonResult(BaseModel):
    metric_comparisons: list[MetricComparison]
    overall_change: Literal["better", "worse", "similar"]
    key_improvements: list[str]
    key_regressions: list[str]
    summary: str
    recommendation: str


__all__ = [
    "EvaluationRequest",
    "MetricScore",
    "EvaluationResult",
    "MetricComparison",
    "ComparisonResult",
]
