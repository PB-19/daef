import json
import logging
from typing import Any

from google.adk.agents import SequentialAgent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai.types import Content, Part

from app.agents.domain_research import domain_research_agent
from app.agents.eval_research import eval_research_agent
from app.agents.evaluator import evaluator_agent, EvaluationOutput
from app.models.evaluation import Evaluation

logger = logging.getLogger(__name__)

_APP_NAME = "daef_eval"

# ── Pipeline assembly (module-level singletons) ────────────────────────────────

evaluation_pipeline = SequentialAgent(
    name="EvaluationPipeline",
    sub_agents=[domain_research_agent, eval_research_agent, evaluator_agent],
)

_session_service = InMemorySessionService()

_runner = Runner(
    agent=evaluation_pipeline,
    app_name=_APP_NAME,
    session_service=_session_service,
)


# ── Input packing ──────────────────────────────────────────────────────────────

_MAX_TEXT_CHARS = 2500  # Truncation limit for prompt/output fields to control token cost


def _pack_evaluation_input(evaluation: Evaluation) -> str:
    data = {
        "domain": evaluation.domain,
        "task_description": evaluation.task_description,
        "task_type": evaluation.task_type,
        "focus_areas": evaluation.focus_areas or [],
        "mandatory_metrics": evaluation.mandatory_metrics or [],
        "avoided_metrics": evaluation.avoided_metrics or [],
        "custom_metrics": evaluation.custom_metrics or [],
        "prompt": (evaluation.prompt or "")[:_MAX_TEXT_CHARS],
        "llm_output": (evaluation.llm_output or "")[:_MAX_TEXT_CHARS],
        "context_data": (evaluation.context_data or "")[:_MAX_TEXT_CHARS] if evaluation.context_data else None,
    }
    return json.dumps(data)


# ── Result parsing ─────────────────────────────────────────────────────────────

def _parse_agent_json(raw: Any, field_name: str) -> Any:
    if raw is None:
        logger.warning("Agent state key '%s' is None", field_name)
        return None
    if isinstance(raw, (dict, list)):
        return raw
    if isinstance(raw, str):
        try:
            # Strip markdown code fences if model wrapped output
            cleaned = raw.strip()
            if cleaned.startswith("```"):
                lines = cleaned.split("\n")
                cleaned = "\n".join(lines[1:-1] if lines[-1].strip() == "```" else lines[1:])
            return json.loads(cleaned)
        except json.JSONDecodeError as e:
            logger.error("Failed to parse JSON from state key '%s': %s", field_name, e)
            return None
    return raw


def _build_pipeline_result(evaluation_result: Any, selected_metrics: Any) -> dict:
    if evaluation_result is None:
        raise RuntimeError("EvaluatorAgent produced no output")

    parsed = _parse_agent_json(evaluation_result, "evaluation_result")
    metrics_meta = _parse_agent_json(selected_metrics, "selected_metrics") or {}

    # Validate / normalise via Pydantic
    output = EvaluationOutput.model_validate(parsed)

    # Build scoring guide map from selected_metrics for richer report
    scoring_guides: dict[str, str] = {}
    if isinstance(metrics_meta, dict):
        for m in metrics_meta.get("selected_metrics", []):
            scoring_guides[m.get("metric_name", "")] = m.get("scoring_guide", "")

    metrics_out = []
    for m in output.metrics:
        metrics_out.append({
            "metric_name": m.metric_name,
            "metric_category": m.metric_category,
            "score": m.score,
            "max_score": m.max_score,
            "weight": m.weight,
            "reasoning": m.reasoning,
        })

    return {
        "overall_score": round(output.overall_score, 2),
        "evaluation_report": {
            "summary": output.evaluation_summary,
            "metrics_detail": metrics_out,
            "scoring_guides": scoring_guides,
        },
        "agent_insights": output.agent_insights,
        "metrics": metrics_out,
    }


# ── Public entrypoint ─────────────────────────────────────────────────────────

async def run_evaluation_pipeline(evaluation: Evaluation) -> dict:
    session_id = f"eval_{evaluation.id}"
    user_id = evaluation.user_id

    packed_input = _pack_evaluation_input(evaluation)

    session = await _session_service.create_session(
        app_name=_APP_NAME,
        user_id=user_id,
        session_id=session_id,
        state={"evaluation_input": packed_input},
    )
    logger.info("Starting evaluation pipeline for evaluation %s", evaluation.id)

    trigger = Content(role="user", parts=[Part(text="Begin evaluation pipeline.")])

    async for event in _runner.run_async(
        user_id=user_id,
        session_id=session.id,
        new_message=trigger,
    ):
        if event.is_final_response():
            logger.debug("Pipeline final event received for evaluation %s", evaluation.id)

    final_session = await _session_service.get_session(
        app_name=_APP_NAME,
        user_id=user_id,
        session_id=session.id,
    )

    evaluation_result = final_session.state.get("evaluation_result")
    selected_metrics = final_session.state.get("selected_metrics")
    domain_research = final_session.state.get("domain_research")

    logger.info(
        "Pipeline complete for evaluation %s | domain_research=%s | selected_metrics=%s | result=%s",
        evaluation.id,
        "OK" if domain_research else "MISSING",
        "OK" if selected_metrics else "MISSING",
        "OK" if evaluation_result else "MISSING",
    )

    return _build_pipeline_result(evaluation_result, selected_metrics)


__all__ = ["evaluation_pipeline", "run_evaluation_pipeline"]
