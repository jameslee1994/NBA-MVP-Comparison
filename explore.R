# ============================================================================
# NBA MVP Explorer -- Shiny app
#
# An interactive companion to the Final Project script. Pick a stat, move
# the filter sliders (min GP, min MPG, age, career year), toggle which
# 2025-26 finalists you want highlighted, switch between regular season
# and playoff data, and watch the breakout chart + data table update live.
#
# HOW TO RUN:
#   1. Open this file in RStudio.
#   2. Click the "Run App" button at the top of the editor.
#      (Or, from an R console in this directory:
#         shiny::runApp("explore.R")
#       )
#   3. The app opens in a browser window.
#
# REQUIREMENTS:
#   - Have run the main script ("Final Project - NBA MVP Comparison.R") at
#     least once so the nba_cache.rds file exists. The app loads that
#     cached data at startup for fast launches.
#   - Packages: shiny, dplyr, ggplot2, scales, DT, plotly
#
# NOTE ON "AGE":
#   The raw dataset has no birthdate column, so "age" is APPROXIMATED from
#   draft year using era-specific norms (4-year college era -> 22 at
#   draft; 1990-2005 -> 20; one-and-done era -> 19). Treat it as a rough
#   proxy, not an exact age.
# ============================================================================

suppressPackageStartupMessages({
  library(shiny)
  library(dplyr)
  library(ggplot2)
  library(scales)
  library(DT)
  library(plotly)
})

# ---- Load cached data ------------------------------------------------------
cache_path <- "nba_cache.rds"
if (!file.exists(cache_path)) {
  stop("nba_cache.rds not found. Run the main analysis script first:\n",
       "  Rscript \"Final Project - NBA MVP Comparison.R\"")
}
cache <- readRDS(cache_path)

# Three variants of the player-season table, pre-built by the main script.
ps_rs  <- cache$ps_rs   # regular season only
ps_po  <- cache$ps_po   # playoffs only
ps_all <- cache$ps_all  # combined regular season + playoffs

candidates_full <- cache$candidates
candidate_names <- cache$candidate_names
mvp_means       <- cache$mvp_means
mvp_sds         <- cache$mvp_sds

# ---- Stat catalog ----------------------------------------------------------
stat_catalog <- list(
  "Points per game"    = list(col = "points",    fmt = function(x) sprintf("%.1f", x),
                              atc = NA,    atd = 0),
  "Assists per game"   = list(col = "assists",   fmt = function(x) sprintf("%.1f", x),
                              atc = NA,    atd = 0),
  "Rebounds per game"  = list(col = "rebounds",  fmt = function(x) sprintf("%.1f", x),
                              atc = NA,    atd = 0),
  "Steals per game"    = list(col = "steals",    fmt = function(x) sprintf("%.2f", x),
                              atc = NA,    atd = 0),
  "Blocks per game"    = list(col = "blocks",    fmt = function(x) sprintf("%.2f", x),
                              atc = NA,    atd = 0),
  "Field Goal %"       = list(col = "fg_pct",    fmt = function(x) sprintf(".%03d", round(x*1000)),
                              atc = "fga", atd = 8),
  "3-Point %"          = list(col = "three_pct", fmt = function(x) sprintf(".%03d", round(x*1000)),
                              atc = "tpa", atd = 3),
  "Free Throw %"       = list(col = "ft_pct",    fmt = function(x) sprintf(".%03d", round(x*1000)),
                              atc = "fta", atd = 2),
  "2-Point %"          = list(col = "two_pct",   fmt = function(x) sprintf(".%03d", round(x*1000)),
                              atc = "twoa",atd = 5),
  "All-Around Composite" = list(col = "__composite__",
                              fmt = function(x) sprintf("%+.2f", x),
                              atc = NA,    atd = 0)
)
stat_choices <- names(stat_catalog)

add_composite <- function(df) {
  df %>%
    mutate(
      z_points    = (points    - mvp_means$pts) / mvp_sds$pts,
      z_assists   = (assists   - mvp_means$ast) / mvp_sds$ast,
      z_rebounds  = (rebounds  - mvp_means$reb) / mvp_sds$reb,
      z_steals    = (steals    - mvp_means$stl) / mvp_sds$stl,
      z_blocks    = (blocks    - mvp_means$blk) / mvp_sds$blk,
      z_fg_pct    = (fg_pct    - mvp_means$fg)  / mvp_sds$fg,
      z_three_pct = (three_pct - mvp_means$tp)  / mvp_sds$tp,
      z_ft_pct    = (ft_pct    - mvp_means$ft)  / mvp_sds$ft,
      z_two_pct   = (two_pct   - mvp_means$two) / mvp_sds$two,
      `__composite__` = z_points + z_assists + z_rebounds + z_steals +
                        z_blocks + z_fg_pct + z_three_pct + z_ft_pct +
                        z_two_pct
    )
}

# Helper to pick the right season table based on the UI radio.
get_season_table <- function(game_type) {
  switch(game_type,
         "rs"       = ps_rs,
         "po"       = ps_po,
         "combined" = ps_all,
         ps_rs)
}

# ---- UI --------------------------------------------------------------------
ui <- fluidPage(
  titlePanel("NBA MVP Explorer — Per-Game Seasons (1946-2026)"),
  tags$p(style = "color:#555; margin-top:-10px;",
         "Pick a stat, move the sliders to change the fairness filters,",
         "and see how this season's MVP finalists stack up against the",
         "full history of NBA player-seasons."),

  sidebarLayout(
    sidebarPanel(
      width = 3,

      selectInput("stat", "Stat to rank on:",
                  choices = stat_choices,
                  selected = "Points per game"),

      sliderInput("top_n", "How many top seasons to show:",
                  min = 5, max = 30, value = 10, step = 1),

      tags$hr(),
      tags$b("Game type"),
      radioButtons("game_type", NULL,
                   choices = c("Regular Season" = "rs",
                               "Playoffs"       = "po",
                               "Combined (RS+PO)" = "combined"),
                   selected = "rs",
                   inline = FALSE),

      tags$hr(),
      tags$b("Fair-comparison filters"),
      tags$p(style = "font-size:11px; color:#777;",
             "Raise or lower these to see how the rankings change.",
             "Defaults mirror the main report (50 GP / 25 MPG). For",
             "playoffs, try lowering GP to 5-10."),

      sliderInput("min_gp",  "Minimum games played:",
                  min = 1, max = 82, value = 50, step = 1),
      sliderInput("min_mpg", "Minimum minutes per game:",
                  min = 0, max = 48, value = 25, step = 1),

      conditionalPanel(
        condition = "input.stat == 'Field Goal %' || input.stat == '3-Point %' ||
                     input.stat == 'Free Throw %' || input.stat == '2-Point %'",
        sliderInput("min_att", "Minimum per-game attempts:",
                    min = 0, max = 20, value = 3, step = 1)
      ),

      tags$hr(),
      tags$b("Age + career year"),
      tags$p(style = "font-size:11px; color:#777;",
             "Age is APPROXIMATE (derived from draftYear -- the dataset",
             "has no birthdate field). Career year = season - draftYear",
             "(rookie = year 1)."),
      sliderInput("age_range", "Approximate age range:",
                  min = 18, max = 45, value = c(18, 45), step = 1),
      sliderInput("year_range", "Career year range (Nth year in NBA):",
                  min = 1, max = 25, value = c(1, 25), step = 1),

      tags$hr(),
      checkboxGroupInput(
        "mvp_filter", "Show these seasons in the top list:",
        choices  = c("MVP-winning seasons" = "mvp",
                     "Non-MVP seasons"     = "non_mvp"),
        selected = c("mvp", "non_mvp")
      ),

      tags$hr(),
      tags$b("Finalists to include:"),
      checkboxGroupInput(
        "finalists", NULL,
        choices  = candidate_names,
        selected = candidate_names
      ),

      tags$hr(),
      tags$p(style = "font-size:11px; color:#888;",
             "Bars: blue = MVP season · grey = non-MVP · red = 2025-26",
             "finalist. Hover any bar for the full stat line.")
    ),

    mainPanel(
      width = 9,
      tabsetPanel(
        tabPanel("Breakout chart",
                 plotlyOutput("breakout_chart", height = "650px"),
                 tags$br(),
                 tags$p(style = "color:#666; font-size:12px;",
                        textOutput("candidate_rank_summary")),
                 tags$p(style = "color:#888; font-size:11px;",
                        textOutput("filter_summary"))),
        tabPanel("Data table",
                 tags$br(),
                 DTOutput("breakout_table")),
        tabPanel("About",
                 tags$br(),
                 tags$h4("About this explorer"),
                 tags$p("This app is a companion to the main MVP report.",
                        "It uses the same cleaned player-season tables and",
                        "the same fair-comparison filtering logic, plus",
                        "additional game-type / age / career-year filters",
                        "not in the report."),
                 tags$h4("Stats explained"),
                 tags$ul(
                   tags$li(tags$b("Volume stats"),
                           " (Points/Assists/Rebounds/Steals/Blocks): per-game",
                           " averages."),
                   tags$li(tags$b("Efficiency stats"),
                           " (FG% / 3P% / FT% / 2P%): average of per-game",
                           " shooting percentages."),
                   tags$li(tags$b("All-Around Composite"),
                           ": sum of z-scores across all 9 stats, each",
                           " measured against the historical MVP",
                           " distribution."),
                   tags$li(tags$b("Game type"),
                           ": pick regular season, playoffs, or both",
                           " combined. Note: playoffs are short (4-28",
                           " games) so you'll likely want to lower",
                           " Min GP to 5-10 in playoff mode.")
                 ),
                 tags$h4("Tips"),
                 tags$ul(
                   tags$li("Set Career Year = 1-1 to see the greatest",
                           " rookie seasons ever."),
                   tags$li("Set Age = 35-45 to see the best late-career",
                           " seasons (LeBron, Kareem, Stockton, Dirk)."),
                   tags$li("Switch to Playoffs, drop Min GP to 6, and",
                           " rank on Points per game to see the greatest",
                           " playoff scoring runs in history."),
                   tags$li("Flip off 'MVP-winning seasons' to find the",
                           " best seasons that never won MVP.")
                 ),
                 tags$h4("Data caveats"),
                 tags$ul(
                   tags$li("Approximate age is derived from draftYear",
                           " using era-specific norms (~22 pre-1990,",
                           " ~20 in 1990-2005, ~19 post-2006). Accurate",
                           " to within ~2 years."),
                   tags$li("Players without a recorded draftYear",
                           " (mostly undrafted or international signings)",
                           " will show NA for age and may be excluded",
                           " when the age filter is narrow."),
                   tags$li("Steals & blocks weren't tracked before 1974;",
                           " 3-point line was added in 1980. Early-era",
                           " rows will show 0 for those stats.")
                 ))
      )
    )
  )
)

# ---- Server ----------------------------------------------------------------
server <- function(input, output, session) {

  # Active season table based on game-type radio.
  active_table <- reactive({
    tab <- get_season_table(input$game_type)
    # For percentage stats, the mean of per-game percentages is still
    # meaningful. For pre-3PT-line seasons (three_pct = 0), filtering by
    # min_attempts correctly excludes them.
    tab
  })

  ranked_seasons <- reactive({
    info     <- stat_catalog[[input$stat]]
    stat_col <- info$col
    tab      <- active_table()

    base <- tab %>%
      filter(games_played >= input$min_gp,
             minutes      >= input$min_mpg,
             # Age filter: keep rows whose approx_age is in range OR is
             # NA (to not lose players without a draftYear when the
             # slider is at its full range). If the user narrows the
             # range, NA-age rows are excluded.
             (is.na(approx_age) & input$age_range[1] == 18 &
                input$age_range[2] == 45) |
               (approx_age >= input$age_range[1] &
                  approx_age <= input$age_range[2]),
             career_year >= input$year_range[1],
             career_year <= input$year_range[2])

    if (stat_col == "__composite__") {
      base <- base %>% add_composite() %>% filter(!is.na(.data[[stat_col]]))
    } else {
      base <- base %>% filter(!is.na(.data[[stat_col]]))
    }

    if (!is.na(info$atc) && info$atc %in% names(base) && input$min_att > 0) {
      base <- base %>%
        filter(!is.na(.data[[info$atc]]),
               .data[[info$atc]] >= input$min_att)
    }

    allowed_types <- character()
    if ("mvp"     %in% input$mvp_filter) allowed_types <- c(allowed_types, "mvp")
    if ("non_mvp" %in% input$mvp_filter) allowed_types <- c(allowed_types, "non_mvp")

    base %>%
      arrange(desc(.data[[stat_col]])) %>%
      mutate(all_time_rank = row_number(),
             season_type   = ifelse(is_mvp, "mvp", "non_mvp")) %>%
      filter(season_type %in% allowed_types) %>%
      mutate(stat_value = .data[[stat_col]])
  })

  # Candidates for the current filter state.
  #
  # Rather than always displaying each finalist's 2026 line, we pick
  # EACH FINALIST'S BEST-MATCHING SEASON under the current filter and
  # current ranking stat. That gives apples-to-apples comparisons:
  #   - Career Year = 1-1 -> shows each finalist's rookie year, so you
  #     can compare Jokic's rookie year to MJ's rookie year directly.
  #   - Age 28-30       -> shows each finalist's best age-28-to-30
  #     season.
  #   - No stage filter -> shows each finalist's best season ever on
  #     the selected stat.
  #
  # "Best" is defined as the highest value of the currently-selected
  # stat. For the all-around composite, that means the finalist's
  # highest career composite score that also passes the GP / MPG /
  # attempt / age / career-year filters.
  active_candidates <- reactive({
    info     <- stat_catalog[[input$stat]]
    stat_col <- info$col
    tab      <- active_table()

    pool <- tab %>%
      filter(player %in% input$finalists,
             games_played >= input$min_gp,
             minutes      >= input$min_mpg,
             (is.na(approx_age) & input$age_range[1] == 18 &
                input$age_range[2] == 45) |
               (approx_age >= input$age_range[1] &
                  approx_age <= input$age_range[2]),
             career_year >= input$year_range[1],
             career_year <= input$year_range[2])

    if (stat_col == "__composite__") {
      pool <- pool %>% add_composite() %>% filter(!is.na(.data[[stat_col]]))
    } else {
      pool <- pool %>% filter(!is.na(.data[[stat_col]]))
    }

    if (!is.na(info$atc) && info$atc %in% names(pool) && input$min_att > 0) {
      pool <- pool %>%
        filter(!is.na(.data[[info$atc]]),
               .data[[info$atc]] >= input$min_att)
    }

    # One row per finalist: their best matching season on this stat.
    pool %>%
      group_by(player) %>%
      arrange(desc(.data[[stat_col]]), .by_group = TRUE) %>%
      slice_head(n = 1) %>%
      ungroup()
  })

  chart_data <- reactive({
    ranked <- ranked_seasons()
    info   <- stat_catalog[[input$stat]]

    top_n <- ranked %>%
      slice_head(n = input$top_n) %>%
      transmute(entity = paste0(player, " (", season, ") — #", all_time_rank),
                value  = stat_value,
                type   = ifelse(is_mvp,
                                "Top N all-time (MVP season)",
                                "Top N all-time (non-MVP season)"),
                all_time_rank)

    cand_pool <- active_candidates()  # already has composite added if needed
    if (length(input$finalists) > 0 && nrow(cand_pool) > 0) {
      cand_rows <- cand_pool %>%
        mutate(
          stat_value = .data[[info$col]],
          all_time_rank = sapply(stat_value, function(v) {
            if (is.na(v)) return(NA_integer_)
            as.integer(sum(ranked$stat_value > v, na.rm = TRUE) + 1L)
          })
        ) %>%
        # Use the ACTUAL season that matched the filter (e.g. 2016 for
        # Jokic's rookie year when Career Year = 1-1 is set), not a
        # hardcoded 2026 -- that's the apples-to-apples view.
        transmute(entity = paste0(player, " (", season, ") — #", all_time_rank),
                  value  = stat_value,
                  type   = "2025-26 Finalist",
                  all_time_rank)
    } else {
      cand_rows <- tibble()
    }

    bind_rows(top_n, cand_rows) %>%
      group_by(entity) %>%
      arrange(desc(type == "2025-26 Finalist"), .by_group = TRUE) %>%
      slice_head(n = 1) %>%
      ungroup() %>%
      arrange(desc(value)) %>%
      mutate(entity = factor(entity, levels = rev(entity)),
             type   = factor(type, levels = c(
               "Top N all-time (MVP season)",
               "Top N all-time (non-MVP season)",
               "2025-26 Finalist")))
  })

  output$breakout_chart <- renderPlotly({
    info <- stat_catalog[[input$stat]]
    dat  <- chart_data()
    validate(need(nrow(dat) > 0,
                  "No seasons match the current filters. Try loosening them."))

    dat$label_text <- info$fmt(dat$value)
    dat$tooltip <- sprintf(
      "<b>%s</b><br>%s: %s<br>Rank under current filters: #%s",
      as.character(dat$entity), input$stat, dat$label_text,
      dat$all_time_rank
    )

    # Title is set via plotly::layout (below) rather than ggplot's labs(),
    # so we can position it cleanly and avoid the legend-overlap problem
    # that ggplotly's default title handling causes. Legend also moved
    # to the bottom for the same reason.
    chart_title <- sprintf("Top %d %s — %s",
                           input$top_n, input$stat,
                           switch(input$game_type,
                                  "rs" = "Regular Season",
                                  "po" = "Playoffs",
                                  "combined" = "Regular Season + Playoffs"))

    p <- ggplot(dat, aes(x = entity, y = value, fill = type,
                         text = tooltip)) +
      geom_col(width = 0.72) +
      coord_flip() +
      scale_fill_manual(values = c(
          "Top N all-time (MVP season)"     = "#1f77b4",
          "Top N all-time (non-MVP season)" = "#b0b0b0",
          "2025-26 Finalist"                = "#d62728"),
        name = NULL, drop = FALSE) +
      scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
      labs(x = NULL, y = input$stat) +
      theme_minimal(base_size = 12) +
      theme(legend.position = "bottom")

    ggplotly(p, tooltip = "text") %>%
      layout(
        title = list(
          text  = paste0("<b>", chart_title, "</b>"),
          x     = 0.02,
          xref  = "paper",
          xanchor = "left",
          y     = 0.97,
          font  = list(size = 15)
        ),
        legend = list(
          orientation = "h",
          x = 0.5, xanchor = "center",
          y = -0.12, yanchor = "top"
        ),
        margin = list(t = 60, b = 90, l = 10, r = 10)
      ) %>%
      config(displayModeBar = FALSE)
  })

  output$breakout_table <- renderDT({
    info <- stat_catalog[[input$stat]]
    dat  <- chart_data() %>% arrange(desc(value))
    dat$value_display <- info$fmt(dat$value)

    dat %>%
      transmute(Rank     = all_time_rank,
                Season   = as.character(entity),
                Category = as.character(type),
                `Value`  = value_display) %>%
      datatable(rownames = FALSE,
                options = list(pageLength = 15,
                               dom = 'tip',
                               columnDefs = list(list(className = 'dt-center',
                                                      targets = c(0, 3)))))
  })

  output$candidate_rank_summary <- renderText({
    if (length(input$finalists) == 0) return("")
    info   <- stat_catalog[[input$stat]]
    ranked <- ranked_seasons()
    shown  <- active_candidates() %>% pull(player)
    missing <- setdiff(input$finalists, shown)

    # Part 1: which finalists are on the chart and where they rank
    summary_part <- ""
    if (length(shown) > 0) {
      cand_pool <- active_candidates()
      ranks <- cand_pool %>%
        mutate(
          stat_value = .data[[info$col]],
          all_time_rank = sapply(stat_value, function(v) {
            if (is.na(v)) return(NA_integer_)
            as.integer(sum(ranked$stat_value > v, na.rm = TRUE) + 1L)
          })
        ) %>% arrange(all_time_rank)
      parts <- paste0(ranks$player, " ", ranks$season, " (#",
                      ranks$all_time_rank, ")")
      summary_part <- paste0(
        "Finalists shown (each finalist's best matching season): ",
        paste(parts, collapse = " · "))
    }

    # Part 2: which finalists got filtered out and give a hint why
    missing_part <- ""
    if (length(missing) > 0) {
      missing_part <- paste0(
        " — Hidden by filter: ", paste(missing, collapse = ", "),
        ". Try loosening Min MPG / Min GP / age / career-year sliders.")
    }

    paste0(summary_part, missing_part)
  })

  output$filter_summary <- renderText({
    paste0(
      "Filters: ",
      "Game type = ",
      switch(input$game_type,
             "rs" = "Regular Season",
             "po" = "Playoffs",
             "combined" = "Regular Season + Playoffs"),
      " · GP >= ", input$min_gp,
      " · MPG >= ", input$min_mpg,
      " · Age ", input$age_range[1], "-", input$age_range[2],
      " · Career year ", input$year_range[1], "-", input$year_range[2]
    )
  })
}

# ---- Launch ----------------------------------------------------------------
shinyApp(ui = ui, server = server)
