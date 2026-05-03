import pytest

from bridge.signals_modes import normalize_request_options, resolve_mode_settings


def test_resolve_mode_settings_uses_defaults_when_request_options_missing():
    settings = resolve_mode_settings({})

    assert settings["topic_mode"] == "general"
    assert settings["response_mode"] == "concise"
    assert settings["wants_verification"] is False
    assert settings["wants_visualization"] is False


def test_resolve_mode_settings_honors_explicit_request_options():
    settings = resolve_mode_settings(
        {
            "request": "Explain aliasing",
            "requestOptions": {
                "topicMode": "sampling",
                "responseMode": "exam",
                "wantsVerification": True,
                "wantsVisualization": True,
            },
        }
    )

    assert settings["topic_mode"] == "sampling"
    assert settings["response_mode"] == "exam"
    assert settings["wants_verification"] is True
    assert settings["wants_visualization"] is True


def test_resolve_mode_settings_detects_sampling_mode_from_request_text_when_mode_source_is_default():
    settings = resolve_mode_settings(
        {
            "request": "Show why this signal aliases when the sample rate is too low",
            "requestOptions": {"modeSource": "default"},
        }
    )

    assert settings["topic_mode"] == "sampling"
    assert settings["response_mode"] == "concise"


def test_resolve_mode_settings_preserves_explicit_general_mode():
    settings = resolve_mode_settings(
        {
            "request": "Show why this signal aliases when the sample rate is too low",
            "requestOptions": {"topicMode": "general", "modeSource": "explicit"},
        }
    )

    assert settings["topic_mode"] == "general"


def test_normalize_request_options_rejects_invalid_modes():
    with pytest.raises(ValueError):
        normalize_request_options({"topicMode": "banana"})

    with pytest.raises(ValueError):
        normalize_request_options({"responseMode": "verify"})
