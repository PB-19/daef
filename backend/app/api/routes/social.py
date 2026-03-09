from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.database.session import get_db
from app.schemas.social import SocialPostCreate, SocialPostResponse
from app.schemas.common import PaginatedResponse, SuccessResponse
from app.services import social_service
from app.api.deps import get_current_user
from app.models.user import User

router = APIRouter(prefix="/social", tags=["Social"])


@router.post("/posts", response_model=SocialPostResponse, status_code=status.HTTP_201_CREATED)
async def create_post(
    post_data: SocialPostCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await social_service.create_post(post_data, current_user.id, db)


@router.get("/posts/feed", response_model=PaginatedResponse[SocialPostResponse])
async def get_feed(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await social_service.get_feed(page, page_size, current_user.id, db)


@router.get("/posts/top-score", response_model=List[SocialPostResponse])
async def get_top_by_score(
    limit: int = Query(10, ge=1, le=50),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await social_service.get_top_by_score(limit, current_user.id, db)


@router.get("/posts/top-liked", response_model=List[SocialPostResponse])
async def get_top_by_likes(
    limit: int = Query(10, ge=1, le=50),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await social_service.get_top_by_likes(limit, current_user.id, db)


@router.get("/posts/top-commented", response_model=List[SocialPostResponse])
async def get_top_by_comments(
    limit: int = Query(10, ge=1, le=50),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await social_service.get_top_by_comments(limit, current_user.id, db)


@router.get("/posts/user/{user_id}", response_model=PaginatedResponse[SocialPostResponse])
async def get_user_posts(
    user_id: str,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await social_service.get_user_posts(user_id, page, page_size, current_user.id, db)


@router.get("/posts/{post_id}", response_model=SocialPostResponse)
async def get_post(
    post_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await social_service.get_post(post_id, current_user.id, db)


@router.delete("/posts/{post_id}", response_model=SuccessResponse)
async def delete_post(
    post_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await social_service.delete_post(post_id, current_user.id, db)
    return SuccessResponse(message="Post deleted")
