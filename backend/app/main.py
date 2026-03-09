import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from sqlalchemy.exc import IntegrityError

from app.core.config import settings
from app.core.logging import setup_logging
from app.database.init_db import init_db, close_db
from app.api.routes import api_router
from app.api.error_handlers import (
    validation_exception_handler,
    integrity_error_handler,
    general_exception_handler,
)

setup_logging(log_level="DEBUG" if settings.DEBUG else "INFO")
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting DAEF API...")
    await init_db()
    yield
    logger.info("Shutting down DAEF API...")
    await close_db()


app = FastAPI(
    title="DAEF API",
    description="Domain-Aware Evaluation Framework",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(IntegrityError, integrity_error_handler)
app.add_exception_handler(Exception, general_exception_handler)

app.include_router(api_router, prefix="/api/v1")


@app.get("/")
async def root():
    return {"message": "DAEF API", "version": "1.0.0", "docs": "/docs"}
