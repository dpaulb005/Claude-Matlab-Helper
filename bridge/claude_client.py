from __future__ import annotations

from typing import Any

from bridge.prompt_templates import build_system_prompt, build_user_message
from bridge.retrieval import build_notes_context

DEFAULT_MODEL = "claude-opus-4-7"

_client: Any = None


def ensure_api_key() -> str:
    import os

    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        raise RuntimeError(
            "ANTHROPIC_API_KEY is not set. Set it in the environment or create a .env file in the project root."
        )
    return api_key


def get_client() -> Any:
    global _client
    ensure_api_key()
    if _client is None:
        import anthropic

        _client = anthropic.Anthropic()
    return _client


def call_claude(payload: dict, model: str = DEFAULT_MODEL) -> str:
    system_prompt, _settings = build_system_prompt(payload)
    notes_context = build_notes_context(payload.get("request") or "")
    user_message = build_user_message(payload, notes_context)

    response = get_client().messages.create(
        model=model,
        max_tokens=8192,
        system=system_prompt,
        messages=[{"role": "user", "content": user_message}],
    )

    text_blocks = [block.text for block in response.content if block.type == "text"]
    output = "\n".join(text_blocks).strip()
    if not output:
        raise RuntimeError("Claude returned an empty response.")
    return output
