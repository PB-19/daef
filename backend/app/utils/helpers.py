import uuid
import math
from typing import TypeVar, List

T = TypeVar("T")


def new_uuid() -> str:
    return str(uuid.uuid4())


def paginate(items: List[T], page: int, page_size: int) -> dict:
    total = len(items)
    total_pages = math.ceil(total / page_size) if page_size else 0
    start = (page - 1) * page_size
    end = start + page_size
    return {
        "items": items[start:end],
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": total_pages,
    }
