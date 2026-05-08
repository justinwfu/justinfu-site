---
description: Scaffold a new PHOTO episode end-to-end (optimize photos, cover crop, gallery page, index card). Music and essay episodes use different templates — not handled here.
argument-hint: <slug e.g. coffee-vol-2> <"Title e.g. Coffee, Vol. 2"> <source-folder e.g. ~/Desktop/raw-coffee-2>
allowed-tools: Bash, Read, Edit, Write
---

Create a new photo episode following the playbook in CLAUDE.md.

This skill is for **photo galleries only**. Music episodes (like `suno.html`) and essay episodes (like `screengram.html`) use different templates and should be created by hand or with a future dedicated skill.

**Args:** `$1` = slug, `$2` = display title, `$3` = source folder of raw photos.

**Steps:**

1. **Validate inputs**
   - `$3` exists and contains JPEG/PNG files
   - `$1` does not collide with an existing `*.html` page or `images/$1/` folder
   - Ask the user to choose which raw file should be the cover, using `AskUserQuestion` with the filenames as options.

2. **Optimize gallery photos** to `images/$1/`:
   - Same recipe as `/optimize-image` — q82 progressive, max 1600px, EXIF stripped
   - Preserve original filenames (replace extension with `.jpg`)
   - Report total bytes in vs out

3. **Create cover image** at `images/cover-$1.jpg`:
   - Take the user-selected raw → 3:2 center crop → 800×533 → q85 progressive → EXIF stripped

4. **Extract GPS** from the originals (before stripping):
   - Read EXIF GPS from each source file using PIL
   - Build a `GPS` JS object keyed by output filename: `{ "01.jpg": { lat, lng } }`
   - Skip files with no GPS

5. **Generate the gallery page** at `$1.html`:
   - Use the most recent existing photo gallery page (e.g. `ricoh.html` or `coffee.html`) as a template — Read it, then Write the new page with these substitutions:
     - `<title>`, `<meta>`, `og:title`, `og:image`
     - `ep_label` → next episode number (count existing photo `*.html` pages and add 1)
     - `ep-title` in header
     - `photos` JS array — list all `images/$1/*.jpg`
     - `GPS` JS object — built in step 4
     - Footer note text → `$2`

6. **Update `index.html`**:
   - Read it, then add a new `.episode-card` block as the FIRST card inside `.index-grid`
   - Use the cover image and link to `$1.html`
   - Update `header-sub` count: increment "N episodes"

7. **Show a diff summary** and ask the user to review before committing. Do NOT auto-commit.

   Final report:
   - Photos optimized: N (total size: X MB → Y MB)
   - Photos with GPS: N / total
   - Cover created: `images/cover-$1.jpg`
   - Gallery page created: `$1.html`
   - Index card added — episode count now N

If at any step the user wants to bail (e.g. cover choice prompt cancelled), stop cleanly and don't leave half-created files.
