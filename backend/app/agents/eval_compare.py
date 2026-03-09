import logging
from pydantic import BaseModel, Field
from google.adk.agents import LlmAgent
from google.genai.types import GenerateContentConfig
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai.types import Content, Part

from app.agents.utils.prompt_templates import EVAL_COMPARE_INSTRUCTION

logger = logging.getLogger(__name__)

_MODEL = "gemini-2.5-flash"
_APP_NAME = "daef_compare"


class MetricComparison(BaseModel):
    metric_name: str
    base_score: float
    new_score: float
    change: float
    analysis: str = Field(description="1 sentence explaining why this metric changed")


class ComparisonOutput(BaseModel):
    metric_comparisons: list[MetricComparison]
    overall_change: str = Field(description="'better', 'worse', or 'similar'")
    key_improvements: list[str] = Field(description="Up to 3 specific improvements")
    key_regressions: list[str] = Field(description="Up to 3 specific regressions")
    summary: str = Field(description="2-3 sentence plain-language comparison summary")
    recommendation: str = Field(description="1-2 sentence actionable recommendation")


eval_compare_agent = LlmAgent(
    name="EvalCompareAgent",
    model=_MODEL,
    description=(
        "Compares two evaluation results to explain performance differences at the metric level. "
        "Identifies root causes of improvements and regressions, and provides actionable recommendations."
    ),
    instruction=EVAL_COMPARE_INSTRUCTION,
    output_schema=ComparisonOutput,
    output_key="comparison_result",
    include_contents="none",
    disallow_transfer_to_parent=True,
    generate_content_config=GenerateContentConfig(
        temperature=0.1,
    ),
)

_compare_session_service = InMemorySessionService()
_compare_runner = Runner(
    agent=eval_compare_agent,
    app_name=_APP_NAME,
    session_service=_compare_session_service,
)


async def run_comparison_pipeline(
    base_evaluation: dict,
    new_evaluation: dict,
    user_id: str,
    session_id: str,
) -> dict:
    import json

    initial_state = {
        "base_evaluation": json.dumps(base_evaluation, default=str),
        "new_evaluation": json.dumps(new_evaluation, default=str),
    }

    session = await _compare_session_service.create_session(
        app_name=_APP_NAME,
        user_id=user_id,
        session_id=session_id,
        state=initial_state,
    )

    trigger = Content(role="user", parts=[Part(text="Compare the two evaluations.")])

    async for event in _compare_runner.run_async(
        user_id=user_id,
        session_id=session.id,
        new_message=trigger,
    ):
        if event.is_final_response():
            logger.debug("EvalCompareAgent final response received")

    final_session = await _compare_session_service.get_session(
        app_name=_APP_NAME,
        user_id=user_id,
        session_id=session.id,
    )

    result = final_session.state.get("comparison_result")
    if not result:
        raise RuntimeError("EvalCompareAgent produced no output")

    if isinstance(result, str):
        result = json.loads(result)

    logger.info("Comparison pipeline complete for session %s", session_id)
    return result


__all__ = ["eval_compare_agent", "ComparisonOutput", "MetricComparison", "run_comparison_pipeline"]
