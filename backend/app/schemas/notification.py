from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime


class NotificationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    type: str
    title: str
    message: str

    related_evaluation_id: Optional[str]
    related_post_id: Optional[str]
    related_user_id: Optional[str]

    is_read: bool
    created_at: datetime
