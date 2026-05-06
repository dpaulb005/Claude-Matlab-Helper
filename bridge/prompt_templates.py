from __future__ import annotations

from typing import Any

from bridge.signals_modes import resolve_mode_settings
from bridge.verification_templates import build_verification_instruction

BASE_TOOLBOX_INSTRUCTIONS = [
    "Only use base MATLAB and the Symbolic Math Toolbox (syms, laplace, ilaplace, fourier, ifourier, solve, simplify, etc.).",
    "Do NOT use the Control System Toolbox (tf, bode, step, zpkdata, etc.) or any other optional toolbox.",
    "If a task would normally use tf() or bode(), implement it using symbolic or numeric methods instead.",
]

INCOGNITO_INSTRUCTIONS = [
    "INCOGNITO MODE IS ACTIVE.",
    "Format your entire response as valid MATLAB. This means:",
    "  - All explanations, reasoning, and derivations go inside % comment lines.",
    "  - Any mathematical steps appear as % comments showing each step.",
    "  - Any MATLAB code appears as normal executable lines.",
    "  - Do NOT write prose, sentences, or paragraphs outside of % comments.",
    "  - The output must look like a .m file someone wrote themselves.",
    "  - Example format for an explanation:",
    "    % BIBO stable: system is stable if the impulse response is absolutely integrable.",
    "    % For H(s) = 1/(s+2), all poles have negative real parts -> stable.",
    "  - Example format for a derivation with code:",
    "    % Step 1: define symbolic variable",
    "    syms s t",
    "    % Step 2: define transfer function",
    "    H = 1 / (s + 2);",
    "    % Step 3: inverse Laplace",
    "    h = ilaplace(H);",
    "    % Result: h(t) = exp(-2t) * u(t)",
    "  - Never break this format. Every line is either a % comment or MATLAB code.",
]

VISUAL_HELPERS = {
    "convolution": (
        "matlab_code_assist_plot_convolution(t, x, h) — plots x(t), h(t), "
        "the time-reversed/shifted h(t0-tau) at a chosen shift point, and the convolution output y(t). "
        "Use this when showing or verifying a convolution result visually."
    ),
    "sampling": (
        "matlab_code_assist_sampling_demo(f_signal, fs, duration) — plots the analog waveform, "
        "sampled points, and FFT spectra with an aliasing warning when fs < 2*f_signal. "
        "Use this when demonstrating Nyquist/aliasing concepts."
    ),
    "stability": (
        "matlab_code_assist_system_summary('num', num, 'den', den) — computes poles, zeros, "
        "BIBO stability classification, and symbolic impulse response. Plots the pole-zero map. "
        "Use this when analyzing stability or system behavior."
    ),
    "fourier": (
        "matlab_code_assist_fourier_demo('Waveform','square','N',10,'T',1) — reconstructs a "
        "periodic signal from its Fourier series, shows harmonic build-up and spectrum. "
        "Use this when exploring Fourier series convergence or coefficients."
    ),
}

VISUAL_HELPERS_BY_TOPIC = {
    "convolution": ["convolution"],
    "sampling": ["sampling"],
    "stability": ["stability"],
    "response": ["stability"],
    "fourier": ["fourier"],
    "general": ["convolution", "sampling"],
    "laplace": [],
}


def _build_visual_helpers_note(topic_mode: str, wants_visualization: bool) -> str:
    relevant_keys = VISUAL_HELPERS_BY_TOPIC.get(topic_mode, [])
    if not relevant_keys:
        return ""

    lines = ["Available local MATLAB visual helpers (call these directly in the Command Window):"]
    for key in relevant_keys:
        if key in VISUAL_HELPERS:
            lines.append(f"  - {VISUAL_HELPERS[key]}")

    if wants_visualization:
        lines.append(
            "When a visual would materially help understanding, suggest the appropriate helper command above."
        )
    else:
        lines.append(
            "Mention these helpers if they would clarify your answer, but do not insist on them."
        )
    return "\n".join(lines)


def build_system_prompt(payload: dict[str, Any]) -> tuple[str, dict[str, Any]]:
    settings = resolve_mode_settings(payload)
    target = str(payload.get("target") or "command").lower()
    incognito = settings["incognito"]

    if incognito:
        # In incognito mode all output is formatted as MATLAB regardless of target
        behavior = [
            "Return your response formatted as MATLAB only — explanations as % comments, code as executable lines.",
            "Do not use markdown fences.",
            "Do not write any prose outside of % comment lines.",
        ]
    elif target == "editor":
        behavior = [
            "Return MATLAB code only.",
            "Do not use markdown fences.",
            "Do not explain the code.",
            "If editing a selection, return only the replacement code for that selection.",
        ]
    else:
        behavior = [
            "Answer the user's question directly and very concisely.",
            "Prefer plain text with optional short MATLAB code unless the response mode asks for a structured derivation.",
            "Do not use markdown fences.",
        ]

    prompt_lines = [
        "You are a MATLAB study assistant.",
        "You are especially strong at Signals and Systems.",
        f"Current topic mode: {settings['topic_mode']}.",
        f"Current response mode: {settings['response_mode']}.",
        behavior[0],
        *behavior[1:],
        settings["topic_instruction"],
        settings["response_instruction"],
        "Explicitly distinguish continuous-time from discrete-time when that affects the answer.",
        "Use the provided course notes when they are relevant.",
        "Keep continuity with the current problem context when one is active.",
        *BASE_TOOLBOX_INSTRUCTIONS,
    ]

    if incognito:
        prompt_lines.extend(INCOGNITO_INSTRUCTIONS)

    verification_instruction = build_verification_instruction(
        settings["topic_mode"],
        wants_verification=settings["wants_verification"],
    )
    if verification_instruction:
        if incognito:
            prompt_lines.append(
                "Verification code: include it as executable MATLAB lines after a % Verification: comment header."
            )
        else:
            prompt_lines.append(verification_instruction)

    visual_note = _build_visual_helpers_note(
        settings["topic_mode"],
        settings["wants_visualization"],
    )
    if visual_note:
        prompt_lines.append(visual_note)

    return "\n".join(prompt_lines), settings


def format_problem_context(problem_label: Any) -> str:
    if problem_label in (None, "", []):
        return "(no active problem selected)"
    return (
        f"Problem {problem_label}. Keep the answer scoped to this problem and its "
        "follow-up parts unless the user switches to a different problem."
    )


def build_user_message(payload: dict[str, Any], notes_context: str) -> str:
    editor = payload.get("editor") or {}
    file_name = editor.get("fileName") or "untitled.m"
    file_code = editor.get("code") or ""
    selected_code = editor.get("selectedCode") or ""
    command_window = payload.get("commandWindow") or ""
    workspace_summary = payload.get("workspaceSummary") or ""
    problem_label = payload.get("problemLabel")
    problem_context = payload.get("problemContext") or ""
    request = payload.get("request") or ""
    request_options = payload.get("requestOptions") or {}

    return "\n".join([
        "Current active problem context:",
        format_problem_context(problem_label),
        "",
        "Active request options:",
        str(request_options),
        "",
        "Relevant prior problem history:",
        problem_context or "(no saved problem history available)",
        "",
        "Relevant course notes:",
        notes_context,
        "",
        f"Active MATLAB file: {file_name}",
        "",
        "User request:",
        request,
        "",
        "Selected code:",
        selected_code or "(no selection)",
        "",
        "Current file contents:",
        file_code or "(empty file)",
        "",
        "Current base workspace summary:",
        workspace_summary or "(no workspace variables captured)",
        "",
        "Recent Command Window context:",
        command_window or "(unavailable)",
    ])
