#!/usr/bin/env python3

import sys
import zipfile
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent.parent
DIST_DIR = PROJECT_DIR / "dist"
EXCLUDED_NAMES = {
    ".DS_Store",
}
EXCLUDED_DIR_NAMES = {
    "__pycache__",
    "state",
    "dist",
}
EXCLUDED_PARTS = {
    "notes/rendered",
    "EE350 Lectures",
}


def should_include(path: Path):
    relative = path.relative_to(PROJECT_DIR)
    relative_posix = relative.as_posix()

    if path.name in EXCLUDED_NAMES:
        return False

    if any(part in EXCLUDED_DIR_NAMES for part in relative.parts):
        return False

    if relative_posix in EXCLUDED_PARTS:
        return False

    for excluded in EXCLUDED_PARTS:
        if relative_posix.startswith(excluded + "/"):
            return False

    return True


def iter_files():
    for path in sorted(PROJECT_DIR.rglob("*")):
        if not path.is_file():
            continue
        if should_include(path):
            yield path


def main():
    bundle_name = sys.argv[1] if len(sys.argv) > 1 else "matlab-code-assist-portable.zip"
    DIST_DIR.mkdir(parents=True, exist_ok=True)
    bundle_path = DIST_DIR / bundle_name

    with zipfile.ZipFile(bundle_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for path in iter_files():
            archive.write(path, path.relative_to(PROJECT_DIR))

    print(f"Wrote portable bundle: {bundle_path}")


if __name__ == "__main__":
    main()
