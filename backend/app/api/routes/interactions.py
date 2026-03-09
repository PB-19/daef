from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.session import get_db
from app.schemas.social import CommentCreate, CommentResponse, LikeResponse
from app.schemas.common import PaginatedResponse, SuccessResponse
from app.services import social_service, notification_service
from app.api.deps import get_current_user
from app.models.user import User
from app.models.notification import NotificationType
from app.models.social_post import SocialPost
from sqlalchemy import select

router = APIRouter(prefix="/interactions", tags=["Interactions"])


@router.post("/posts/{post_id}/like", response_model=LikeResponse, status_code=status.HTTP_201_CREATED)
async def like_post(
    post_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    like = await social_service.like_post(post_id, current_user.id, db)

    # Notify post owner (skip if liking own post)
    post_result = await db.execute(select(SocialPost).where(SocialPost.id == post_id))
    post = post_result.scalar_one_or_none()
    if post and post.user_id != current_user.id:
        await notification_service.create_notification(
            db=db,
            user_id=post.user_id,
            type=NotificationType.LIKE,
            title="Someone liked your post",
            message=f"{current_user.username} liked your post",
            related_post_id=post_id,
            related_user_id=current_user.id,
        )

    return like


@router.delete("/posts/{post_id}/like", response_model=SuccessResponse)
async def unlike_post(
    post_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await social_service.unlike_post(post_id, current_user.id, db)
    return SuccessResponse(message="Post unliked")


@router.post("/posts/{post_id}/comments", response_model=CommentResponse, status_code=status.HTTP_201_CREATED)
async def create_comment(
    post_id: str,
    comment_data: CommentCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    comment = await social_service.create_comment(post_id, comment_data, current_user.id, db)

    post_result = await db.execute(select(SocialPost).where(SocialPost.id == post_id))
    post = post_result.scalar_one_or_none()
    if post and post.user_id != current_user.id:
        await notification_service.create_notification(
            db=db,
            user_id=post.user_id,
            type=NotificationType.COMMENT,
            title="New comment on your post",
            message=f"{current_user.username} commented: {comment_data.content[:80]}",
            related_post_id=post_id,
            related_user_id=current_user.id,
        )

    return comment


@router.get("/posts/{post_id}/comments", response_model=PaginatedResponse[CommentResponse])
async def get_comments(
    post_id: str,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    return await social_service.get_comments(post_id, page, page_size, db)


@router.delete("/comments/{comment_id}", response_model=SuccessResponse)
async def delete_comment(
    comment_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await social_service.delete_comment(comment_id, current_user.id, db)
    return SuccessResponse(message="Comment deleted")
