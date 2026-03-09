from fastapi import APIRouter, Depends, BackgroundTasks, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.session import get_db
from app.schemas.evaluation import EvaluationCompare, VersionComparisonResponse
from app.services import evaluation_service
from app.api.deps import get_current_user
from app.models.user import User

router = APIRouter(prefix="/comparisons", tags=["Comparisons"])


@router.post("", response_model=VersionComparisonResponse, status_code=status.HTTP_201_CREATED)
async def compare_evaluations(
    comparison_data: EvaluationCompare,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    version = await evaluation_service.create_comparison(comparison_data, current_user.id, db)
    background_tasks.add_task(
        evaluation_service.process_comparison,
        comparison_data.base_evaluation_id,
        comparison_data.new_evaluation_id,
        version.id,
        current_user.id,
    )
    return version


@router.get("/evaluation/{evaluation_id}", response_model=list[VersionComparisonResponse])
async def get_evaluation_versions(
    evaluation_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await evaluation_service.get_evaluation_versions(evaluation_id, current_user.id, db)
