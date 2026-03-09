import logging
import time
import math
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from fastapi import HTTPException, status

from app.models.evaluation import Evaluation, EvaluationStatus
from app.models.evaluation_metric import EvaluationMetric
from app.models.evaluation_version import EvaluationVersion, PerformanceChange
from app.schemas.evaluation import EvaluationCreate, EvaluationCompare
from app.utils.helpers import new_uuid
from app.database.base import async_session_maker

logger = logging.getLogger(__name__)


async def create_evaluation(data: EvaluationCreate, user_id: str, db: AsyncSession) -> Evaluation:
    evaluation = Evaluation(
        id=new_uuid(),
        user_id=user_id,
        domain=data.domain,
        task_description=data.task_description,
        task_type=data.task_type,
        focus_areas=data.focus_areas,
        mandatory_metrics=list(data.mandatory_metrics) if data.mandatory_metrics else [],
        avoided_metrics=list(data.avoided_metrics) if data.avoided_metrics else [],
        custom_metrics=[m.model_dump() for m in data.custom_metrics] if data.custom_metrics else [],
        prompt=data.prompt,
        llm_output=data.llm_output,
        context_data=data.context_data,
        attached_files=data.attached_files or [],
        status=EvaluationStatus.PENDING,
    )
    db.add(evaluation)
    await db.flush()
    logger.info("Evaluation created: %s for user %s", evaluation.id, user_id)
    return evaluation


async def list_evaluations(
    user_id: str,
    db: AsyncSession,
    page: int = 1,
    page_size: int = 20,
    status_filter: str = None,
) -> dict:
    query = select(Evaluation).where(Evaluation.user_id == user_id)
    count_query = select(func.count()).select_from(Evaluation).where(Evaluation.user_id == user_id)

    if status_filter:
        query = query.where(Evaluation.status == status_filter)
        count_query = count_query.where(Evaluation.status == status_filter)

    total = (await db.execute(count_query)).scalar_one()
    total_pages = math.ceil(total / page_size) if page_size else 0

    result = await db.execute(
        query.order_by(Evaluation.created_at.desc()).offset((page - 1) * page_size).limit(page_size)
    )
    items = list(result.scalars().all())
    return {"items": items, "total": total, "page": page, "page_size": page_size, "total_pages": total_pages}


async def get_evaluation(evaluation_id: str, user_id: str, db: AsyncSession) -> Evaluation:
    result = await db.execute(
        select(Evaluation).where(Evaluation.id == evaluation_id, Evaluation.user_id == user_id)
    )
    evaluation = result.scalar_one_or_none()
    if not evaluation:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Evaluation not found")
    return evaluation


async def get_evaluation_with_metrics(evaluation_id: str, user_id: str, db: AsyncSession) -> dict:
    evaluation = await get_evaluation(evaluation_id, user_id, db)

    metrics_result = await db.execute(
        select(EvaluationMetric).where(EvaluationMetric.evaluation_id == evaluation_id)
    )
    metrics = list(metrics_result.scalars().all())

    eval_dict = {c.name: getattr(evaluation, c.name) for c in evaluation.__table__.columns}
    eval_dict["metrics"] = metrics
    return eval_dict


async def delete_evaluation(evaluation_id: str, user_id: str, db: AsyncSession) -> None:
    evaluation = await get_evaluation(evaluation_id, user_id, db)
    await db.delete(evaluation)
    await db.flush()
    logger.info("Evaluation deleted: %s", evaluation_id)


async def retry_evaluation(evaluation_id: str, user_id: str, db: AsyncSession) -> Evaluation:
    evaluation = await get_evaluation(evaluation_id, user_id, db)

    if evaluation.status != EvaluationStatus.FAILED:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Only failed evaluations can be retried")
    if evaluation.retry_count >= 3:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Maximum retry limit (3) reached")

    evaluation.status = EvaluationStatus.PENDING
    evaluation.error_message = None
    db.add(evaluation)
    await db.flush()
    logger.info("Evaluation %s queued for retry #%d", evaluation_id, evaluation.retry_count + 1)
    return evaluation


# ── Background task: run evaluation pipeline ──────────────────────────────────

async def process_evaluation(evaluation_id: str) -> None:
    async with async_session_maker() as db:
        try:
            result = await db.execute(select(Evaluation).where(Evaluation.id == evaluation_id))
            evaluation = result.scalar_one_or_none()
            if not evaluation:
                logger.error("Background task: evaluation %s not found", evaluation_id)
                return

            evaluation.status = EvaluationStatus.PROCESSING
            evaluation.retry_count += 1
            db.add(evaluation)
            await db.commit()

            # TODO: Wire ADK agent pipeline here in agents phase
            # from app.agents.orchestrator import run_evaluation_pipeline
            # pipeline_result = await run_evaluation_pipeline(evaluation)
            # await _save_evaluation_results(evaluation, pipeline_result, db)
            raise NotImplementedError("Agent pipeline not yet wired")

        except NotImplementedError:
            result = await db.execute(select(Evaluation).where(Evaluation.id == evaluation_id))
            evaluation = result.scalar_one_or_none()
            if evaluation:
                evaluation.status = EvaluationStatus.FAILED
                evaluation.error_message = "Agent pipeline not yet implemented"
                db.add(evaluation)
                await db.commit()
        except Exception as exc:
            logger.error("Evaluation processing failed for %s: %s", evaluation_id, exc, exc_info=True)
            async with async_session_maker() as err_db:
                err_result = await err_db.execute(select(Evaluation).where(Evaluation.id == evaluation_id))
                evaluation = err_result.scalar_one_or_none()
                if evaluation:
                    evaluation.status = EvaluationStatus.FAILED
                    evaluation.error_message = str(exc)
                    err_db.add(evaluation)
                    await err_db.commit()


async def _save_evaluation_results(
    evaluation: Evaluation,
    pipeline_result: dict,
    db: AsyncSession,
) -> None:
    evaluation.overall_score = pipeline_result.get("overall_score")
    evaluation.evaluation_report = pipeline_result.get("evaluation_report")
    evaluation.agent_insights = pipeline_result.get("agent_insights")
    evaluation.status = EvaluationStatus.COMPLETED
    db.add(evaluation)

    for metric_data in pipeline_result.get("metrics", []):
        metric = EvaluationMetric(
            id=new_uuid(),
            evaluation_id=evaluation.id,
            metric_name=metric_data["metric_name"],
            metric_category=metric_data.get("metric_category"),
            score=metric_data["score"],
            max_score=metric_data.get("max_score", 100),
            weight=metric_data.get("weight"),
            reasoning=metric_data.get("reasoning"),
        )
        db.add(metric)

    await db.flush()


# ── Background task: run comparison pipeline ──────────────────────────────────

async def process_comparison(
    base_evaluation_id: str,
    new_evaluation_id: str,
    version_id: str,
) -> None:
    async with async_session_maker() as db:
        try:
            # TODO: Wire EvalCompareAgent here in agents phase
            raise NotImplementedError("Comparison agent not yet wired")
        except NotImplementedError:
            logger.warning("Comparison %s: agent not yet implemented", version_id)
        except Exception as exc:
            logger.error("Comparison processing failed for version %s: %s", version_id, exc, exc_info=True)


async def create_comparison(
    data: EvaluationCompare,
    user_id: str,
    db: AsyncSession,
) -> EvaluationVersion:
    base_result = await db.execute(
        select(Evaluation).where(Evaluation.id == data.base_evaluation_id, Evaluation.user_id == user_id)
    )
    base_eval = base_result.scalar_one_or_none()
    if not base_eval:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Base evaluation not found")

    new_result = await db.execute(
        select(Evaluation).where(Evaluation.id == data.new_evaluation_id, Evaluation.user_id == user_id)
    )
    new_eval = new_result.scalar_one_or_none()
    if not new_eval:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="New evaluation not found")

    for ev in [base_eval, new_eval]:
        if ev.status != EvaluationStatus.COMPLETED:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Evaluation {ev.id} is not completed yet",
            )

    score_diff = None
    perf_change = None
    if base_eval.overall_score is not None and new_eval.overall_score is not None:
        score_diff = float(new_eval.overall_score) - float(base_eval.overall_score)
        if score_diff > 1:
            perf_change = PerformanceChange.BETTER
        elif score_diff < -1:
            perf_change = PerformanceChange.WORSE
        else:
            perf_change = PerformanceChange.SIMILAR

    version = EvaluationVersion(
        id=new_uuid(),
        base_evaluation_id=data.base_evaluation_id,
        new_evaluation_id=data.new_evaluation_id,
        score_difference=score_diff,
        performance_change=perf_change,
    )
    db.add(version)
    await db.flush()
    logger.info("Comparison version created: %s", version.id)
    return version


async def get_evaluation_versions(evaluation_id: str, user_id: str, db: AsyncSession) -> list:
    eval_result = await db.execute(
        select(Evaluation).where(Evaluation.id == evaluation_id, Evaluation.user_id == user_id)
    )
    if not eval_result.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Evaluation not found")

    result = await db.execute(
        select(EvaluationVersion).where(
            (EvaluationVersion.base_evaluation_id == evaluation_id)
            | (EvaluationVersion.new_evaluation_id == evaluation_id)
        )
    )
    return list(result.scalars().all())
