import logging
from google.cloud import storage
from fastapi import HTTPException, status, UploadFile

from app.core.config import settings

logger = logging.getLogger(__name__)

ALLOWED_CONTENT_TYPES = {"application/pdf", "text/plain"}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB


def _get_client() -> storage.Client:
    return storage.Client(project=settings.GOOGLE_CLOUD_PROJECT)


async def upload_file(file: UploadFile, user_id: str) -> str:
    if file.content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only PDF and TXT files are allowed",
        )

    content = await file.read()
    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="File exceeds 10 MB limit",
        )

    client = _get_client()
    bucket = client.bucket(settings.GCS_BUCKET_NAME)
    blob_name = f"{user_id}/{file.filename}"
    blob = bucket.blob(blob_name)
    blob.upload_from_string(content, content_type=file.content_type)

    gcs_path = f"gs://{settings.GCS_BUCKET_NAME}/{blob_name}"
    logger.info("File uploaded to GCS: %s", gcs_path)
    return gcs_path


async def delete_file(gcs_path: str, user_id: str) -> None:
    if not gcs_path.startswith(f"gs://{settings.GCS_BUCKET_NAME}/{user_id}/"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not own this file",
        )

    blob_name = gcs_path.replace(f"gs://{settings.GCS_BUCKET_NAME}/", "")
    client = _get_client()
    bucket = client.bucket(settings.GCS_BUCKET_NAME)
    blob = bucket.blob(blob_name)

    if not blob.exists():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="File not found")

    blob.delete()
    logger.info("File deleted from GCS: %s", gcs_path)
