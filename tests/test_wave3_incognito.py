"""Tests for Wave 3: incognito mode and new bridge features."""
from bridge.prompt_templates import build_system_prompt
from bridge.signals_modes import normalize_request_options


def test_incognito_flag_normalizes_correctly():
    opts = normalize_request_options({"incognito": True})
    assert opts["incognito"] is True


def test_incognito_off_by_default():
    opts = normalize_request_options({})
    assert opts["incognito"] is False


def test_incognito_system_prompt_contains_comment_format_instructions():
    payload = {
        "request": "Explain BIBO stability",
        "requestOptions": {"incognito": True, "modeSource": "explicit"},
        "target": "command",
    }
    prompt, settings = build_system_prompt(payload)

    assert settings["incognito"] is True
    assert "%" in prompt          # MATLAB comment character must appear
    assert "INCOGNITO" in prompt


def test_incognito_overrides_command_behavior():
    """Incognito should format as MATLAB even for command target."""
    payload_normal = {
        "request": "Explain BIBO",
        "requestOptions": {"incognito": False, "modeSource": "explicit"},
        "target": "command",
    }
    payload_incognito = {
        "request": "Explain BIBO",
        "requestOptions": {"incognito": True, "modeSource": "explicit"},
        "target": "command",
    }
    prompt_normal, _ = build_system_prompt(payload_normal)
    prompt_incognito, _ = build_system_prompt(payload_incognito)

    # Normal prompt should say "very concisely"; incognito should not
    assert "concisely" in prompt_normal
    assert "concisely" not in prompt_incognito


def test_incognito_with_verification_uses_comment_header():
    payload = {
        "request": "Find the Laplace transform",
        "requestOptions": {
            "incognito": True,
            "topicMode": "laplace",
            "wantsVerification": True,
            "modeSource": "explicit",
        },
        "target": "command",
    }
    prompt, _ = build_system_prompt(payload)

    assert "Verification" in prompt
    assert "INCOGNITO" in prompt


def test_incognito_mode_token_parsed_by_signals_modes():
    opts = normalize_request_options({"incognito": True, "topicMode": "laplace", "modeSource": "explicit"})
    assert opts["incognito"] is True
    assert opts["topicMode"] == "laplace"
