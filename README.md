# Claude MATLAB Helper

Claude MATLAB Helper is a desktop MATLAB workflow that sends local context to a one-shot Python helper, calls Claude, and returns either:
- a concise answer in the MATLAB Command Window, or
- MATLAB code for the active editor

This project is now direct-mode only.
There is no localhost HTTP bridge, no background server, and no port 8765 dependency.

## How it works

On each request, MATLAB:
1. captures editor / selection / command-window context
2. writes a request JSON file to a temp directory
3. runs `bridge/run_claude_request.py`
4. lets Python call Claude with the assembled prompt
5. reads the JSON response back into MATLAB

## Main MATLAB commands

- `matlab_code_assist_setup` — add the project to the path and run a direct-mode healthcheck
- `lrn("your prompt")` — preferred study / question interface
- `lrn("mode sampling exam verify")` — set active topic / response behavior
- `lrn("show mode")` / `lrn("clear mode")` — inspect or reset the active mode
- `clr` — instant prerecorded MATLAB snippet
- `matlab_code_assist("editor")` — generate code into the current editor
- `matlab_code_assist("command")` — print the response in the Command Window
- `matlab_code_assist_plot_convolution(t, x, h)` — visualize convolution step-by-step
- `matlab_code_assist_sampling_demo(f_signal, fs, duration)` — visualize sampling and aliasing
- `matlab_code_assist_system_summary('num', num, 'den', den)` — pole-zero map, BIBO stability, impulse response
- `matlab_code_assist_fourier_demo('Waveform', 'square', 'N', 10)` — Fourier series reconstruction explorer

Examples:

```matlab
lrn("What does BIBO stability mean?")
lrn("Explain convolution intuitively")
lrn("mode convolution derivation verify")
lrn("show mode")
lrn("write a function that computes RMS", "editor")

% Visual helpers

t = 0:0.01:1;
x = double(t >= 0 & t <= 0.5);
h = double(t >= 0 & t <= 0.3);
matlab_code_assist_plot_convolution(t, x, h)

matlab_code_assist_sampling_demo(5, 8, 1)
matlab_code_assist_sampling_demo(5, 50, 1)

% Wave 3
matlab_code_assist_system_summary('num', [1], 'den', [1 3 2])
matlab_code_assist_fourier_demo('Waveform', 'square', 'N', 15, 'T', 1)
lrn("mode incognito")
lrn("mode noincognito")
clr
```

## Repo layout

- `matlab/` — MATLAB helper functions
- `bridge/` — Python direct-mode Claude helper modules
- `tools/` — portable bundle builder and note-ingestion utilities
- `notes/` — bundled notes, extracted text, and note manifest
- `matlab_code_assist_setup.m` — top-level MATLAB bootstrap entry point
- `RUN_WINDOWS_PORTABLE.bat` — one-click Windows launcher
- `setup.bat` — wrapper that calls `RUN_WINDOWS_PORTABLE.bat`
- `setup.sh` — Mac / Linux setup helper

## Requirements

### Windows portable use

The target machine needs:
- Windows
- MATLAB desktop installed
- Python 3 installed
- internet access for pip install on first run
- outbound HTTPS access to Anthropic
- a Claude / Anthropic API key

### Python packages

From `requirements.txt`:
- `anthropic`
- `pymupdf`
- `pypdf`

## Windows portable workflow

### On the machine where you build the portable zip

From the repo root:

```bash
python3 tools/make_portable_bundle.py
```

This creates:

```text
dist/claude-matlab-helper-portable.zip
```

The bundle excludes junk like `.git`, `.venv`, `__pycache__`, `slprj`, `dist`, and rendered note pages.

### On the Windows machine where you want to use it

1. Extract the zip to a normal writable folder.
2. Double-click `RUN_WINDOWS_PORTABLE.bat`.
3. Let it:
   - detect Python
   - create `.venv`
   - install requirements
   - collect or reuse `ANTHROPIC_API_KEY`
   - run a direct-mode healthcheck
   - launch MATLAB in the project folder
4. In MATLAB, try:

```matlab
lrn("What is the Laplace transform of a unit step?")
```

If MATLAB does not launch automatically:
1. open MATLAB manually
2. set Current Folder to the extracted project folder
3. run:

```matlab
matlab_code_assist_setup
```

## Mac / Linux setup

From the repo root:

```bash
bash setup.sh
```

Then in MATLAB:

```matlab
matlab_code_assist_setup
lrn("your question")
```

## Validation

Python validation:

```bash
python3 -m compileall bridge
python3 -m pytest tests -q
```

MATLAB-side validation should be run in MATLAB, not Octave.

## Troubleshooting

### `ANTHROPIC_API_KEY` is not set

Either:
- export it in your shell, or
- create a `.env` file in the project root containing:

```text
ANTHROPIC_API_KEY=your_key_here
```

### Direct-mode healthcheck fails

Run:

```bash
python3 bridge/run_claude_request.py --healthcheck --output /tmp/matlab-code-assist-health.json
cat /tmp/matlab-code-assist-health.json
```

On Windows, run the portable launcher again and read the printed JSON error.

### Claude requests still fail on school computers

This repo no longer depends on localhost networking.
If it still fails on a managed machine, the likely problem is outbound network policy blocking Anthropic API access.

## Notes

- `notes/manifest.json` is used for local course-note retrieval.
- This project targets MATLAB desktop workflows.
- Do not use Octave for validation.
