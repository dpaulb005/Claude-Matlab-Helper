"""Tests for Wave 2 visual helper bridge integration."""
from bridge.prompt_templates import build_system_prompt


def test_system_prompt_mentions_convolution_helper_when_topic_is_convolution():
    payload = {
        "request": "Compute the convolution of two rectangular pulses",
        "requestOptions": {"topicMode": "convolution", "modeSource": "explicit"},
        "target": "command",
    }
    prompt, _ = build_system_prompt(payload)

    assert "convolution" in prompt.lower()


def test_system_prompt_mentions_sampling_helper_when_topic_is_sampling():
    payload = {
        "request": "Show aliasing at low sample rate",
        "requestOptions": {"topicMode": "sampling", "modeSource": "explicit"},
        "target": "command",
    }
    prompt, _ = build_system_prompt(payload)

    assert "sampling" in prompt.lower()


def test_visual_helpers_mentioned_when_wants_visualization():
    payload = {
        "request": "Show the convolution graphically",
        "requestOptions": {
            "topicMode": "convolution",
            "wantsVisualization": True,
            "modeSource": "explicit",
        },
        "target": "command",
    }
    prompt, settings = build_system_prompt(payload)

    assert settings["wants_visualization"] is True
    assert "plot" in prompt.lower() or "visual" in prompt.lower() or "helper" in prompt.lower()


def test_visual_helpers_listed_in_user_message():
    from bridge.prompt_templates import build_user_message

    payload = {
        "request": "Visualize convolution",
        "requestOptions": {"topicMode": "convolution", "wantsVisualization": True, "modeSource": "explicit"},
        "target": "command",
    }
    msg = build_user_message(payload, "(no notes)")

    assert "convolution" in msg.lower()
