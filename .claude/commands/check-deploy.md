---
description: Check the latest Vercel deploy status and verify the live site reflects local HEAD
allowed-tools: Bash
---

Verify the latest deploy is healthy and the live site matches local HEAD.

**Steps:**

1. Show the last 3 deploys via `vercel ls`. Flag any non-Ready states.

2. Compare local git HEAD to what's deployed:
   - Get local HEAD short SHA: `git rev-parse --short HEAD`
   - If local HEAD differs from `origin/main`, note that local has unpushed commits.

3. Smoke-test the live site at https://www.justinfu.com:
   - `curl -sI` the homepage — confirm 200, capture `Last-Modified`, `Age`, `X-Vercel-Cache`.
   - For each page in `*.html` at the repo root, `curl -sI` and confirm 200.
   - For each `<img src="images/...">` referenced anywhere in `*.html`, HEAD-request the image — flag any non-200.

4. **Report** as a compact table:
   - Latest deploy state + age
   - Local vs origin (in sync / N commits ahead)
   - Pages checked / images checked / any failures listed explicitly

If the project is not linked to Vercel (no `.vercel/project.json`), say so and stop — don't fall back to GitHub Actions.
