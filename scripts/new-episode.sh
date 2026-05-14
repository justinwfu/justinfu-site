#!/usr/bin/env bash
# scripts/new-episode.sh
#
# Scaffold a new photo episode end-to-end (HTML + index card) so all you
# have to do is drop optimized JPEGs into images/<slug>/ and edit the
# photos array.
#
# Usage:
#   scripts/new-episode.sh <slug> <ep-num> <title> <location> [count]
#
# Examples:
#   scripts/new-episode.sh tokyo 07 "Tokyo" "Tokyo, Japan" 20
#   scripts/new-episode.sh london 08 "London" "London, England"
#
# What it creates:
#   - <slug>.html               (gallery page, baseball.html template)
#   - images/<slug>/            (empty dir for your JPEGs)
#   - new <a class="episode-card"> at the top of index.html
#   - bumps the "<N> episodes" count in the header
#
# What it does NOT do (still your job):
#   - optimize your JPEGs (use /optimize-image or the inline Pillow recipe
#     in CLAUDE.md)
#   - create images/cover-<slug>.jpg (800x533, q85)
#   - fill in the photos[] array
#   - commit / open a PR

set -euo pipefail

if [[ "$#" -lt 4 ]]; then
  cat <<'USAGE'
Usage: scripts/new-episode.sh <slug> <ep-num> <title> <location> [count]

  slug      filename stub (no .html), e.g. tokyo
  ep-num    zero-padded episode number, e.g. 07
  title     display title, e.g. "Tokyo"
  location  location string for the index card, e.g. "Tokyo, Japan"
  count     optional photo count (default: 0; you'll edit later)

Example:
  scripts/new-episode.sh tokyo 07 "Tokyo" "Tokyo, Japan" 20
USAGE
  exit 1
fi

SLUG="$1"
EP="$2"
TITLE="$3"
LOCATION="$4"
COUNT="${5:-0}"
TODAY="$(date '+%B %-d, %Y')"
TODAY_ISO="$(date '+%Y-%m-%d')"
# portable lowercase (avoid bash 4+ ${var,,}; macOS ships bash 3.2)
LOCATION_LOWER="$(printf '%s' "$LOCATION" | tr '[:upper:]' '[:lower:]')"

# Must run from repo root (so paths resolve)
if [[ ! -f index.html || ! -d images ]]; then
  echo "error: run this from the repo root (index.html + images/ must exist)" >&2
  exit 1
fi

# Slug sanity
if [[ ! "$SLUG" =~ ^[a-z0-9-]+$ ]]; then
  echo "error: slug must be lowercase letters/digits/hyphens only (got: '$SLUG')" >&2
  exit 1
fi

# Don't clobber
if [[ -e "${SLUG}.html" ]]; then
  echo "error: ${SLUG}.html already exists" >&2
  exit 1
fi

# Page file — modeled on baseball.html (cleanest gallery: no map overlay)
cat > "${SLUG}.html" <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="theme-color" content="#0e0d0c">
  <title>Justin Fu — ${TITLE}</title>
  <meta name="description" content="Photographs from ${LOCATION} by Justin Fu.">
  <meta name="author" content="Justin Fu">
  <link rel="canonical" href="https://justinfu.com/${SLUG}.html">
  <meta property="og:type" content="article">
  <meta property="og:title" content="Justin Fu — ${TITLE}">
  <meta property="og:description" content="Photographs from ${LOCATION} by Justin Fu.">
  <meta property="og:url" content="https://justinfu.com/${SLUG}.html">
  <meta property="og:image" content="https://justinfu.com/images/cover-${SLUG}.jpg">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="Justin Fu — ${TITLE}">
  <meta name="twitter:description" content="Photographs from ${LOCATION} by Justin Fu.">
  <meta name="twitter:image" content="https://justinfu.com/images/cover-${SLUG}.jpg">
  <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>◼</text></svg>">
  <link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,300;0,400;1,300;1,400&family=Geist+Mono:wght@300;400&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="styles.css">
  <link rel="stylesheet" href="gallery.css">
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "ImageGallery",
    "name": "${TITLE}",
    "description": "Photographs from ${LOCATION} by Justin Fu.",
    "url": "https://justinfu.com/${SLUG}.html",
    "datePublished": "${TODAY_ISO}",
    "creator": { "@type": "Person", "name": "Justin Fu", "url": "https://justinfu.com/" }
  }
  </script>
</head>
<body>
  <header>
    <a class="back" href="/">← all episodes</a>
    <div class="divider"></div>
    <div class="ep-label">Episode ${EP}</div>
    <h1 class="ep-title">${TITLE}</h1>
    <div class="ep-count">${COUNT} photographs</div>
  </header>

  <div class="gallery-wrap">
    <div class="masonry" id="gallery"></div>
  </div>

  <div id="lightbox">
    <span class="lb-close" onclick="closeLB()">close ✕</span>
    <span class="lb-nav" id="lb-prev" onclick="navLB(-1)">← prev</span>
    <img id="lb-img" src="" alt="">
    <span class="lb-nav" id="lb-next" onclick="navLB(1)">next →</span>
    <div class="lb-counter" id="lb-counter"></div>
  </div>

  <footer>
    <span><a href="/" style="color:inherit;text-decoration:none;">justinfu.com</a></span>
    <span>${LOCATION_LOWER}</span>
  </footer>

  <script>
    // TODO: list your optimized JPEGs with descriptive alt and intrinsic w/h.
    // Run \`python3 -c "from PIL import Image; ..."\` to get dimensions.
    var photos = [
      // { src: "images/${SLUG}/first.jpg", alt: "Describe what is in this photo", w: 1600, h: 1067 },
    ];
    var current = 0;
    var gallery = document.getElementById('gallery');
    photos.forEach(function(p, i) {
      var item = document.createElement('div');
      item.className = 'photo-item';
      var img = document.createElement('img');
      img.src = p.src; img.alt = p.alt; img.width = p.w; img.height = p.h; img.loading = 'lazy';
      img.onload = function() { this.classList.add('loaded'); };
      item.appendChild(img);
      item.addEventListener('click', function() { openLB(i); });
      gallery.appendChild(item);
    });
    var lb = document.getElementById('lightbox');
    var lbImg = document.getElementById('lb-img');
    var lbCounter = document.getElementById('lb-counter');
    function openLB(i) {
      current = i; lbImg.src = photos[i].src; lbImg.alt = photos[i].alt;
      lbCounter.textContent = (i+1) + ' / ' + photos.length;
      lb.classList.add('open'); document.body.style.overflow = 'hidden';
    }
    function closeLB() { lb.classList.remove('open'); document.body.style.overflow = ''; }
    function navLB(dir) {
      current = (current + dir + photos.length) % photos.length;
      lbImg.src = photos[current].src; lbImg.alt = photos[current].alt;
      lbCounter.textContent = (current+1) + ' / ' + photos.length;
    }
    lb.addEventListener('click', function(e) { if (e.target === lb) closeLB(); });
    document.addEventListener('keydown', function(e) {
      if (!lb.classList.contains('open')) return;
      if (e.key === 'Escape') closeLB();
      if (e.key === 'ArrowLeft') navLB(-1);
      if (e.key === 'ArrowRight') navLB(1);
    });
  </script>
</body>
</html>
HTML

# Image dir
mkdir -p "images/${SLUG}"

# Insert card at top of index grid + bump episode count.
# Python keeps quoting/regex safety simple vs sed.
SLUG="$SLUG" EP="$EP" TITLE="$TITLE" LOCATION="$LOCATION" COUNT="$COUNT" TODAY="$TODAY" TODAY_ISO="$TODAY_ISO" \
python3 - <<'PYEOF'
import os, re, sys

slug = os.environ['SLUG']
ep = os.environ['EP']
title = os.environ['TITLE']
location = os.environ['LOCATION']
count = os.environ['COUNT']
today = os.environ['TODAY']
today_iso = os.environ['TODAY_ISO']

card = (
    f'    <a class="episode-card" href="{slug}.html">\n'
    f'      <img src="images/cover-{slug}.jpg" alt="{title}" width="800" height="533" loading="lazy" decoding="async">\n'
    f'      <div class="ep-arrow">↗</div>\n'
    f'      <div class="episode-info">\n'
    f'        <div class="ep-label">Episode {ep}</div>\n'
    f'        <div class="ep-title">{title}</div>\n'
    f'        <div class="ep-meta">{count} photographs<span class="ep-location">{location}</span><span class="ep-location"><time datetime="{today_iso}">{today}</time></span></div>\n'
    f'      </div>\n'
    f'    </a>\n\n'
)

with open('index.html', 'r', encoding='utf-8') as f:
    content = f.read()

# Insert at the top of the grid (works regardless of what classes the
# next card uses — e.g. essay cards add episode-card--essay).
marker = '  <div class="index-grid">\n\n'
if marker not in content:
    print('error: could not find <div class="index-grid"> opener in index.html', file=sys.stderr)
    sys.exit(2)
content = content.replace(marker, marker + card, 1)

# Bump the "<N> episodes" header count
def bump(m):
    return f'{m.group(1)}{int(m.group(2))+1}{m.group(3)}'
content, n = re.subn(
    r'(<div class="header-sub">)(\d+)( episodes)',
    bump, content, count=1,
)
if n == 0:
    print('warning: did not find "<N> episodes" header to bump', file=sys.stderr)

with open('index.html', 'w', encoding='utf-8') as f:
    f.write(content)
PYEOF

cat <<DONE

✓ created ${SLUG}.html
✓ created images/${SLUG}/
✓ inserted card in index.html (now Episode ${EP}: ${TITLE})

Next steps:
  1. optimize JPEGs into images/${SLUG}/ (e.g. ./scripts/new-episode helpers, or /optimize-image)
  2. fill in the photos[] array in ${SLUG}.html
  3. create images/cover-${SLUG}.jpg (800x533, q85)
  4. git checkout -b episode/${SLUG}
     git add ${SLUG}.html index.html images/${SLUG} images/cover-${SLUG}.jpg
     git commit -m "add episode: ${TITLE}"
     git push -u origin episode/${SLUG} && gh pr create --fill
DONE
