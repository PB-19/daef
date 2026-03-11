import logging
import math
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from fastapi import HTTPException, status

from app.models.social_post import SocialPost
from app.models.like import Like
from app.models.comment import Comment
from app.models.evaluation import Evaluation, EvaluationStatus
from app.models.user import User
from app.schemas.social import SocialPostCreate, CommentCreate
from app.utils.helpers import new_uuid

logger = logging.getLogger(__name__)


async def create_post(data: SocialPostCreate, user_id: str, db: AsyncSession) -> dict:
    result = await db.execute(
        select(Evaluation).where(Evaluation.id == data.evaluation_id, Evaluation.user_id == user_id)
    )
    evaluation = result.scalar_one_or_none()
    if not evaluation:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Evaluation not found")
    if evaluation.status != EvaluationStatus.COMPLETED:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Only completed evaluations can be posted")

    existing = await db.execute(select(SocialPost).where(SocialPost.evaluation_id == data.evaluation_id))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Evaluation already shared")

    post = SocialPost(
        id=new_uuid(),
        evaluation_id=data.evaluation_id,
        user_id=user_id,
        title=data.title,
        description=data.description,
        overall_score=evaluation.overall_score,
        domain=evaluation.domain,
        task_type=evaluation.task_type,
    )
    db.add(post)
    await db.flush()
    await db.refresh(post)
    logger.info("Social post created: %s", post.id)
    return await _enrich_post(post, user_id, db)


async def _enrich_post(post: SocialPost, current_user_id: str, db: AsyncSession) -> dict:
    user_result = await db.execute(select(User.username).where(User.id == post.user_id))
    username = user_result.scalar_one_or_none() or ""

    liked_result = await db.execute(
        select(Like).where(Like.post_id == post.id, Like.user_id == current_user_id)
    )
    is_liked = liked_result.scalar_one_or_none() is not None

    data = {c.name: getattr(post, c.name) for c in post.__table__.columns}
    data["username"] = username
    data["is_liked_by_current_user"] = is_liked
    return data


async def get_feed(page: int, page_size: int, current_user_id: str, db: AsyncSession) -> dict:
    count_result = await db.execute(select(func.count()).select_from(SocialPost))
    total = count_result.scalar_one()
    total_pages = math.ceil(total / page_size) if page_size else 0

    result = await db.execute(
        select(SocialPost)
        .order_by(SocialPost.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    posts = result.scalars().all()
    items = [await _enrich_post(p, current_user_id, db) for p in posts]
    return {"items": items, "total": total, "page": page, "page_size": page_size, "total_pages": total_pages}


async def get_top_by_score(limit: int, current_user_id: str, db: AsyncSession) -> list:
    result = await db.execute(
        select(SocialPost).order_by(SocialPost.overall_score.desc()).limit(limit)
    )
    return [await _enrich_post(p, current_user_id, db) for p in result.scalars().all()]


async def get_top_by_likes(limit: int, current_user_id: str, db: AsyncSession) -> list:
    result = await db.execute(
        select(SocialPost).order_by(SocialPost.likes_count.desc()).limit(limit)
    )
    return [await _enrich_post(p, current_user_id, db) for p in result.scalars().all()]


async def get_top_by_comments(limit: int, current_user_id: str, db: AsyncSession) -> list:
    result = await db.execute(
        select(SocialPost).order_by(SocialPost.comments_count.desc()).limit(limit)
    )
    return [await _enrich_post(p, current_user_id, db) for p in result.scalars().all()]


async def get_post(post_id: str, current_user_id: str, db: AsyncSession) -> dict:
    result = await db.execute(select(SocialPost).where(SocialPost.id == post_id))
    post = result.scalar_one_or_none()
    if not post:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Post not found")
    return await _enrich_post(post, current_user_id, db)


async def delete_post(post_id: str, user_id: str, db: AsyncSession) -> None:
    result = await db.execute(select(SocialPost).where(SocialPost.id == post_id))
    post = result.scalar_one_or_none()
    if not post:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Post not found")
    if post.user_id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your post")
    await db.delete(post)
    await db.flush()
    logger.info("Post deleted: %s", post_id)


async def get_user_posts(target_user_id: str, page: int, page_size: int, current_user_id: str, db: AsyncSession) -> dict:
    count_result = await db.execute(
        select(func.count()).select_from(SocialPost).where(SocialPost.user_id == target_user_id)
    )
    total = count_result.scalar_one()
    total_pages = math.ceil(total / page_size) if page_size else 0

    result = await db.execute(
        select(SocialPost)
        .where(SocialPost.user_id == target_user_id)
        .order_by(SocialPost.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    items = [await _enrich_post(p, current_user_id, db) for p in result.scalars().all()]
    return {"items": items, "total": total, "page": page, "page_size": page_size, "total_pages": total_pages}


# ── Likes ──────────────────────────────────────────────────────────────────────

async def like_post(post_id: str, user_id: str, db: AsyncSession) -> Like:
    post_result = await db.execute(select(SocialPost).where(SocialPost.id == post_id))
    post = post_result.scalar_one_or_none()
    if not post:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Post not found")

    existing = await db.execute(select(Like).where(Like.post_id == post_id, Like.user_id == user_id))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Already liked")

    like = Like(id=new_uuid(), post_id=post_id, user_id=user_id)
    db.add(like)
    post.likes_count += 1
    db.add(post)
    await db.flush()
    await db.refresh(like)
    logger.debug("Post %s liked by %s", post_id, user_id)
    return like


async def unlike_post(post_id: str, user_id: str, db: AsyncSession) -> None:
    result = await db.execute(select(Like).where(Like.post_id == post_id, Like.user_id == user_id))
    like = result.scalar_one_or_none()
    if not like:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Like not found")

    post_result = await db.execute(select(SocialPost).where(SocialPost.id == post_id))
    post = post_result.scalar_one_or_none()
    if post and post.likes_count > 0:
        post.likes_count -= 1
        db.add(post)

    await db.delete(like)
    await db.flush()
    logger.debug("Post %s unliked by %s", post_id, user_id)


# ── Comments ───────────────────────────────────────────────────────────────────

async def create_comment(post_id: str, data: CommentCreate, user_id: str, db: AsyncSession) -> dict:
    post_result = await db.execute(select(SocialPost).where(SocialPost.id == post_id))
    post = post_result.scalar_one_or_none()
    if not post:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Post not found")

    comment = Comment(id=new_uuid(), post_id=post_id, user_id=user_id, content=data.content)
    db.add(comment)
    post.comments_count += 1
    db.add(post)
    await db.flush()
    await db.refresh(comment)

    user_result = await db.execute(select(User.username).where(User.id == user_id))
    username = user_result.scalar_one_or_none() or ""

    result = {c.name: getattr(comment, c.name) for c in comment.__table__.columns}
    result["username"] = username
    logger.debug("Comment added to post %s by %s", post_id, user_id)
    return result


async def get_comments(post_id: str, page: int, page_size: int, db: AsyncSession) -> dict:
    count_result = await db.execute(
        select(func.count()).select_from(Comment).where(Comment.post_id == post_id)
    )
    total = count_result.scalar_one()
    total_pages = math.ceil(total / page_size) if page_size else 0

    result = await db.execute(
        select(Comment)
        .where(Comment.post_id == post_id)
        .order_by(Comment.created_at.asc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    comments = result.scalars().all()

    items = []
    for c in comments:
        user_result = await db.execute(select(User.username).where(User.id == c.user_id))
        username = user_result.scalar_one_or_none() or ""
        item = {col.name: getattr(c, col.name) for col in c.__table__.columns}
        item["username"] = username
        items.append(item)

    return {"items": items, "total": total, "page": page, "page_size": page_size, "total_pages": total_pages}


async def delete_comment(comment_id: str, user_id: str, db: AsyncSession) -> None:
    result = await db.execute(select(Comment).where(Comment.id == comment_id))
    comment = result.scalar_one_or_none()
    if not comment:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Comment not found")
    if comment.user_id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your comment")

    post_result = await db.execute(select(SocialPost).where(SocialPost.id == comment.post_id))
    post = post_result.scalar_one_or_none()
    if post and post.comments_count > 0:
        post.comments_count -= 1
        db.add(post)

    await db.delete(comment)
    await db.flush()
    logger.debug("Comment %s deleted by %s", comment_id, user_id)
