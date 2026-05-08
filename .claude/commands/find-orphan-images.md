---
description: Find images in /images/ that aren't referenced by any HTML file
allowed-tools: Bash
---

Find orphaned image files — anything under `images/` that no `*.html` file references.

**Steps:**

1. List every file under `images/` (recursively), relative to the repo root.

2. For each file, grep all `*.html` at the repo root for the path. Match flexibly:
   - The full relative path (e.g. `images/coffee-vol-1/01.jpg`)
   - Just the basename (in case a page uses a different prefix)

3. Categorize results:
   - **Orphaned** — no HTML reference at all
   - **Referenced** — at least one HTML reference

4. **Report**:
   - Count of total images, referenced, orphaned
   - List orphaned paths with file size each
   - Total reclaimable bytes if all orphans are removed

5. Do NOT delete anything. End with a one-liner the user can copy if they want to clean up:

   ```
   git rm <orphan1> <orphan2> ...
   ```
