#!/usr/bin/env python3
"""
Produces a standalone HTML file with font-toolbar.js inlined — no external dependencies.

Usage:
    python3 shared/inline-toolbar.py <project>/index.html

Output:
    <project>/index-standalone.html

Run from any directory; paths are resolved relative to this script's location.
"""
import pathlib
import re
import sys

if len(sys.argv) != 2:
    print("Usage: python3 shared/inline-toolbar.py <project>/index.html")
    sys.exit(1)

src = pathlib.Path(sys.argv[1]).resolve()
if not src.exists():
    print(f"Error: {src} not found")
    sys.exit(1)

# Resolve font-toolbar.js through the symlink in the project directory
toolbar = src.parent / 'font-toolbar.js'
if not toolbar.exists():
    print(f"Error: {toolbar} not found — did you create the symlink?")
    sys.exit(1)

html = src.read_text()
js   = toolbar.read_text()

inlined = re.sub(
    r'<script\s+src=["\']font-toolbar\.js["\']>\s*</script>',
    f'<script>\n{js}\n</script>',
    html
)

if inlined == html:
    print("Warning: no <script src=\"font-toolbar.js\"> tag found — nothing was inlined")
    sys.exit(1)

out = src.with_name('index-standalone.html')
out.write_text(inlined)
print(f'Written: {out}')
