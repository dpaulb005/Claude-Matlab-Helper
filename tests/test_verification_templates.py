from bridge.verification_templates import build_verification_instruction


def test_build_verification_instruction_for_convolution_mentions_numeric_and_plot_checks():
    instruction = build_verification_instruction("convolution")

    assert "conv" in instruction.lower() or "convolution" in instruction.lower()
    assert "plot" in instruction.lower()


def test_build_verification_instruction_for_laplace_mentions_symbolic_tools():
    instruction = build_verification_instruction("laplace")

    assert "syms" in instruction
    assert "laplace" in instruction.lower()
    assert "ilaplace" in instruction.lower()


def test_build_verification_instruction_returns_empty_string_when_not_requested():
    instruction = build_verification_instruction("general", wants_verification=False)

    assert instruction == ""
