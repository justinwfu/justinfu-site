---
description: Optimize an image for the site — q82 progressive JPEG, strip EXIF/GPS, max 1600px
argument-hint: <source-path> [optional-output-name.jpg]
allowed-tools: Bash, Read
---

Optimize the image at `$1` per CLAUDE.md conventions.

**Steps:**

1. Resolve destination:
   - If `$2` is given → `images/$2`
   - Otherwise → `images/<source-basename>.jpg` (replace any extension with `.jpg`)

2. Run Python + PIL via Bash to:
   - Open source, convert to RGB (composite PNG transparency over the site bg `#0e0d0c`)
   - Resize so longer edge ≤ 1600px (only if currently larger; use LANCZOS)
   - Save as progressive JPEG, quality=82, optimize=True
   - EXIF is dropped automatically by PIL re-encode

3. **Verify** the output has zero EXIF tags by re-opening and checking `getexif()`. If any GPS data is found, fail loudly.

4. **Report**:
   - Source bytes → dest bytes with % reduction
   - Final dimensions
   - HTML-ready path: `images/<filename>`

If the source path doesn't exist or isn't a recognized image format, stop and report the error — do not attempt to write a destination.
