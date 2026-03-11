from fastapi import APIRouter, Depends, BackgroundTasks, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional

from app.database.session import get_db
from app.schemas.evaluation import EvaluationCreate, EvaluationResponse, EvaluationDetailResponse
from app.schemas.common import PaginatedResponse, SuccessResponse
from app.services import evaluation_service
from app.api.deps import get_current_user
from app.models.user import User

router = APIRouter(prefix="/evaluations", tags=["Evaluations"])


@router.post("", response_model=EvaluationResponse, status_code=status.HTTP_201_CREATED)
async def create_evaluation(
    eval_data: EvaluationCreate,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    evaluation = await evaluation_service.create_evaluation(eval_data, current_user.id, db)
    background_tasks.add_task(evaluation_service.process_evaluation, evaluation.id)
    return evaluation


@router.get("", response_model=PaginatedResponse[EvaluationResponse])
async def list_evaluations(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    status: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await evaluation_service.list_evaluations(current_user.id, db, page, page_size, status)


@router.get("/{evaluation_id}/public", response_model=EvaluationDetailResponse)
async def get_public_evaluation(
    evaluation_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await evaluation_service.get_public_evaluation_with_metrics(evaluation_id, db)


@router.get("/{evaluation_id}", response_model=EvaluationDetailResponse)
async def get_evaluation(
    evaluation_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await evaluation_service.get_evaluation_with_metrics(evaluation_id, current_user.id, db)


@router.delete("/{evaluation_id}", response_model=SuccessResponse)
async def delete_evaluation(
    evaluation_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await evaluation_service.delete_evaluation(evaluation_id, current_user.id, db)
    return SuccessResponse(message="Evaluation deleted")


@router.post("/{evaluation_id}/retry", response_model=EvaluationResponse)
async def retry_evaluation(
    evaluation_id: str,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    evaluation = await evaluation_service.retry_evaluation(evaluation_id, current_user.id, db)
    background_tasks.add_task(evaluation_service.process_evaluation, evaluation.id)
    return evaluation
