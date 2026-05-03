from __future__ import annotations

TEMPLATES = {
    "general": (
        "If verification is useful, provide a short base-MATLAB or Symbolic Math Toolbox check. "
        "Avoid optional toolboxes beyond Symbolic Math Toolbox."
    ),
    "convolution": (
        "Finish with MATLAB verification code that checks the convolution numerically or symbolically, "
        "uses conv when appropriate, and plots the signals or output when that clarifies the result."
    ),
    "laplace": (
        "Finish with MATLAB verification code using syms, laplace, ilaplace, and simplify where appropriate. "
        "Include a small time-domain check or plot when useful."
    ),
    "fourier": (
        "Finish with MATLAB verification code that computes representative coefficients or spectra and plots a reconstruction or magnitude view when useful."
    ),
    "sampling": (
        "Finish with MATLAB verification code that demonstrates sample-rate choice, sampled points, FFT-based aliasing evidence, and a plot comparison when useful."
    ),
    "stability": (
        "Finish with MATLAB verification code that checks the stated stability criterion numerically or symbolically and reports why the system is or is not BIBO stable."
    ),
    "response": (
        "Finish with MATLAB verification code that evaluates poles/zeros or equivalent formulas and compares impulse, step, or frequency-response behavior without using Control System Toolbox functions."
    ),
}


def build_verification_instruction(topic_mode: str, wants_verification: bool = True) -> str:
    if not wants_verification:
        return ""

    topic_mode = (topic_mode or "general").strip().lower()
    template = TEMPLATES.get(topic_mode, TEMPLATES["general"])
    return (
        "Provide a MATLAB verification section at the end. Use only base MATLAB and Symbolic Math Toolbox. "
        "Do not use markdown fences. "
        + template
    )
