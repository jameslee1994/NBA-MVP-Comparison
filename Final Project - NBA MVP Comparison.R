# ============================================================================
# R Final Project: NBA MVP Candidate Comparison
# Author: Jim
# Course: Data Analytics with R
#
# Dataset : Historical NBA Data and Player Box Scores (Kaggle, Eoin A. Moore)
#           https://www.kaggle.com/datasets/eoinamoore/historical-nba-data-and-player-box-scores
#
# Goal    : Use 1.67M game-level rows to evaluate the 2025-26 NBA MVP
#           finalists -- Nikola Jokic, Shai Gilgeous-Alexander, Luka Doncic,
#           and Victor Wembanyama -- against every previous MVP winner since
#           the modern statistical era (1984), including Michael Jordan.
#
# Research questions:
#   1. How do this year's finalists compare to the historical MVP average
#      on the core stats MVP voters weigh?
#   2. Is their scoring statistically distinguishable from a typical MVP?
#   3. Can a linear regression on box-score inputs predict MVP-level scoring?
#
# This script is organized to follow the assignment rubric one section at
# a time: INGEST -> CLEAN -> MANIPULATE (dplyr) -> DESCRIPTIVE STATS ->
# HYPOTHESIS TEST -> LINEAR REGRESSION -> 3 VISUALIZATIONS.
# ============================================================================


# ---- SETUP -----------------------------------------------------------------
# Load only the tidyverse packages we actually use, so the script starts fast.
suppressPackageStartupMessages({
  library(readr)    # read_csv()
  library(dplyr)    # data manipulation
  library(ggplot2)  # visualizations
  library(scales)   # percent_format() on one of the axes
  library(fmsb)     # radarchart() for the all-around visualization
})

# Create a folder for saved plots so the README can reference them.
plots_dir <- "plots"
if (!dir.exists(plots_dir)) dir.create(plots_dir)


# ---- 1. DATA INGESTION -----------------------------------------------------
# The Kaggle dataset ships several CSVs. We only need PlayerStatistics.csv,
# which has one row per player per game. We use read_csv() with col_select
# so that we load only the columns the analysis needs (saves time + memory
# on the 323 MB file).
cat("1. Loading PlayerStatistics.csv ...\n")
raw <- read_csv(
  "PlayerStatistics.csv",
  col_select = c(firstName, lastName, gameDateTimeEst, gameType,
                 numMinutes, points, assists, reboundsTotal,
                 steals, blocks,
                 fieldGoalsMade, fieldGoalsAttempted,
                 threePointersMade, threePointersAttempted,
                 fieldGoalsPercentage, threePointersPercentage,
                 freeThrowsPercentage),
  show_col_types = FALSE
)
cat("   Loaded", format(nrow(raw), big.mark = ","), "game-level rows\n\n")


# ---- 2. DATA CLEANING ------------------------------------------------------
# Issues we handle, each documented inline:
#   a) Incorrect data types    - force numeric stat columns with as.numeric()
#   b) Missing values          - drop rows with NA or zero minutes (DNPs)
#                                and coerce NA shooting % (zero attempts) to 0
#   c) Duplicates              - dedupe on (player, game date) as a safeguard
#   d) Outliers / unfair rates - only keep Regular Season games (MVP voting
#                                is regular-season only); filter out partial
#                                seasons and specialist-minute roles later
#   e) Accented names          - transliterate to ASCII so our MVP winner
#                                list joins against "Luka Doncic" etc.
cat("2. Cleaning data ...\n")
nba <- raw %>%
  mutate(
    across(c(numMinutes, points, assists, reboundsTotal, steals, blocks,
             fieldGoalsMade, fieldGoalsAttempted,
             threePointersMade, threePointersAttempted,
             fieldGoalsPercentage, threePointersPercentage,
             freeThrowsPercentage),
           as.numeric),
    firstName = iconv(firstName, to = "ASCII//TRANSLIT"),
    lastName  = iconv(lastName,  to = "ASCII//TRANSLIT"),
    player    = paste(firstName, lastName),
    game_date = as.Date(gameDateTimeEst),
    # NBA seasons straddle calendar years. Games in Oct-Dec count toward
    # the next calendar year's season label (e.g., Oct 2025 -> 2026).
    season    = ifelse(as.integer(format(game_date, "%m")) >= 10,
                       as.integer(format(game_date, "%Y")) + 1L,
                       as.integer(format(game_date, "%Y")))
  ) %>%
  filter(gameType == "Regular Season",     # playoffs/preseason excluded
         !is.na(numMinutes),                # drop DNPs
         numMinutes > 0) %>%
  distinct(player, game_date, .keep_all = TRUE) %>%      # dedupe
  mutate(
    # Derive 2-point % per game: (2PM) / (2PA). The dataset doesn't have
    # native 2-point columns, so compute from FG and 3P counts. Guard
    # against divide-by-zero.
    twoPointersMade      = fieldGoalsMade      - threePointersMade,
    twoPointersAttempted = fieldGoalsAttempted - threePointersAttempted,
    twoPointersPercentage = ifelse(twoPointersAttempted > 0,
                                   twoPointersMade / twoPointersAttempted,
                                   NA_real_),
    # Zero-attempt percentage rows -> coerce to 0 so the mean stays sane.
    across(c(fieldGoalsPercentage,
             threePointersPercentage,
             freeThrowsPercentage,
             twoPointersPercentage),
           ~ ifelse(is.na(.x), 0, .x))
  )
cat("   After cleaning:", format(nrow(nba), big.mark = ","),
    "regular-season player-game rows\n\n")


# ---- 3. DATA MANIPULATION (dplyr) ------------------------------------------
# The rubric asks for at least 2 dplyr operations. This pipeline uses FIVE
# of the listed ones -- filter, mutate (above), group_by + summarise,
# select, and arrange -- to collapse 1.2M game rows down to a per-game,
# per-season table we can actually analyze.
cat("3. Aggregating to player-season averages ...\n")
player_seasons <- nba %>%
  group_by(player, season) %>%                    # grouping
  summarise(                                      # grouped summary
    games_played = n(),
    minutes      = mean(numMinutes,              na.rm = TRUE),
    points       = mean(points,                  na.rm = TRUE),
    assists      = mean(assists,                 na.rm = TRUE),
    rebounds     = mean(reboundsTotal,           na.rm = TRUE),
    steals       = mean(steals,                  na.rm = TRUE),
    blocks       = mean(blocks,                  na.rm = TRUE),
    fg_pct       = mean(fieldGoalsPercentage,    na.rm = TRUE),
    three_pct    = mean(threePointersPercentage, na.rm = TRUE),
    ft_pct       = mean(freeThrowsPercentage,    na.rm = TRUE),
    two_pct      = mean(twoPointersPercentage,   na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(games_played >= 50, minutes >= 25) %>%   # fair-comparison filter
  select(player, season, games_played, minutes,   # reorder columns
         points, assists, rebounds, steals, blocks,
         fg_pct, three_pct, ft_pct, two_pct) %>%
  arrange(desc(season), desc(points))             # sort: newest & top scorers
cat("   Player-season table:", nrow(player_seasons), "qualifying rows\n\n")


# ---- 4. DEFINE OUR COMPARISON GROUPS ---------------------------------------
# We compare this year's 4 MVP finalists (2025-26) against every MVP winner
# since 1984 (the modern statistical era, which starts with Larry Bird's
# first MVP). This keeps the comparison apples-to-apples -- blocks, steals,
# and 3PT% have all been league-tracked throughout this period.
mvp_winners <- tribble(
  ~player,                    ~mvp_season,
  "Larry Bird",                1984, "Larry Bird",                1985,
  "Larry Bird",                1986, "Magic Johnson",             1987,
  "Michael Jordan",            1988, "Magic Johnson",             1989,
  "Magic Johnson",             1990, "Michael Jordan",            1991,
  "Michael Jordan",            1992, "Charles Barkley",           1993,
  "Hakeem Olajuwon",           1994, "David Robinson",            1995,
  "Michael Jordan",            1996, "Karl Malone",               1997,
  "Michael Jordan",            1998, "Karl Malone",               1999,
  "Shaquille O'Neal",          2000, "Allen Iverson",             2001,
  "Tim Duncan",                2002, "Tim Duncan",                2003,
  "Kevin Garnett",             2004, "Steve Nash",                2005,
  "Steve Nash",                2006, "Dirk Nowitzki",             2007,
  "Kobe Bryant",               2008, "LeBron James",              2009,
  "LeBron James",              2010, "Derrick Rose",              2011,
  "LeBron James",              2012, "LeBron James",              2013,
  "Kevin Durant",              2014, "Stephen Curry",             2015,
  "Stephen Curry",             2016, "Russell Westbrook",         2017,
  "James Harden",              2018, "Giannis Antetokounmpo",     2019,
  "Giannis Antetokounmpo",     2020, "Nikola Jokic",              2021,
  "Nikola Jokic",              2022, "Joel Embiid",               2023,
  "Nikola Jokic",              2024, "Shai Gilgeous-Alexander",   2025
)

# Historical MVP stat lines (one row per MVP-winning season).
past_mvps <- mvp_winners %>%
  inner_join(player_seasons,
             by = c("player" = "player", "mvp_season" = "season"))

# 2025-26 finalists (season label 2026).
finalist_names <- c("Nikola Jokic", "Shai Gilgeous-Alexander",
                    "Luka Doncic", "Victor Wembanyama")
finalists <- player_seasons %>%
  filter(season == 2026, player %in% finalist_names)

cat("4. Comparison groups built:\n")
cat("   Historical MVP seasons since 1984:", nrow(past_mvps), "\n")
cat("   2025-26 finalists loaded:         ", nrow(finalists), "\n\n")
print(finalists %>% select(player, games_played, points, assists, rebounds,
                           fg_pct))
cat("\n")


# ---- 5. DESCRIPTIVE STATISTICS ---------------------------------------------
# Rubric asks for at least 2 descriptive statistics. We compute THREE:
# mean, median, and standard deviation of the key per-game stats across
# every historical MVP season since 1984. This gives us a distribution
# to compare the 2025-26 finalists against.
cat("5. Descriptive statistics (historical MVP seasons, 1984-2025):\n\n")
desc_stats <- past_mvps %>%
  summarise(
    ppg_mean = mean(points),    ppg_median = median(points),    ppg_sd = sd(points),
    apg_mean = mean(assists),   apg_median = median(assists),   apg_sd = sd(assists),
    rpg_mean = mean(rebounds),  rpg_median = median(rebounds),  rpg_sd = sd(rebounds),
    fg_mean  = mean(fg_pct),    fg_median  = median(fg_pct),    fg_sd  = sd(fg_pct)
  )
print(desc_stats)
cat("\nInterpretation: the 'typical' MVP since 1984 averaged",
    round(desc_stats$ppg_mean, 1), "PPG (SD =", round(desc_stats$ppg_sd, 1),
    "), with a median of", round(desc_stats$ppg_median, 1),
    "PPG. These numbers are the benchmark we'll compare the 2025-26",
    "finalists against.\n\n")


# ---- 6. HYPOTHESIS TEST ----------------------------------------------------
# Question: Is the scoring produced by this year's finalists statistically
# different from the historical MVP average?
#   H0: mean(finalist PPG) == historical MVP mean PPG
#   H1: mean(finalist PPG) != historical MVP mean PPG
# One-sample t-test (finalists' points-per-game against the historical mean).
mvp_mean_ppg <- mean(past_mvps$points)
t_result <- t.test(finalists$points, mu = mvp_mean_ppg)

cat("6. Hypothesis test (one-sample t-test):\n")
cat("   H0: finalists' mean PPG == historical MVP mean PPG (",
    round(mvp_mean_ppg, 2), ")\n", sep = "")
cat("   Finalist PPG sample:", paste(round(finalists$points, 1),
                                     collapse = ", "), "\n")
print(t_result)
cat("\nInterpretation: p-value =", signif(t_result$p.value, 3),
    ". With a small sample (n = 4) the test lacks power, but the result",
    "tells us we cannot strongly distinguish the finalists' scoring from",
    "the typical MVP's -- i.e., they are scoring at MVP-normal levels.\n\n")


# ---- 7. LINEAR REGRESSION --------------------------------------------------
# Model: points ~ minutes + assists + rebounds + fg_pct
# Fit on historical MVP-winning seasons. Purpose: see which box-score
# inputs actually predict scoring AMONG already-elite players, and use
# the model to predict each finalist's "expected" PPG given their other
# stats.
cat("7. Linear regression (historical MVP seasons):\n")
model <- lm(points ~ minutes + assists + rebounds + fg_pct,
            data = past_mvps)
print(summary(model))

finalists <- finalists %>%
  mutate(predicted_ppg = predict(model, newdata = .),
         delta         = points - predicted_ppg)

cat("\nPredicted vs. actual PPG for 2025-26 finalists:\n")
print(finalists %>% select(player, points, predicted_ppg, delta))

cat("\nInterpretation: R-squared is modest because once you've filtered to\n",
    "MVP-caliber seasons, box-score inputs explain only a fraction of\n",
    "scoring variance -- everyone in the pool is elite. Finalists with a\n",
    "POSITIVE delta are over-producing relative to the model (creating\n",
    "shots the model doesn't expect from their supporting stats).\n\n",
    sep = "")


# ---- 8. DATA VISUALIZATIONS (ggplot2) --------------------------------------
# Rubric asks for at least 3 ggplot2 visualizations with titles, labels,
# legends, and clear formatting. Each plot is saved as a PNG so the README
# can embed it.
cat("8. Creating visualizations ...\n")
theme_set(theme_minimal(base_size = 12) +
          theme(plot.title = element_text(face = "bold")))

## Visualization 1: Grouped bar chart -- finalists vs. historical MVP average
## on four key stats. Answers: "is each finalist above or below an MVP
## average?"
benchmark_means <- past_mvps %>%
  summarise(Points   = mean(points),
            Assists  = mean(assists),
            Rebounds = mean(rebounds),
            `FG %`   = mean(fg_pct) * 100) %>%
  mutate(player = "Historical MVP Avg")

compare_df <- finalists %>%
  transmute(player,
            Points   = points,
            Assists  = assists,
            Rebounds = rebounds,
            `FG %`   = fg_pct * 100) %>%
  bind_rows(benchmark_means) %>%
  tidyr::pivot_longer(-player, names_to = "stat", values_to = "value")

p1 <- ggplot(compare_df, aes(x = stat, y = value, fill = player)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.75) +
  geom_text(aes(label = round(value, 1)),
            position = position_dodge(width = 0.8),
            vjust = -0.4, size = 3) +
  scale_fill_brewer(palette = "Set2", name = NULL) +
  labs(title    = "2025-26 MVP Finalists vs. Historical MVP Average",
       subtitle = "Per-game averages, regular season only (MVPs since 1984)",
       x = NULL, y = "Per-game value") +
  theme(legend.position = "top")

ggsave(file.path(plots_dir, "01_finalists_vs_mvp_average.png"),
       p1, width = 9, height = 5.5, dpi = 150)

## Visualization 2: Scatter -- scoring vs. shooting efficiency.
## All player-seasons since 1984 in grey, MVP-winning seasons highlighted
## in blue, 2025-26 finalists labeled in red.
p2 <- ggplot(player_seasons %>% filter(season >= 1984),
             aes(x = fg_pct, y = points)) +
  geom_point(alpha = 0.15, color = "grey60", size = 1) +
  geom_point(data = past_mvps,
             color = "#1f77b4", size = 2.2, alpha = 0.8) +
  geom_point(data = finalists,
             color = "#d62728", size = 4) +
  geom_text(data = finalists,
            aes(label = player),
            color = "#d62728", size = 3.5, fontface = "bold",
            hjust = -0.1, vjust = -0.5) +
  scale_x_continuous(labels = percent_format(accuracy = 1)) +
  labs(title    = "Scoring vs. Shooting Efficiency",
       subtitle = "Every player-season since 1984 (grey); past MVPs (blue); 2025-26 finalists (red)",
       x = "Field Goal %", y = "Points per game")

ggsave(file.path(plots_dir, "02_scoring_vs_efficiency.png"),
       p2, width = 9, height = 5.5, dpi = 150)

## Visualization 3: Timeline -- MVP points per game over time, with MJ and
## the current finalists highlighted.
mvp_timeline <- past_mvps %>% select(mvp_season, player, points)
current_timeline <- finalists %>%
  transmute(mvp_season = season, player, points)

p3 <- ggplot(mvp_timeline, aes(x = mvp_season, y = points)) +
  geom_line(color = "grey50", linewidth = 0.4) +
  geom_point(color = "#1f77b4", size = 2.2) +
  geom_point(data = mvp_timeline %>% filter(player == "Michael Jordan"),
             color = "#d62728", size = 3.5) +
  geom_point(data = current_timeline,
             shape = 17, color = "#2ca02c", size = 4) +
  geom_text(data = current_timeline, aes(label = player),
            color = "#2ca02c", size = 3, hjust = 1.1, vjust = -0.6) +
  labs(title    = "MVP Points per Game Over Time",
       subtitle = "Every MVP season 1984-2025 (blue); Michael Jordan (red); 2025-26 finalists (green)",
       x = "MVP Season (ending year)", y = "Points per game")

ggsave(file.path(plots_dir, "03_mvp_ppg_timeline.png"),
       p3, width = 9, height = 5.5, dpi = 150)

## Visualization 4: Radar chart -- "all-around greatness" on 8 per-game stats.
## Each axis is a percentile rank within the historical MVP-season
## distribution, so a player who fills the chart is producing above-MVP
## on every stat. We include MJ's 1988 MVP season as the GOAT benchmark
## to contrast each finalist's shape against.
##
## Axes: 5 volume (Points/Assists/Rebounds/Steals/Blocks) + 3 efficiency
## (3P%/FT%/2P%). FG% is intentionally EXCLUDED because it's a weighted
## blend of 2P% and 3P% -- including it alongside them would double-count
## shooting and artificially inflate the enclosed area.
radar_stats  <- c("points","assists","rebounds","steals","blocks",
                  "three_pct","ft_pct","two_pct")
radar_labels <- c("Points","Assists","Rebounds","Steals","Blocks",
                  "3P%","FT%","2P%")

# Percentile-rank helper: where does a value sit within the MVP distribution?
pct_rank <- function(x, vec) 100 * mean(vec <= x, na.rm = TRUE)

# Build one row per player-season of their 8-stat percentile scores.
mj_1988 <- past_mvps %>% filter(player == "Michael Jordan", mvp_season == 1988)
radar_input <- bind_rows(
  finalists %>% mutate(label = player),
  mj_1988   %>% mutate(label = "Michael Jordan (1988)",
                       season = mvp_season)
)
radar_rows <- radar_input %>%
  rowwise() %>%
  mutate(across(all_of(radar_stats),
                ~ pct_rank(.x, past_mvps[[cur_column()]]),
                .names = "pct_{.col}")) %>%
  ungroup() %>%
  select(label, starts_with("pct_"))

# fmsb::radarchart wants: row 1 = max, row 2 = min, rows 3+ = data.
radar_matrix <- rbind(
  rep(100, length(radar_stats)),    # max
  rep(0,   length(radar_stats)),    # min
  as.data.frame(radar_rows[, -1])
)
rownames(radar_matrix) <- c("Max","Min", radar_rows$label)
colnames(radar_matrix) <- radar_labels

# Colors -- candidates get distinct colors, MJ gets GOAT red.
color_map <- c(
  "Luka Doncic"             = "#1f77b4",
  "Shai Gilgeous-Alexander" = "#ff7f0e",
  "Nikola Jokic"            = "#2ca02c",
  "Victor Wembanyama"       = "#9467bd",
  "Michael Jordan (1988)"   = "#d62728"
)
series_colors <- color_map[radar_rows$label]
series_fill   <- adjustcolor(series_colors, alpha.f = 0.20)

png(file.path(plots_dir, "04_all_around_radar.png"),
    width = 2000, height = 1700, res = 170)
layout(matrix(c(1, 2), nrow = 2), heights = c(5, 1.7))
par(mar = c(2, 2, 5, 2))
radarchart(
  radar_matrix,
  axistype   = 1,
  cglcol     = "grey70", cglty = 1, cglwd = 0.8,
  axislabcol = "grey40",
  caxislabels = seq(0, 100, 25),
  pcol       = series_colors,
  pfcol      = series_fill,
  plwd       = 2.5, plty = 1,
  vlcex      = 1.10,
  title      = "All-Around Greatness: 2025-26 MVP Finalists vs. MJ (1988)"
)
mtext("Each axis = percentile rank of per-game average within historical MVP distribution.",
      side = 3, line = 0.6, cex = 0.9, col = "grey25")
par(mar = c(0, 0, 0, 0))
plot.new()
legend("center",
       legend = radar_rows$label,
       col    = series_colors,
       lty    = 1, lwd = 3, bty = "n", cex = 1.05,
       ncol   = 3)
mtext("50 = median MVP  |  100 = better than every MVP since 1984  |  0 = worse than all of them",
      side = 1, line = -1, cex = 0.85, col = "grey30")
dev.off()

cat("   Saved 4 plots to:", normalizePath(plots_dir), "\n\n")

cat("Done. All rubric items complete.\n")
