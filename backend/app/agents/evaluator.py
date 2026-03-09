import logging
from pydantic import BaseModel, Field
from google.adk.agents import LlmAgent
from google.genai.types import GenerateContentConfig

from app.agents.utils.prompt_templates import EVALUATOR_INSTRUCTION

logger = logging.getLogger(__name__)

_MODEL = "gemini-2.0-flash"


class MetricScore(BaseModel):
    metric_name: str
    metric_category: str
    score: float = Field(ge=0.0, le=100.0)
    max_score: float = Field(default=100.0)
    weight: float = Field(ge=0.0, le=1.0)
    reasoning: str


class EvaluationOutput(BaseModel):
    metrics: list[MetricScore]
    overall_score: float = Field(ge=0.0, le=100.0)
    agent_insights: str = Field(description="2-3 domain-specific actionable insights")
    evaluation_summary: str = Field(description="1-2 sentence high-level summary")


evaluator_agent = LlmAgent(
    name="EvaluatorAgent",
    model=_MODEL,
    description=(
        "Scores an LLM response against a curated set of domain-specific metrics. "
        "Produces per-metric scores (0-100), weighted overall score, and actionable insights. "
        "Does not use external tools — works purely from provided context."
    ),
    instruction=EVALUATOR_INSTRUCTION,
    output_schema=EvaluationOutput,
    output_key="evaluation_result",
    include_contents="none",
    disallow_transfer_to_parent=True,
    generate_content_config=GenerateContentConfig(
        temperature=0.1,
        max_output_tokens=2000,
    ),
)

__all__ = ["evaluator_agent", "EvaluationOutput", "MetricScore"]
