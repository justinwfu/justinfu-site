# justinfu.com — Claude Code Context

## What this site is
A personal photo journal at justinfu.com. Static HTML/CSS/JS — no framework, no build step.
Hosted on Vercel (target) / Laughing Squid (current). Production deploys from `main`; feature branches get Vercel preview URLs.

## Site structure
```
index.html              # Episode grid homepage
coffee.html             # Gallery: Coffee
ricoh.html              # Gallery: Ricoh GR IV
suno.html               # Music: Buddhist EDM
screengram.html         # Essay: Screengram
baseball.html           # Gallery: Baseball
images/
  cover-<slug>.jpg      # 800x533 cover for index card
  <slug>/               # optimized JPEGs for gallery
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
- Slug: plain topic name — `{topic}.html` e.g. `baseball.html`, `screengram.html`
- Cover image: `images/cover-{slug}.jpg` cropped 3:2, 800px wide, q85
- Gallery images: `images/{slug}/` folder, max 1600px, q82, progressive JPEG, auto-orient

## How to add a new episode

1. **Optimize photos** — use the `/optimize-image` skill, or inline Python:
   ```python
   from PIL import Image, ImageOps
   im = ImageOps.exif_transpose(Image.open(src))
   im.thumbnail((1600, 1600), Image.LANCZOS)
   im.convert("RGB").save(dst, "JPEG", quality=82, progressive=True, optimize=True)
   ```
   Strip EXIF (no GPS) — the pre-commit hook will reject anything with GPS tags.

2. **Create cover image** — center-crop 3:2 from a hero shot, resize to 800x533, q85.
   Save as `images/cover-{slug}.jpg`.

3. **Copy gallery template** from `ricoh.html` (photo) or `suno.html` (music) and update:
   - `<title>`, `<meta>`, `og:title`, `og:image`
   - `ep-label` (Episode 05, 06…)
   - `ep-title` in header
   - `photos` JS array — list all image paths
   - footer note text

4. **Add episode card to index.html**:
   - Copy an existing `.episode-card` block
   - Update: `href`, `img src`, `ep-label`, `ep-title`, `ep-meta` (count + location)
   - Add as FIRST card (newest episode goes top-left)
   - Bump `header-sub` count: "5 episodes" etc.

5. **Ship via feature branch + PR** (see "Branch workflow" below):
   ```bash
   git checkout -b episode/<slug>
   git add .
   git commit -m "add episode: <Title>"
   git push -u origin episode/<slug>
   gh pr create --fill
   # review the Vercel preview URL posted on the PR
   gh pr merge --squash --delete-branch
   ```
   Vercel deploys the merged commit to prod in ~30 seconds.

## Current episodes
| # | Slug | Title | Count | Notes |
|---|------|-------|-------|-------|
| 07 | kites | Ce jeu de cerfs-volants | 2 videos | Video episode — YouTube embeds (Geographer + YELLE) |
| 06 | sontag | Sontag | essay | On photography |
| 05 | baseball | Baseball | 4 photos | Dodger Stadium, Los Angeles |
| 04 | screengram | Screengram | essay | Concept piece, no photos |
| 03 | suno | Buddhist EDM | 6 tracks | Music episode — Suno embeds |
| 02 | ricoh | Ricoh GR IV | 20 photos | Los Angeles, San Francisco |
| 01 | coffee | Coffee | 20 photos | Asia, California |

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
- `episode/<slug>` — new episodes (`episode/baseball`, `episode/screengram`)
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
- Template: `suno.html` — copy for future music episodes
- Layout: two-column grid (desktop), single column (mobile ≤640px)
- Songs driven by a `tracks` JS array: `{ id, title, desc? }`
- `id` is the Suno song ID from the URL: `suno.com/song/SONG_ID`
- Embed src: `https://suno.com/embed/SONG_ID` in a 152px-tall iframe
- No GPS, no lightbox — music episodes are self-contained

## Video episodes (YouTube)
- Template: `kites.html` — copy for future video episodes
- Layout: stacked vertical `.video-card`s, each with a `01`/`02` numeral and a 16:9 frame; no setlist sidebar, no JS, no prev/next nav
- Stylesheet: `video.css` (loaded alongside `styles.css`; gallery.css is NOT loaded)
- Embed src: `https://www.youtube-nocookie.com/embed/<VIDEO_ID>` (privacy-enhanced; works for IDs sourced from both `youtube.com` and `music.youtube.com`)
- Each iframe needs: `loading="lazy"`, full `allow=` permissions string (incl. `fullscreen`), `allowfullscreen`, `referrerpolicy="strict-origin-when-cross-origin"`, and a `title` attribute (looked up via `youtube.com/oembed` for screen readers — no visible title)
- Cover image: pull `https://img.youtube.com/vi/<VIDEO_ID>/maxresdefault.jpg`, then `PIL.ImageOps.fit` to 800×533 q85 (crops ~12% off left/right since source is 16:9 and the index card enforces 3:2)
- **Pre-flight check:** before opening the PR, open each `youtube-nocookie.com/embed/<ID>` in an incognito tab. Music-label tracks sometimes return "Video unavailable" silently — swap to the regular YT URL or drop the video if blocked
- For N>4 videos consider click-to-load so you don't hammer YouTube on page load (`loading="lazy"` only helps off-screen)

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
