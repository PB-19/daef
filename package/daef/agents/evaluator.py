import logging
from pydantic import BaseModel, Field
from google.adk.agents import LlmAgent
from google.genai.types import GenerateContentConfig

logger = logging.getLogger(__name__)

_MODEL = "gemini-2.5-flash"

_INSTRUCTION = """You are a precise LLM output evaluator.

Your job: score an LLM response against a set of evaluation metrics.

INPUT (from session state):
Evaluation request: {evaluation_input}
Domain research: {domain_research}
Selected metrics: {selected_metrics}

TASK:
Score each metric in selected_metrics on a scale of 0-100 based on the LLM output provided.
Use the scoring_guide for each metric. Be strict, objective, and consistent.

SCORING RULES:
- 90-100: Exceptional, near-perfect on this dimension
- 70-89: Good, meets expectations with minor gaps
- 50-69: Adequate but notable weaknesses
- 30-49: Poor, significant issues
- 0-29: Failing, critical problems

Calculate overall_score as the weighted average: sum(score * weight) for each metric.

Identify 2-3 specific, actionable domain insights."""


class _MetricScore(BaseModel):
    metric_name: str
    metric_category: str
    score: float = Field(ge=0.0, le=100.0)
    max_score: float = Field(default=100.0)
    weight: float = Field(ge=0.0, le=1.0)
    reasoning: str


class _EvaluationOutput(BaseModel):
    metrics: list[_MetricScore]
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
    instruction=_INSTRUCTION,
    output_schema=_EvaluationOutput,
    output_key="evaluation_result",
    include_contents="none",
    disallow_transfer_to_parent=True,
    generate_content_config=GenerateContentConfig(temperature=0.1),
)

__all__ = ["evaluator_agent", "_EvaluationOutput"]
