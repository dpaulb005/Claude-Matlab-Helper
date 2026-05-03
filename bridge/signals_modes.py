from __future__ import annotations

from typing import Any

TOPIC_MODES = (
    "general",
    "convolution",
    "laplace",
    "fourier",
    "sampling",
    "stability",
    "response",
)
RESPONSE_MODES = ("concise", "derivation", "exam")
DEFAULT_REQUEST_OPTIONS = {
    "topicMode": "general",
    "responseMode": "concise",
    "wantsVerification": False,
    "wantsVisualization": False,
    "incognito": False,
    "modeSource": "default",
}

TOPIC_KEYWORDS = {
    "convolution": ("convolution", "convolve", "overlap", "impulse response"),
    "laplace": ("laplace", "roc", "partial fraction", "inverse laplace"),
    "fourier": ("fourier", "harmonic", "spectrum", "series", "transform"),
    "sampling": ("sampling", "aliasing", "nyquist", "sample rate", "reconstruction"),
    "stability": ("bibo", "stable", "stability", "summable", "integrable"),
    "response": ("pole", "zero", "impulse response", "step response", "frequency response"),
}

MODE_INSTRUCTIONS = {
    "general": "Answer as a MATLAB study assistant with Signals and Systems awareness.",
    "convolution": (
        "Focus on convolution setup, time reversal, shifting, overlap intervals, and piecewise support. "
        "When verification is requested, include a MATLAB-friendly numeric or symbolic check plus plots when useful."
    ),
    "laplace": (
        "Focus on Laplace/inverse Laplace reasoning, ROC and causality assumptions, partial fractions, and symbolic checks."
    ),
    "fourier": (
        "Focus on Fourier series/transform intuition, coefficient interpretation, reconstruction, symmetry, and harmonics."
    ),
    "sampling": (
        "Focus on sampling, Nyquist limits, aliasing, spectrum replicas, and reconstruction limitations."
    ),
    "stability": (
        "Focus on BIBO stability criteria and explicitly distinguish continuous-time from discrete-time arguments."
    ),
    "response": (
        "Focus on pole-zero interpretation, impulse/step behavior, and frequency-response intuition without using Control System Toolbox shortcuts."
    ),
}

RESPONSE_STYLE_INSTRUCTIONS = {
    "concise": "Be concise and direct unless the user asks for more detail.",
    "derivation": "Show the derivation step by step and justify each property or transformation used.",
    "exam": "Present the solution in a clean exam-style format with explicit steps and minimal fluff.",
}


def normalize_request_options(request_options: dict[str, Any] | None) -> dict[str, Any]:
    normalized = dict(DEFAULT_REQUEST_OPTIONS)
    if request_options:
        normalized.update(request_options)

    topic_mode = str(normalized.get("topicMode", "general") or "general").strip().lower()
    response_mode = str(normalized.get("responseMode", "concise") or "concise").strip().lower()

    if topic_mode not in TOPIC_MODES:
        raise ValueError(f"Unsupported topic mode: {topic_mode}")
    if response_mode not in RESPONSE_MODES:
        raise ValueError(f"Unsupported response mode: {response_mode}")

    normalized["topicMode"] = topic_mode
    normalized["responseMode"] = response_mode
    normalized["wantsVerification"] = bool(normalized.get("wantsVerification", False))
    normalized["wantsVisualization"] = bool(normalized.get("wantsVisualization", False))
    normalized["incognito"] = bool(normalized.get("incognito", False))

    mode_source = str(normalized.get("modeSource", "default") or "default").strip().lower()
    if mode_source not in {"default", "explicit"}:
        raise ValueError(f"Unsupported mode source: {mode_source}")
    normalized["modeSource"] = mode_source
    return normalized


def infer_topic_mode(request: str, fallback: str = "general") -> str:
    text = (request or "").lower()
    if not text:
        return fallback

    best_mode = fallback
    best_score = 0
    for mode, keywords in TOPIC_KEYWORDS.items():
        score = sum(1 for keyword in keywords if keyword in text)
        if score > best_score:
            best_mode = mode
            best_score = score
    return best_mode


def resolve_mode_settings(payload: dict[str, Any]) -> dict[str, Any]:
    request = str(payload.get("request") or "")
    options = normalize_request_options(payload.get("requestOptions") or {})

    topic_mode = options["topicMode"]
    if topic_mode == "general" and options["modeSource"] != "explicit":
        topic_mode = infer_topic_mode(request, fallback="general")

    return {
        "topic_mode": topic_mode,
        "response_mode": options["responseMode"],
        "wants_verification": options["wantsVerification"],
        "wants_visualization": options["wantsVisualization"],
        "incognito": options["incognito"],
        "raw_options": options,
        "topic_instruction": MODE_INSTRUCTIONS[topic_mode],
        "response_instruction": RESPONSE_STYLE_INSTRUCTIONS[options["responseMode"]],
    }
