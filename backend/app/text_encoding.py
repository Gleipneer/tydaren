"""
Återställer text där UTF-8 felaktigt tolkats som latin-1 (klassisk mojibake: Ã¤, Ã¶).
Vanligt om äldre klienter skickat UTF-8 med fel teckenuppsättning mot MySQL.
"""


def repair_mojibake_utf8(value: str | None) -> str | None:
    if value is None or not isinstance(value, str) or not value:
        return value
    try:
        repaired = value.encode("latin-1").decode("utf-8")
    except (UnicodeEncodeError, UnicodeDecodeError):
        return value
    if repaired == value:
        return value
    return repaired
