# Submission Checklist — Do These In Order

**Target completion: 1 hour from now.** Realistic time estimate per step.

---

## Step 1 — Push to GitHub (15 minutes)

You need a public GitHub repo. The submission for Part 1 is a link to that repo.

### 1a. Create the repo on github.com (2 min)

1. Go to <https://github.com/new>
2. Name it something like `nba-mvp-analysis-r-final` (or whatever you want)
3. **Public** visibility (graders need to see it)
4. **Do NOT** check "Add a README" or "Add .gitignore" — we already have those files
5. Click **Create repository**
6. **Leave the page open** — you'll need the commands GitHub shows you

### 1b. Initialize git locally and push (10 min)

Open a terminal in this folder (`NBA MVP Comparison`) and run:

```bash
git init
git add .gitignore README.md "Final Project - NBA MVP Comparison.R" plots/
git commit -m "Initial submission for R Final Project"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPO-NAME.git
git push -u origin main
```

**Replace** `YOUR-USERNAME/YOUR-REPO-NAME` with the values GitHub shows you. The exact two lines you need from GitHub are the `git remote add origin …` and `git push -u origin main` lines.

> **If `git push` complains about authentication:** GitHub no longer accepts password auth on the command line. Easiest fix: install GitHub Desktop (<https://desktop.github.com/>), open the existing folder in it, and click the "Publish repository" button. Same result, no auth headache.

> **If you accidentally include the big CSVs:** the `.gitignore` should prevent this, but if `git status` shows the giant `.csv` or `.parquet` files staged, run `git rm --cached *.csv *.parquet` and try the commit again. **A push that includes the 323 MB CSV will be rejected by GitHub.**

### 1c. Verify the push worked (3 min)

1. Refresh the GitHub page in your browser
2. Confirm you see: `README.md`, `Final Project - NBA MVP Comparison.R`, `plots/` folder, etc.
3. Click into `README.md` and confirm it renders nicely with embedded images
4. **Copy the repo URL** from your browser address bar — that's what you submit for Part 1.

---

## Step 2 — Submit Part 1 (2 minutes)

1. Open Canvas → Final Project Part 1 assignment
2. Paste your GitHub repo URL into the text entry box
3. Click **Submit**

**Done with Part 1.** ✅

---

## Step 3 — Record the video (25 minutes)

### 3a. Setup (5 min)

1. Open `PRESENTATION_SCRIPT.md` in a separate window — you'll read from it
2. Open RStudio with `Final Project - NBA MVP Comparison.R` visible. Bump font size up (Tools → Global Options → Appearance → Editor font size → 16+) so it reads clearly on video
3. Open these three plot images in browser tabs ready to switch to:
   - `plots/01_candidates_vs_mvp_average.png`
   - `plots/04_all_around_radar.png`
   - `plots/06_breakout_all_around.png`
4. Choose your recording tool. **Easiest options:**
   - **Loom** (<https://loom.com>) — free, records camera + screen, gives you a shareable link instantly
   - **Zoom** — start a meeting with just yourself, hit Record (saves locally as MP4), share screen
   - **QuickTime** (Mac) — File → New Screen Recording, but won't capture your camera as a webcam overlay
5. Test mic + camera. Say "test 1, 2, 3" — play it back, make sure audio is clear

### 3b. Practice run (8 min)

Read through the script once out loud, watching the timer. Goal: **4:30 ± 15 seconds.** If you're way over, trim Section 2 (drop dplyr operations from 5 to 3) and shorten the regression part of Section 3.

### 3c. Record (10 min — usually two takes)

1. Hit Record
2. Take a breath. Smile.
3. Read the script. **Look at the camera, not the script**, as much as you can. Slow down. Pause between sentences.
4. If you mess up a sentence, just stop, take a breath, and rewind to the start of that sentence — most editing tools let you trim out the dead time, or you can just leave the do-over in. Recruiters do this too — don't sweat one stumble.
5. Stop recording.
6. Watch it back at 1.5x speed. If audio is clear and you hit all the rubric items, **you're done**.

### 3d. If you do another take

If take 1 was bad — too long, too quiet, you skipped a section — just hit record again. Two takes is normal. Don't aim for perfect, aim for "clearly hits every rubric item in 4-5 minutes."

---

## Step 4 — Submit Part 2 (5 minutes)

### Option A — Upload directly to Canvas (preferred)

1. Open Canvas → Final Project Part 2 assignment
2. Click **Upload File** and select your `.mp4`
3. Wait for upload (large videos may take a few minutes)
4. Click **Submit**

### Option B — If file is too big for Canvas

1. Upload the `.mp4` to your **MTECH Google Drive**
2. Right-click the file → **Share** → **Change to anyone with the link**
3. Make sure the share scope is **Anyone at MTECH** (per the rubric)
4. Copy the link
5. In Canvas, click **Submit a website URL** and paste the link
6. Click **Submit**

**Done with Part 2.** ✅

---

## Final Checklist

Before you call it done:

- [ ] GitHub repo URL submitted to Canvas Part 1
- [ ] GitHub repo is **public** (anyone can view)
- [ ] README displays correctly with embedded images
- [ ] R script is in the repo and runs (you don't need to prove this; just verify the file is there)
- [ ] Video is **between 4:00 and 5:00** in length
- [ ] Video shows your face on camera
- [ ] Video shows your screen with R code + at least 2 visualizations
- [ ] Video covers: intro, cleaning, ≥2 dplyr ops, regression + t-test, ≥2 viz, reflection (challenge + learning + 2 next-steps)
- [ ] Video submitted to Canvas Part 2 (file or shareable link)

---

## Emergency Plan B (if something goes catastrophically wrong)

If GitHub push isn't working in time: zip the entire folder (excluding the large `.csv` and `.parquet` files), upload the zip to your MTECH Google Drive, share with MTECH-anyone, and submit the Drive link in the Canvas text box for Part 1 with a brief note explaining you couldn't get GitHub working in time. **Not ideal**, but better than missing the deadline.

If video isn't working in time: do an audio-only screen recording with QuickTime / OBS / Loom and submit that. The Presentation Skills rubric will dock you for no camera (4 pts instead of 10), but you'll get partial credit on every other rubric item. **Submit something rather than nothing.**

You've got this. 🚀
