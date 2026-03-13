"""
Tests for SafetyClassifier.
"""

from __future__ import annotations

import pytest

from src.services.safety_classifier import SafetyClassifier


@pytest.fixture
def classifier() -> SafetyClassifier:
    return SafetyClassifier()


@pytest.mark.asyncio
async def test_safe_message(classifier: SafetyClassifier) -> None:
    result = await classifier.check("今天天气真好，我们去公园走走吧！")
    assert result["safe"] is True


@pytest.mark.asyncio
async def test_safe_empty_string(classifier: SafetyClassifier) -> None:
    result = await classifier.check("")
    assert result["safe"] is True


@pytest.mark.asyncio
async def test_critical_selfharm_zisha(classifier: SafetyClassifier) -> None:
    result = await classifier.check("我想自杀，活不下去了")
    assert result["safe"] is False
    assert result["type"] == "self_harm"
    assert result["severity"] == "critical"


@pytest.mark.asyncio
async def test_critical_selfharm_buxianghuo(classifier: SafetyClassifier) -> None:
    result = await classifier.check("我真的不想活了")
    assert result["safe"] is False
    assert result["type"] == "self_harm"
    assert result["severity"] == "critical"


@pytest.mark.asyncio
async def test_critical_selfharm_qingsheng(classifier: SafetyClassifier) -> None:
    result = await classifier.check("我有轻生的念头")
    assert result["safe"] is False
    assert result["type"] == "self_harm"
    assert result["severity"] == "critical"


@pytest.mark.asyncio
async def test_critical_selfharm_silesuanle(classifier: SafetyClassifier) -> None:
    result = await classifier.check("死了算了，没意思")
    assert result["safe"] is False
    assert result["type"] == "self_harm"
    assert result["severity"] == "critical"


@pytest.mark.asyncio
async def test_high_severity_撑不下去(classifier: SafetyClassifier) -> None:
    result = await classifier.check("好累啊，感觉撑不下去了")
    assert result["safe"] is False
    assert result["type"] == "self_harm"
    assert result["severity"] == "high"


@pytest.mark.asyncio
async def test_high_severity_没人在乎(classifier: SafetyClassifier) -> None:
    result = await classifier.check("没人在乎我，我无所谓了")
    assert result["safe"] is False
    assert result["type"] == "self_harm"
    assert result["severity"] == "high"


@pytest.mark.asyncio
async def test_normal_sad_message_is_safe(classifier: SafetyClassifier) -> None:
    """A mildly sad message that does not contain explicit self-harm keywords."""
    result = await classifier.check("今天心情不太好，有点难过")
    assert result["safe"] is True
