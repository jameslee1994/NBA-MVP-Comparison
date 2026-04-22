# Video Presentation Script (4–5 minutes)

**Target length:** 4 min 30 sec (gives you ~30 seconds of buffer either way).
**Setup before recording:** RStudio open with `Final Project - NBA MVP Comparison.R` visible. Have these images bookmarked / open in tabs so you can switch to them quickly:
- `plots/01_finalists_vs_mvp_average.png`
- `plots/04_all_around_radar.png`

**Tip:** Read this script through twice out loud before recording. Highlight the words you trip on. Time yourself — 4:30 is the goal.

---

## Section 1 — Introduction (≈ 30 seconds)

> "Hi, I'm Jim. For my final project I analyzed the 2025-26 NBA MVP race using R. The dataset I used is the *Historical NBA Data and Player Box Scores* dataset from Kaggle — about **1.7 million game-level rows** going back to **1946** and updated through this current season. My goal was to use the data to answer: **statistically, who has the strongest case for the 2025-26 NBA MVP?** I focused on the four real finalists this year — **Nikola Jokić, Shai Gilgeous-Alexander, Luka Dončić, and Victor Wembanyama** — and I compared them against every previous MVP winner since 1984, including Michael Jordan."

🟢 **Rubric items hit:** Introduction (5 pts).

---

## Section 2 — Data Cleaning + R operations (≈ 1 minute)

**[Switch screen to RStudio, scroll to the cleaning section of your `.R` file]**

> "The raw file had a few issues I had to clean. First, R's CSV reader misclassified some numeric columns as text where stray non-numeric values appeared deep in the file, so I forced everything to numeric with `as.numeric()`. Second, I dropped rows with NA or zero minutes — those are 'Did Not Play' entries that would skew per-game averages. Third, I de-duplicated on player and game date as a safety check. And fourth, I added a fair-comparison filter that requires at least 50 games played and 25 minutes per game, which screens out specialists who posted big per-game numbers in 18-minute roles."

**[Scroll down to the dplyr section]**

> "For data manipulation I used **five `dplyr` operations** — the rubric only required two:
> - `filter` for the role threshold and to keep only Regular Season games,
> - `mutate` to derive the player name and the season label,
> - `group_by` and `summarise` to collapse 1.25 million game rows into about 7,000 player-season averages,
> - `select` to reorder columns,
> - and `arrange` to sort by season and points.
>
> The big one is `group_by` plus `summarise`. That's what turned a million-row box-score file into a player-season table I could actually analyze."

🟢 **Rubric items hit:** Data Cleaning (5 pts), Process Explanation (10 pts — 5 operations explained, way past the required 2).

---

## Section 3 — Statistical Analysis (≈ 1 minute)

**[Scroll to the descriptive stats section]**

> "For descriptive statistics I computed the **mean, median, and standard deviation** of every key per-game stat across every MVP-winning season since 1984. The typical MVP scored about **27.3 points per game**, with a standard deviation of about **4.5 points**. That gives me a baseline distribution to compare this year's finalists against."

**[Scroll to the t-test]**

> "For the hypothesis test I ran a **one-sample t-test** asking: is the finalists' scoring statistically different from the historical MVP mean? My null hypothesis was that the means are equal. I got **t = 1.08, p = 0.358** — far above the 0.05 threshold — which means I cannot reject the null. So even though Luka, SGA, Jokić, and Wemby are all great players, statistically their scoring is indistinguishable from a typical MVP. That's actually exactly what you'd expect for a real MVP race."

**[Scroll to the linear regression]**

> "For the linear regression I modeled **points-per-game as a function of minutes, assists, rebounds, and FG%** using `lm()`, fit on every MVP season since 1984. The R-squared came out to **only 0.22** — which is itself the finding: once you've already filtered down to MVP-caliber players, traditional box-score stats only weakly predict who scores more. When I used the model to predict each finalist's expected scoring, **Luka over-produces by 6.2 points per game** relative to his other stats — he creates shots the model doesn't expect. By contrast Wembanyama actually under-produces by 4.4 points — his MVP case is built on defense, not scoring."

🟢 **Rubric items hit:** Statistical Analysis (Part 1: 7 pts; Part 2: counts toward Process Explanation).

---

## Section 4 — Visualizations (≈ 1 min 15 sec)

**[Open Visualization 1 — `01_finalists_vs_mvp_average.png`]**

> "My first visualization is a **grouped bar chart** comparing each finalist to the historical MVP average across four core stats. I built it with `ggplot2` using `geom_col` and `position_dodge`. The takeaway is that **Jokić beats the historical MVP average in every single category** — points, assists, rebounds, and field-goal percentage. Luka and SGA out-score the average MVP but trail in rebounds. Wemby leads in rebounds but is below average on scoring."

**[Open Visualization 2 — `04_all_around_radar.png`]**

> "My second visualization is a **radar chart** built with the `fmsb` package. Each axis is a percentile rank within the historical MVP-season distribution — so a player who fills the chart is producing above-MVP across the board. The takeaway is the *shape*. **Jokić's green polygon encloses the most area** — he's the most all-around finalist. **Wembanyama's purple polygon is maxed out on Blocks** but pinches on Assists — his MVP case is purely defensive. SGA's polygon is tilted toward shooting efficiency; Luka's bulges toward scoring volume. Each finalist literally has a different geometric shape — a different *kind* of MVP case."

🟢 **Rubric items hit:** Data Visualization (Part 1: 7 pts), Interpret Visualizations (Part 2: 10 pts — interpretation is about *meaning*, not just description). The script also produces two more visualizations — a scoring-vs-efficiency scatter and an MVP timeline — which are in the README but I'm not walking through them here in the interest of time.

---

## Section 5 — Reflection + Next Steps (≈ 45 seconds)

> "**One thing that went well:** I built the analysis as a reusable pipeline — clean, aggregate, compare. So when I wanted to add a new stat or add Wembanyama as a fourth finalist or tighten the games-played filter, none of it required rewriting the upstream code. That made iterating fast.
>
> **One challenge:** The NBA tracked different stats in different eras — blocks and steals only since 1974, the three-point line only since 1980 — and player names sometimes appear with accented characters that broke my joins. So I had to limit the comparison to MVPs since 1984 to keep stat coverage consistent, and transliterate names like 'Luka Dončić' to ASCII before joining. An earlier version silently dropped rows in the regression and gave me garbage output — a good reminder to check for NAs before trusting model results.
>
> **If I continued this project, two next steps:** First, I'd extend the analysis to playoff games and ask the classic 'clutch MVP' question — does each candidate carry over their regular-season production into the playoffs? Second, I'd cumulate stats over a player's full career to build an era-adjusted GOAT ranking — basically the same methodology applied to careers instead of single seasons.
>
> Thanks for watching."

🟢 **Rubric items hit:** Project Reflection (5 pts — challenge ✓, learning ✓, two continuation ideas ✓).

---

## Final timing check

| Section                               | Target time |
|---------------------------------------|-------------|
| 1. Introduction                       | 0:30        |
| 2. Cleaning + dplyr operations        | 1:00        |
| 3. Stats: descriptive + t-test + lm   | 1:00        |
| 4. Two visualizations                 | 1:15        |
| 5. Reflection + next steps            | 0:45        |
| **Total**                             | **4:30**    |

If you go over 5 minutes, drop one of the dplyr operations from section 2 (mention 4 instead of 5) and shorten the regression explanation in section 3.

## Recording checklist

- [ ] Camera on, face clearly visible, decent lighting
- [ ] Mic test — say "test 1, 2, 3" and play it back
- [ ] Screen-share permission granted to your recording tool
- [ ] RStudio open with the script visible, font size big enough to read on video (16pt+)
- [ ] Plot images bookmarked / open in tabs for fast switching
- [ ] Glass of water nearby
- [ ] Close email / Slack / browser notifications
- [ ] Practice the script ONCE through, time yourself, then record on the second take
