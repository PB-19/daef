"""
Seeds evaluations and social posts for dummy users.
Run AFTER create_dummy_users.py:
    python -m scripts.seed_data
"""
import asyncio
import sys
import os
import random
import logging

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())

from decimal import Decimal
from sqlalchemy import select

from app.core.logging import setup_logging
from app.database.base import async_session_maker
from app.database.init_db import init_db
from app.models.user import User
from app.models.evaluation import Evaluation, EvaluationStatus, TaskType
from app.models.evaluation_metric import EvaluationMetric
from app.models.social_post import SocialPost
from app.utils.helpers import new_uuid

setup_logging()
logger = logging.getLogger(__name__)

DOMAINS = ["Healthcare", "Legal", "Finance", "Education", "E-commerce"]
TASK_TYPES = [TaskType.RAG, TaskType.TUNING, TaskType.SINGLE_CALL]
FOCUS_AREAS = [
    ["Security and Guardrails", "Legal and Regulatory Compliance"],
    ["Content Generation Quality", "User Experience"],
    ["Performance, Cost and Operations", "Data and Dataset Related"],
]

SAMPLE_METRICS = [
    {"metric_name": "Faithfulness", "metric_category": "RAG Quality", "score": 78.5, "weight": 0.30},
    {"metric_name": "Answer Relevancy", "metric_category": "RAG Quality", "score": 85.0, "weight": 0.25},
    {"metric_name": "Context Precision", "metric_category": "RAG Quality", "score": 72.0, "weight": 0.20},
    {"metric_name": "Hallucination Rate", "metric_category": "Safety", "score": 91.0, "weight": 0.25},
]


async def seed() -> None:
    await init_db()

    async with async_session_maker() as db:
        result = await db.execute(select(User))
        users = result.scalars().all()

        if not users:
            logger.error("No users found — run create_dummy_users.py first")
            return

        for user in users:
            for i in range(3):
                eval_id = new_uuid()
                score = Decimal(str(round(random.uniform(60, 95), 2)))

                evaluation = Evaluation(
                    id=eval_id,
                    user_id=user.id,
                    domain=random.choice(DOMAINS),
                    task_description=f"Sample evaluation {i+1} for {user.username}",
                    task_type=random.choice(TASK_TYPES),
                    focus_areas=random.choice(FOCUS_AREAS),
                    mandatory_metrics=[],
                    avoided_metrics=[],
                    custom_metrics=[],
                    prompt="What are the latest treatments for diabetes?",
                    llm_output="Recent advances include GLP-1 receptor agonists and SGLT2 inhibitors...",
                    overall_score=score,
                    evaluation_report={"summary": "Good overall performance"},
                    agent_insights="Strong factual accuracy, minor hallucinations detected.",
                    status=EvaluationStatus.COMPLETED,
                    processing_time_seconds=random.randint(15, 45),
                )
                db.add(evaluation)

                for m in SAMPLE_METRICS:
                    metric = EvaluationMetric(
                        id=new_uuid(),
                        evaluation_id=eval_id,
                        reasoning="Based on analysis of the response content.",
                        max_score=100,
                        **m,
                    )
                    db.add(metric)

                if i == 0:
                    post = SocialPost(
                        id=new_uuid(),
                        evaluation_id=eval_id,
                        user_id=user.id,
                        title=f"{user.username}'s evaluation showcase",
                        description="Sharing my domain-aware evaluation result!",
                        overall_score=score,
                        domain=evaluation.domain,
                        task_type=evaluation.task_type,
                    )
                    db.add(post)

            logger.info("Seeded 3 evaluations + 1 post for %s", user.username)

        await db.commit()
    logger.info("Seed data created successfully")


if __name__ == "__main__":
    asyncio.run(seed())
