import json
import logging
import uuid
from typing import Any

logger = logging.getLogger(__name__)


def new_uuid() -> str:
    return str(uuid.uuid4())


def parse_agent_json(raw: Any, field_name: str) -> Any:
    if raw is None:
        logger.warning("Agent state key '%s' is None", field_name)
        return None
    if isinstance(raw, (dict, list)):
        return raw
    if isinstance(raw, str):
        try:
            cleaned = raw.strip()
            if cleaned.startswith("```"):
                lines = cleaned.split("\n")
                cleaned = "\n".join(lines[1:-1] if lines[-1].strip() == "```" else lines[1:])
            return json.loads(cleaned)
        except json.JSONDecodeError as e:
            logger.error("Failed to parse JSON from state key '%s': %s", field_name, e)
            return None
    return raw


__all__ = ["new_uuid", "parse_agent_json"]
