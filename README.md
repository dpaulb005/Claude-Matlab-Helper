# Claude MATLAB Helper

Claude MATLAB Helper is a desktop MATLAB workflow that lets MATLAB send context to a small local Python bridge, which then calls Claude and returns either:
- a concise answer in the MATLAB Command Window, or
- MATLAB code for the active editor

This repo is designed to be portable, especially for Windows:
- build a clean zip bundle
- move it to another machine
- unzip it
- run one batch file
- start working in MATLAB

Important: despite some older file names like `codex_bridge.py`, the current implementation in this repo uses the Anthropic Python SDK and an `ANTHROPIC_API_KEY`.

## What the script does

At a high level, this project gives MATLAB an AI helper with local context.

It does the following:
1. starts a local HTTP bridge on `http://127.0.0.1:8765`
2. reads the current MATLAB editor contents and recent command-window context
3. optionally pulls in local course notes from `notes/manifest.json`
4. sends the assembled prompt to Claude
5. returns either:
   - a short plain-text explanation, or
   - MATLAB code to paste into the editor

It is meant for desktop MATLAB workflows like:
- asking theory questions in the Command Window
- generating MATLAB functions/snippets
- keeping problem-by-problem context with `lrn(...)`
- grounding answers in bundled class notes

## Main user-facing commands in MATLAB

After setup, the most important commands are:

- `matlab_code_assist_setup` — bootstrap the project inside MATLAB
- `lrn("your prompt")` — preferred study / question interface
- `clr` — instant prerecorded MATLAB snippet
- `matlab_code_assist("editor")` — generate code into the current editor
- `matlab_code_assist("command")` — print the response in the Command Window

Examples:

```matlab
lrn("What does BIBO stability mean?")
lrn("Explain convolution intuitively")
lrn("write a function that computes RMS", "editor")
clr
```

## Repo layout

- `matlab/` — MATLAB helper functions and bridge integration
- `bridge/` — local Python HTTP bridge and bridge launchers
- `tools/` — bundle builder and note-ingestion utilities
- `notes/` — bundled notes, extracted text, and note manifest
- `matlab_code_assist_setup.m` — top-level MATLAB bootstrap entry point
- `RUN_WINDOWS_PORTABLE.bat` — one-click Windows portable launcher
- `setup.bat` — wrapper that calls `RUN_WINDOWS_PORTABLE.bat`

## Requirements

## Windows portable use

For the Windows portable flow, the target machine needs:
- Windows
- MATLAB desktop installed
- Python 3 installed
- internet access for pip install on first run
- a Claude / Anthropic API key

The portable launcher will handle:
- creating a local `.venv`
- installing `requirements.txt`
- saving `ANTHROPIC_API_KEY` into `.env` if needed
- starting the local bridge
- checking bridge health
- trying to open MATLAB in the project folder automatically

## Python packages used by the bridge

From `requirements.txt`:
- `anthropic`
- `pymupdf`
- `pypdf`

## Windows portable: step-by-step

This is the main workflow you asked for.

## On the machine where you build the portable zip

From the repo root:

```bash
python3 tools/make_portable_bundle.py
```

This creates:

```text
dist/claude-matlab-helper-portable.zip
```

The bundle script now excludes junk like:
- `.git`
- `.venv`
- `__pycache__`
- `slprj`
- `dist`
- rendered note pages and other runtime clutter

The zip also contains a single root folder so it extracts cleanly.

## On the Windows machine where you want to use it

### Step 1 — Unzip the bundle

Right-click the zip and extract it anywhere you have normal write access, for example:

```text
C:\Users\YourName\Desktop\claude-matlab-helper-portable
```

Do not run it directly from inside the zip preview. Extract it first.

### Step 2 — Open the extracted folder

Open the extracted folder in File Explorer.

You should see files including:
- `RUN_WINDOWS_PORTABLE.bat`
- `setup.bat`
- `matlab_code_assist_setup.m`
- `bridge/`
- `matlab/`
- `notes/`

### Step 3 — Double-click `RUN_WINDOWS_PORTABLE.bat`

This is the preferred Windows entry point.

What it does automatically:
1. detects Python 3
2. creates a local `.venv` inside the extracted folder if needed
3. installs Python dependencies into that local environment
4. checks for `ANTHROPIC_API_KEY`
5. prompts you for the key if `.env` does not already exist
6. starts the local bridge on port `8765`
7. verifies `http://127.0.0.1:8765/health`
8. tries to launch MATLAB in this project folder automatically
9. tells MATLAB to run `matlab_code_assist_setup(false)`

That makes the folder much more self-contained: the extracted folder carries its own Python environment and startup path.

### Step 4 — If prompted, enter your Claude API key

The launcher will save it to:

```text
.env
```

in the extracted project folder.

The expected line is:

```text
ANTHROPIC_API_KEY=your_key_here
```

### Step 5 — Let MATLAB open

If MATLAB is found automatically, the launcher will open MATLAB with this project as the current folder and run:

```matlab
matlab_code_assist_setup(false)
```

Why `false`?
Because the Windows launcher has already started the bridge, so MATLAB only needs to add the helper code to the path and run the health check.

### Step 6 — Try a command in MATLAB

Once MATLAB is open, try:

```matlab
lrn("What is the Laplace transform of a unit step?")
```

or:

```matlab
clr
```

If that works, the portable folder is fully functional.

## If MATLAB does not launch automatically

If `RUN_WINDOWS_PORTABLE.bat` cannot find `matlab.exe`, do this manually:

1. open MATLAB yourself
2. set MATLAB Current Folder to the extracted project folder
3. run:

```matlab
matlab_code_assist_setup(false)
```

If you did not already run the batch launcher, run:

```matlab
matlab_code_assist_setup
```

That version will try to start the bridge from inside MATLAB.

## Fast manual Windows fallback

If you want to start pieces manually on Windows:

### Start the bridge only

```bat
bridge\start_bridge.bat
```

### Then in MATLAB

```matlab
matlab_code_assist_setup(false)
```

## Typical usage once running

### Study / explanation flow

```matlab
lrn("What does it mean for an LTI system to be causal?")
lrn("Explain why this sampling frequency aliases")
lrn("Compare this to problem 1a")
```

### Generate code into the editor

```matlab
matlab_code_assist("editor")
```

### Generate code or text in the Command Window

```matlab
matlab_code_assist("command")
```

### Terminal-style mode

```matlab
matlab_code_assist_terminal_mode("on")
```

Then you can type lines beginning with `~` in the MATLAB Command Window, though `lrn(...)` is still the more reliable interface.

Disable it with:

```matlab
matlab_code_assist_terminal_mode("off")
```

## Notes support

The project can include local notes and use them as prompt context.

Important files:
- `notes/raw/` — source PDFs
- `notes/text/` — extracted text
- `notes/manifest.json` — manifest used by the bridge

If you add or update notes in the source repo, rebuild the manifest before creating the portable zip.

Useful tools:

```bash
python3 tools/ingest_notes.py
python3 tools/vision_ingest_notes.py
python3 tools/build_notes_manifest.py
```

## Portable bundle behavior

The Windows portable launcher is intended to make the unzipped folder behave more like an app folder.

What stays local to the extracted folder:
- `.venv`
- `.env`
- project files

What is still machine-dependent:
- MATLAB installation
- Python installation
- network access for first-time `pip install`
- your Claude API key

## What changed to improve portability

The portable flow is now more inclusive because:
- there is a single Windows entry point: `RUN_WINDOWS_PORTABLE.bat`
- it creates and reuses a folder-local `.venv`
- `bridge/start_bridge.bat` prefers that local `.venv`
- MATLAB bridge startup now prefers the local `.venv` too
- the zip builder excludes unnecessary repo/build/runtime junk
- the zip extracts into one clean root folder instead of spraying files everywhere

## Troubleshooting

## `RUN_WINDOWS_PORTABLE.bat` says Python is missing

Install Python 3 and make sure one of these works in Command Prompt:
- `py -3`
- `python`

Then run the batch file again.

## Dependencies fail to install

Open Command Prompt in the extracted folder and run:

```bat
.venv\Scripts\python.exe -m pip install -r requirements.txt
```

If `.venv` does not exist yet, rerun `RUN_WINDOWS_PORTABLE.bat`.

## Bridge does not respond on port 8765

The launcher prints the bridge log path. You can also start it manually:

```bat
bridge\start_bridge.bat
```

Then test in a browser or terminal:

```text
http://127.0.0.1:8765/health
```

You should get JSON containing `"ok": true`.

## MATLAB opens but the helper commands are undefined

Make sure MATLAB Current Folder is the extracted project root, then run:

```matlab
matlab_code_assist_setup(false)
```

## The API key was not saved

Create `.env` manually in the project root with:

```text
ANTHROPIC_API_KEY=your_key_here
```

Then rerun:

```bat
RUN_WINDOWS_PORTABLE.bat
```

## Build the portable zip again

Whenever you want a fresh distributable bundle from the source repo:

```bash
python3 tools/make_portable_bundle.py
```

The output zip will be written to:

```text
dist/claude-matlab-helper-portable.zip
```

## Recommended Windows portable workflow summary

If you only remember one flow, use this:

1. build the zip with `python3 tools/make_portable_bundle.py`
2. move the zip to the Windows machine
3. extract it
4. double-click `RUN_WINDOWS_PORTABLE.bat`
5. enter `ANTHROPIC_API_KEY` if prompted
6. let MATLAB open
7. run `lrn("...")`

That is the intended portable workflow for this repo.
