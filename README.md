# MATLAB Code Assist

This project is a portable desktop MATLAB workflow powered by a small local Codex bridge. The folder is organized so the root stays clean and the project is easy to zip, move to another machine, unzip, and use on macOS, Linux, or Windows.

## What It Does

- Runs a small local HTTP bridge that shells out to `codex exec`.
- Lets desktop MATLAB send the current editor context to that bridge.
- Returns concise answers in the Command Window and MATLAB code when editor output is requested.
- Uses your local Codex login instead of storing an API key in MATLAB.
- Keeps runtime logs and transcript capture outside the project folder so the bundle stays cleaner.
- Includes a portable bundle script and both shell and Windows launchers.

## Folder Layout

- `matlab/`: all MATLAB helper commands and integration code
- `bridge/`: the local HTTP bridge and cross-platform launchers
- `tools/`: note-ingestion and bundle-building utilities
- `notes/`: your bundled source notes, extracted text, and manifest
- `dist/`: generated zip bundles
- `matlab_code_assist_setup.m`: root bootstrap entry point for MATLAB

Things that are generated outside the unzipped project:

- bridge logs
- Command Window transcript capture
- Python bytecode cache

That means you can zip this folder without carrying session junk from one machine to another.

## Quick Start

After unzipping this folder on a machine:

1. Make sure `codex` is installed or available through the OpenAI VS Code/Cursor extension on that machine.
2. Open MATLAB.
3. Change MATLAB's current folder to this unzipped project.
4. Run:

```matlab
matlab_code_assist_setup
```

That adds the folder to the MATLAB path, starts the bridge, checks connectivity, and turns on transcript capture.

## Manual Setup

1. Open a terminal in this folder.
2. Sign into Codex if needed.
3. Start the local bridge.
4. Open MATLAB desktop in this folder.
5. Add the folder to the MATLAB path and run the health check.

Commands:

```bash
cd "/path/to/Matlab Helper"
codex login
python3 tools/ingest_notes.py
python3 tools/vision_ingest_notes.py
python3 bridge/start_bridge.py
```

On Windows Command Prompt:

```bat
cd C:\path\to\Matlab Helper
codex login
bridge\start_bridge.bat
```

Optional bridge check:

```bash
curl http://127.0.0.1:8765/health
```

In MATLAB:

```matlab
addpath(pwd)
matlab_code_assist_start_bridge
matlab_code_assist_healthcheck
```

That startup also enables Command Window transcript capture, so future `lrn(...)` requests can refer back to past terminal input and output from the same session.

## Usage

Use directly from the MATLAB Command Window:

```matlab
lrn(1)
lrn("1a")
lrn("part a asks for the Fourier series coefficients")
lrn("that comes from problem 1a, compare it to what we did there")
lrn("now use the same problem context to explain the symmetry shortcut")
lrn(2)
lrn("start problem 2 and solve the convolution part")
lrn("write a function that plots a sine wave from 0 to 10 seconds")
lrn("write a function that computes RMS", "editor")
lrn("show code for a histogram example", "command")
lrn("what does it mean for an LTI system to be BIBO stable?")
lrn("why did my sampling result alias based on what I typed earlier?")
```

This is the recommended terminal-style workflow.

For Command Window questions, the assistant now aims to answer briefly and directly, then use MATLAB only to support the answer when helpful.

Instant failsafe snippet:

```matlab
clr
clr("command")
clr("editor")
```

`clr(...)` does not call the bridge. It returns one of several prerecorded ~30-line MATLAB snippets immediately.

If you still want to use `help("...")`, the project includes an optional wrapper for that too.

Write into the active editor:

```matlab
matlab_code_assist("editor")
```

Print into the MATLAB Command Window instead:

```matlab
matlab_code_assist("command")
```

Enable terminal-style queries from the MATLAB Command Window:

```matlab
matlab_code_assist_terminal_mode("on")
```

Then type commands like this directly into the MATLAB Command Window:

```matlab
~write a function that computes RMS
~plot a sine wave from 0 to 10 seconds
```

Disable terminal mode with:

```matlab
matlab_code_assist_terminal_mode("off")
```

If no active editor is open, generated code is stored in the base workspace variable `matlabCodeAssistLast`.

## Notes

- The bridge auto-detects the `codex` binary from common VS Code extension install paths.
- You can override the binary explicitly:

```bash
CODEX_BIN="/full/path/to/codex" python3 bridge/start_bridge.py
```

- The bridge launcher now works on Windows too through `start_bridge.bat` or `matlab_code_assist_start_bridge`.
- Runtime logs, transcript files, and Python cache are written to a per-user temp/runtime directory instead of inside the project.
- To reference past terminal work reliably, keep transcript capture enabled with `matlab_code_assist_enable_context_capture`. This uses MATLAB's built-in `diary` to capture both commands and printed output.
- Put course PDFs in `notes/raw/` and run `python3 tools/ingest_notes.py` whenever you add or update notes.
- For handwritten notes, prefer `python3 tools/vision_ingest_notes.py`. This renders note pages to images and uses Codex vision to create cleaner study-note text in `notes/cleaned/`. The `tools/ingest_notes.py` OCR path is optional and may be weaker on non-macOS systems.
- The bridge now prepends matching excerpts from your local notes corpus, so Signals and Systems questions can be grounded in your stored material.
- Terminal mode is implemented by polling MATLAB Command History for lines that begin with `~`. Because MATLAB does not expose a documented pre-execution hook for arbitrary Command Window input, you may still briefly see MATLAB's normal syntax error for `~...` before the assistant response is printed.
- Because MATLAB parses `~...` as MATLAB syntax before user code can intercept it, raw `~prompt` input is not a stable primary interface. Use `lrn("your prompt")` for reliable Command Window use.
- Recent Command History is included as prompt context, so the assistant can see what you ran recently in the MATLAB Command Window.
- Recent Command Window transcript is also included when diary capture is on, so the assistant can reason about past code you typed and output MATLAB printed.
- `lrn(1)`, `lrn("1a")`, `lrn("1b")`, and so on switch the active problem context, and later `lrn("...")` calls stay scoped to that problem until you change it.
- If you mention a previous labeled problem in a new request, like `problem 1a`, the assistant also pulls the saved history from that earlier problem into context.
- `lrn(...)` is the preferred interface because it does not interfere with MATLAB's built-in help behavior.
- `clr(...)` returns one of several prerecorded ~30-line MATLAB snippets immediately.

## Making a Clean Zip

To produce a portable bundle from this folder:

```bash
cd "/path/to/Matlab Helper"
python3 tools/make_portable_bundle.py
```

That writes a clean zip to `dist/matlab-code-assist-portable.zip` and excludes runtime clutter such as `__pycache__`, logs, and rendered note pages.

## Next Improvements

- Add a MATLAB toolbar button for one-click launch.
- Add a docked MATLAB app UI instead of `inputdlg`.
- Support “replace selection” in addition to replacing the full active editor buffer.
- Replace Command History polling with a cleaner pre-execution hook if we find a stable desktop API for it.
# Claude-Matlab-Helper
