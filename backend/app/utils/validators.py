import re


def is_valid_uuid(value: str) -> bool:
    pattern = re.compile(
        r"^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$",
        re.IGNORECASE,
    )
    return bool(pattern.match(value))


def is_valid_gcs_path(path: str) -> bool:
    return path.startswith("gs://")
