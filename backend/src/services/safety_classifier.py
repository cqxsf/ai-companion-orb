"""
Safety classifier — detects self-harm signals in Chinese text.

Called AFTER LLM output, BEFORE sending to device (per CLAUDE.md §三 and §十二).
"""

from __future__ import annotations

import re

# ---------------------------------------------------------------------------
# Keyword / phrase lists — ordered roughly by severity
# ---------------------------------------------------------------------------
_CRITICAL_PATTERNS: list[str] = [
    r"自杀",
    r"去死",
    r"不想活",
    r"了结.*生命",
    r"结束.*生命",
    r"轻生",
    r"跳楼",
    r"上吊",
    r"割腕",
    r"服药.*死",
    r"死了算了",
    r"活着.*没意思",
    r"活不下去",
    r"不如死",
]

_HIGH_PATTERNS: list[str] = [
    r"好累.*不想撑",
    r"撑不下去",
    r"消失",
    r"离开这个世界",
    r"没人在乎",
    r"没人需要我",
    r"活着.*有什么用",
]

_COMPILED_CRITICAL = [re.compile(p) for p in _CRITICAL_PATTERNS]
_COMPILED_HIGH = [re.compile(p) for p in _HIGH_PATTERNS]


class SafetyClassifier:
    """Keyword + regex based safety classifier for Chinese text."""

    async def check(self, text: str) -> dict[str, object]:
        """
        Returns::

            {"safe": True}
            {"safe": False, "type": "self_harm", "severity": "critical"|"high"}
        """
        if not text:
            return {"safe": True}

        for pattern in _COMPILED_CRITICAL:
            if pattern.search(text):
                return {"safe": False, "type": "self_harm", "severity": "critical"}

        for pattern in _COMPILED_HIGH:
            if pattern.search(text):
                return {"safe": False, "type": "self_harm", "severity": "high"}

        return {"safe": True}
