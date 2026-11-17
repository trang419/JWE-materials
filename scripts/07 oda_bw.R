# Japan's bilateral ODA commitments by type and sector, in black and white.
# Run from the project root: Rscript "scripts/07 oda_bw.R"
# Or source this file in RStudio. The plot is also available as oda_bw_plot.
# Dependencies: install.packages(c("ggplot2", "ggpattern", "ragg"))
# Pattern API: https://coolbutuseless.github.io/package/ggpattern/

required_packages <- c("ggplot2", "ggpattern", "ragg")
missing_packages <- required_packages[!vapply(
  required_packages, requireNamespace, logical(1), quietly = TRUE
)]
if (length(missing_packages)) {
  stop("Install required packages first: ", paste(missing_packages, collapse = ", "))
}
library(ggplot2)
library(ggpattern)

# Locate the input from the working directory or this script's own location.
# This supports both Rscript and source(), without changing the working directory.
find_project_root <- function() {
  script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  source_paths <- as.character(unlist(lapply(sys.frames(), function(frame) frame$ofile)))
  candidates <- c(getwd(),
                  dirname(sub("^--file=", "", script_arg)),
                  dirname(source_paths))
  for (candidate in candidates) {
    candidate <- normalizePath(candidate, winslash = "/", mustWork = TRUE)
    repeat {
      if (file.exists(file.path(candidate, "data", "07 oda",
                                "ODA_modality_Japan_DAC.csv"))) return(candidate)
      parent <- dirname(candidate)
      if (identical(parent, candidate)) break
      candidate <- parent
    }
  }
  stop("Cannot find data/07 oda/ODA_modality_Japan_DAC.csv from this location.")
}

project_root <- find_project_root()
input_file <- file.path(project_root, "data", "07 oda", "ODA_modality_Japan_DAC.csv")
oda <- read.csv(input_file, check.names = FALSE, fileEncoding = "UTF-8")
japan_column <- "Japan (Bilateral ODA)"
stopifnot(all(c("Category", "Indicator", japan_column) %in% names(oda)))

# Grant (29%) is a subtotal of technical cooperation (11%) and grant-in-aid
# (18%). Use its components, not the subtotal, alongside loans (71%).
by_type <- oda[oda$Category == "ODA by types (%)" & oda$Indicator != "Grant", ]
by_sector <- oda[oda$Category == "ODA by sectors (%)", ]
stopifnot(nrow(by_type) == 3L, nrow(by_sector) == 8L)

plot_data <- rbind(
  data.frame(panel = "By type", category = by_type$Indicator,
             share = by_type[[japan_column]]),
  data.frame(panel = "By sector", category = by_sector$Indicator,
             share = by_sector[[japan_column]])
)
stopifnot(!anyDuplicated(plot_data[c("panel", "category")]),
          all(is.finite(plot_data$share)),
          all(plot_data$share >= 0 & plot_data$share <= 100))

# Each panel has distinct textures, including different hatch directions.
# Keep white backgrounds, black patterns and black outlines throughout.
plot_data$texture <- c(
  "stripe", "circle", "crosshatch",
  "stripe", "stripe", "crosshatch", "circle", "stripe", "weave", "crosshatch", "stripe"
)
plot_data$angle <- c(45, 0, 45, 45, 135, 45, 0, 0, 0, 0, 90)
plot_data$panel <- factor(plot_data$panel, levels = c("By type", "By sector"))
plot_data$category <- factor(plot_data$category, levels = rev(plot_data$category))

oda_bw_plot <- ggplot(plot_data, aes(x = share, y = category)) +
  geom_col_pattern(
    aes(pattern = texture, pattern_angle = angle),
    orientation = "y", width = 0.65,
    fill = "white", colour = "black", linewidth = 0.45,
    pattern_colour = "black", pattern_fill = "black",
    pattern_fill2 = "white", pattern_density = 0.22,
    pattern_spacing = 0.02, pattern_size = 0.3
  ) +
  geom_text(aes(label = paste0(share, "%")), hjust = -0.2, size = 5.5) +
  scale_pattern_identity() +
  scale_pattern_angle_identity() +
  scale_x_continuous(breaks = seq(0, 80, 20), limits = c(0, 80),
                     expand = expansion(mult = c(0, 0.01))) +
  scale_y_discrete(labels = function(x) vapply(
    x, function(label) paste(strwrap(label, width = 27), collapse = "\n"), character(1)
  )) +
  facet_wrap(~panel, nrow = 1, scales = "free_y") +
  labs(
    title = "Japan's bilateral ODA commitments",
    subtitle = "Aggregates during 1970-2020, based on 2020 prices",
    x = "Share (%)", y = NULL,
    caption = paste(
      "Source: Reproduced Table 2 in Nishitateno (2024), based on OECD.stat.",
      "Type: technical cooperation and grant-in-aid together form grants; the grant subtotal is excluded.",
      "Sector shares total 99% in the source; values are shown without normalization.",
      sep = "\n"
    )
  ) +
  theme_bw(base_size = 17, base_family = "sans") +
  theme(
    legend.position = "none",
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_line(colour = "grey85", linewidth = 0.3),
    strip.background = element_rect(fill = "white", colour = "black"),
    strip.text = element_text(face = "bold", size = 18),
    axis.text = element_text(colour = "black", size = 14),
    axis.ticks.y = element_blank(),
    panel.spacing = grid::unit(1.2, "cm"),
    plot.title = element_text(face = "bold", size = 24),
    plot.subtitle = element_text(size = 16),
    plot.caption = element_text(hjust = 0, size = 12, lineheight = 1.2),
    plot.margin = margin(14, 18, 14, 14)
  )

output_dir <- file.path(project_root, "slides", "image")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
png_file <- file.path(output_dir, "japan_oda_type_sector_bw.png")
ggsave(png_file, oda_bw_plot, device = ragg::agg_png,
       width = 14, height = 8, units = "in", dpi = 300, bg = "white")
if (interactive()) print(oda_bw_plot)
message("Saved: ", png_file)
