import logging
import os
from daef.agents.orchestrator import run_evaluation_pipeline
from daef.agents.eval_compare import run_comparison_pipeline
from daef.schemas import EvaluationRequest, EvaluationResult, MetricScore, ComparisonResult
from daef.utils import new_uuid

logger = logging.getLogger(__name__)


class DAEFClient:
    def __init__(self, api_key: str | None = None) -> None:
        if api_key:
            os.environ["GOOGLE_API_KEY"] = api_key

        if not os.getenv("GOOGLE_API_KEY"):
            raise ValueError(
                "GOOGLE_API_KEY is required. Pass api_key= or set the GOOGLE_API_KEY environment variable."
            )

    async def evaluate(self, request: EvaluationRequest) -> EvaluationResult:
        raw = await run_evaluation_pipeline(request)
        return EvaluationResult(
            overall_score=raw["overall_score"],
            summary=raw["summary"],
            metrics=[MetricScore(**m) for m in raw["metrics"]],
            agent_insights=raw["agent_insights"],
            scoring_guides=raw.get("scoring_guides", {}),
        )

    async def compare(
        self,
        base_result: EvaluationResult,
        new_result: EvaluationResult,
    ) -> ComparisonResult:
        raw = await run_comparison_pipeline(
            base_evaluation=base_result.model_dump(),
            new_evaluation=new_result.model_dump(),
            session_id=f"compare_{new_uuid()}",
        )
        return ComparisonResult(**raw)


__all__ = ["DAEFClient"]
