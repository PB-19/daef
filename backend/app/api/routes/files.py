from fastapi import APIRouter, Depends, UploadFile, File, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.session import get_db
from app.services import storage_service
from app.api.deps import get_current_user
from app.models.user import User

router = APIRouter(prefix="/files", tags=["Files"])


@router.post("/upload")
async def upload_file(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    gcs_path = await storage_service.upload_file(file, current_user.id)
    return {"file_path": gcs_path}


@router.delete("")
async def delete_file(
    file_path: str = Query(...),
    current_user: User = Depends(get_current_user),
):
    await storage_service.delete_file(file_path, current_user.id)
    return {"success": True, "message": "File deleted"}
