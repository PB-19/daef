from pydantic import BaseModel, Field, ConfigDict
from typing import Optional
from datetime import datetime


class SocialPostCreate(BaseModel):
    evaluation_id: str
    title: Optional[str] = Field(None, max_length=200)
    description: Optional[str] = None


class CommentCreate(BaseModel):
    content: str = Field(..., min_length=1)


class SocialPostResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    evaluation_id: str
    user_id: str
    username: str

    title: Optional[str]
    description: Optional[str]

    overall_score: Optional[float]
    domain: Optional[str]
    task_type: Optional[str]

    likes_count: int
    comments_count: int
    is_liked_by_current_user: bool = False

    created_at: datetime


class CommentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    post_id: str
    user_id: str
    username: str
    content: str
    created_at: datetime


class LikeResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    post_id: str
    user_id: str
    created_at: datetime
