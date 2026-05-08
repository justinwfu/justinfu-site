# justinfu.com — Claude Code Context

## What this site is
A personal photo journal at justinfu.com. Static HTML/CSS/JS — no framework, no build step.
Hosted on Vercel (target) / Laughing Squid (current). Production deploys from `main`; feature branches get Vercel preview URLs.

## Site structure
```
index.html              # Episode grid homepage
coffee-vol-1.html       # Gallery: Coffee, Vol. 1
ricoh-vol-1.html        # Gallery: Ricoh GR IV, Vol. 1
images/
  cover-coffee-vol-1.jpg
  cover-ricoh-vol-1.jpg
  coffee-vol-1/         # 20 optimized JPEGs
  ricoh-vol-1/          # 20 optimized JPEGs
CLAUDE.md               # This file
```

## Design system
- Background: `#0e0d0c` (near black)
- Text: `#d4cfc9` (warm off-white)
- Accent: `#c8a96e` (warm gold)
- Fonts: Cormorant Garamond (serif, titles) + Geist Mono (UI, labels)
- Gallery layout: CSS masonry (3 col → 2 col → 1 col responsive)
- Lightbox: custom vanilla JS, keyboard nav (← → Esc), full-height tap zones on mobile

## Episode naming convention
- Slug: `{topic}-vol-{n}.html` e.g. `coffee-vol-2.html`, `ricoh-vol-2.html`
- Cover image: `images/cover-{slug}.jpg` cropped 3:2, 800px wide, q85
- Gallery images: `images/{slug}/` folder, max 1600px, q82, progressive JPEG, auto-orient

## How to add a new episode

1. **Optimize photos** (ImageMagick):
   ```bash
   mkdir images/new-episode-vol-1
   for f in /path/to/raw/*.jpg; do
     convert "$f" -auto-orient -resize 1600x1600\> -quality 82 -interlace Plane \
       images/new-episode-vol-1/$(basename "$f")
   done
   ```

2. **Create cover image** from best shot:
   ```bash
   convert images/new-episode-vol-1/best.jpg \
     -gravity Center -crop 3:2 +repage \
     -resize 800x533 -quality 85 \
     images/cover-new-episode-vol-1.jpg
   ```

3. **Copy gallery template** from an existing gallery page and update:
   - `<title>`, `<meta>`, `og:title`, `og:image`
   - `ep_label` (Episode 03, 04…)
   - `ep-title` in header
   - `photos` JS array — list all image paths
   - `footer_note` text

4. **Add episode card to index.html**:
   - Copy an existing `.episode-card` block
   - Update: `href`, `img src`, `ep-label`, `ep-title`, `ep-meta` (count + location)
   - Add as FIRST card (newest episode goes top-left)
   - Update `header-sub` count: "3 episodes" etc.

5. **Ship via feature branch + PR** (see "Branch workflow" below):
   ```bash
   git checkout -b episode/new-episode-vol-1
   git add .
   git commit -m "add episode: New Episode, Vol. 1"
   git push -u origin episode/new-episode-vol-1
   gh pr create --fill
   # review the Vercel preview URL posted on the PR
   gh pr merge --squash --delete-branch
   ```
   Vercel deploys the merged commit to prod in ~30 seconds.

## Current episodes
| # | Slug | Title | Count | Notes |
|---|------|-------|-------|-------|
| 03 | suno-vol-1 | Suno, Vol. 1 | 7 tracks | Music episode — Suno embeds, no photos |
| 02 | ricoh-vol-1 | Ricoh GR IV, Vol. 1 | 20 photos | Los Angeles, San Francisco |
| 01 | coffee-vol-1 | Coffee, Vol. 1 | 20 photos | Asia, California |

## Setup tasks (one-time)
- [ ] Install Claude Code: `npm install -g @anthropic-ai/claude-code`
- [ ] Create GitHub repo `justinfu-site` and clone locally
- [ ] Copy site files into repo root
- [ ] `git add . && git commit -m "initial commit" && git push`
- [ ] Connect repo to Vercel (vercel.com → Import Project)
- [ ] Add custom domain `justinfu.com` in Vercel → Domains
- [ ] Update DNS at registrar: point A record to Vercel's IP (76.76.21.21)
- [ ] Verify HTTPS works at https://www.justinfu.com
- [ ] Cancel Laughing Squid once live on Vercel

## Per-clone setup
- [ ] Activate the GPS pre-commit hook: `git config core.hooksPath .githooks`
  (Blocks any commit that includes images carrying GPS EXIF. Requires Pillow: `pip3 install Pillow`.)

## Branch workflow

All changes ship through a feature branch + PR. **Do not push directly to `main`.**
Vercel posts a unique preview URL on every PR — review the rendered site there before merging.

**Branch naming:**
- `episode/<slug>` — new episodes (`episode/screengram`, `episode/ricoh-vol-2`)
- `fix/<short>` — bug fixes (`fix/audio-overlap`)
- `chore/<short>` — tooling, config, docs (`chore/gps-hook`)

**Standard flow:**
```bash
git checkout -b fix/audio-overlap        # branch per logical change
# ...edit, commit freely (messy WIP commits are fine — they get squashed)...
git push -u origin fix/audio-overlap
gh pr create --fill                       # or open in the GitHub UI
# review the Vercel preview URL on the PR
gh pr merge --squash --delete-branch      # main gets one clean commit; auto-deploys to prod
```

Squash-merging keeps `main`'s history one-commit-per-feature (matching the existing style)
while letting in-branch commits stay messy. After merge, `git checkout main && git pull`.

## Music episodes (Suno)
- Template: `suno-vol-1.html` — copy for future music episodes
- Layout: two-column grid (desktop), single column (mobile ≤640px)
- Songs driven by a `tracks` JS array: `{ id, title, desc? }`
- `id` is the Suno song ID from the URL: `suno.com/song/SONG_ID`
- Embed src: `https://suno.com/embed/SONG_ID` in a 152px-tall iframe
- No GPS, no lightbox — music episodes are self-contained

## GPS map feature
- Clicking "📍 view on map" in the lightbox opens a Google Maps satellite embed pinned to the photo location
- GPS coords are extracted from iPhone EXIF data at build time and hardcoded as a `GPS` JS object in each gallery page
- Photos without GPS show a greyed-out "📍 no location data" button (non-clickable)
- Ricoh GR IV strips GPS by default — Ricoh gallery has no pins unless GPS is enabled in camera settings
- To extract GPS from new photos: run the PIL EXIF script and add entries to the `GPS` object in the relevant HTML file
- Map closes on Esc, clicking outside, or the close button

## Notes
- No build step — edit HTML directly, changes go live when the PR merges to `main`
- Images are the heaviest asset — always optimize before committing
- The `photos` JS array in each gallery page controls order — reorder freely
- `white-space: nowrap` on `.ep-location` — keep location strings short
- SSL is currently broken on Laughing Squid (HTTP only) — Vercel fixes this automatically
