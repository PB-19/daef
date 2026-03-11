import json
import logging
from google.adk.agents import SequentialAgent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai.types import Content, Part

from daef.agents.domain_research import domain_research_agent
from daef.agents.eval_research import eval_research_agent
from daef.agents.evaluator import evaluator_agent, _EvaluationOutput
from daef.schemas import EvaluationRequest
from daef.utils import new_uuid, parse_agent_json

logger = logging.getLogger(__name__)

_APP_NAME = "daef_eval"
_MAX_TEXT_CHARS = 2500

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


def _pack_input(request: EvaluationRequest) -> str:
    return json.dumps({
        "domain": request.domain,
        "task_description": request.task_description,
        "task_type": request.task_type,
        "focus_areas": request.focus_areas,
        "mandatory_metrics": request.mandatory_metrics,
        "avoided_metrics": request.avoided_metrics,
        "custom_metrics": request.custom_metrics,
        "prompt": request.prompt[:_MAX_TEXT_CHARS],
        "llm_output": request.llm_output[:_MAX_TEXT_CHARS],
        "context_data": request.context_data[:_MAX_TEXT_CHARS] if request.context_data else None,
    })


def _build_result(evaluation_result, selected_metrics) -> dict:
    if evaluation_result is None:
        raise RuntimeError("EvaluatorAgent produced no output")

    parsed = parse_agent_json(evaluation_result, "evaluation_result")
    metrics_meta = parse_agent_json(selected_metrics, "selected_metrics") or {}

    output = _EvaluationOutput.model_validate(parsed)

    scoring_guides: dict[str, str] = {}
    if isinstance(metrics_meta, dict):
        for m in metrics_meta.get("selected_metrics", []):
            scoring_guides[m.get("metric_name", "")] = m.get("scoring_guide", "")

    metrics_out = [
        {
            "metric_name": m.metric_name,
            "metric_category": m.metric_category,
            "score": m.score,
            "max_score": m.max_score,
            "weight": m.weight,
            "reasoning": m.reasoning,
        }
        for m in output.metrics
    ]

    return {
        "overall_score": round(output.overall_score, 2),
        "summary": output.evaluation_summary,
        "metrics": metrics_out,
        "agent_insights": output.agent_insights,
        "scoring_guides": scoring_guides,
    }


async def run_evaluation_pipeline(request: EvaluationRequest) -> dict:
    session_id = f"eval_{new_uuid()}"
    user_id = "daef_package"

    session = await _session_service.create_session(
        app_name=_APP_NAME,
        user_id=user_id,
        session_id=session_id,
        state={"evaluation_input": _pack_input(request)},
    )
    logger.info("Starting evaluation pipeline | domain=%s task_type=%s", request.domain, request.task_type)

    trigger = Content(role="user", parts=[Part(text="Begin evaluation pipeline.")])

    async for event in _runner.run_async(
        user_id=user_id,
        session_id=session.id,
        new_message=trigger,
    ):
        if event.is_final_response():
            logger.debug("Pipeline final event received")

    final_session = await _session_service.get_session(
        app_name=_APP_NAME,
        user_id=user_id,
        session_id=session.id,
    )

    evaluation_result = final_session.state.get("evaluation_result")
    selected_metrics = final_session.state.get("selected_metrics")
    domain_research = final_session.state.get("domain_research")

    logger.info(
        "Pipeline complete | domain_research=%s selected_metrics=%s result=%s",
        "OK" if domain_research else "MISSING",
        "OK" if selected_metrics else "MISSING",
        "OK" if evaluation_result else "MISSING",
    )

    return _build_result(evaluation_result, selected_metrics)


__all__ = ["run_evaluation_pipeline", "evaluation_pipeline"]
