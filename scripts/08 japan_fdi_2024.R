# Extract MOF's 2024 directional-principle FDI tables without losing signs.
# Run from the project root: source("scripts/08 japan_fdi_2024.R")
# Workbook downloaded on 2026-11-18 from:
# https://www.mof.go.jp/policy/international_policy/reference/balance_of_payments/revised/fdi2024.xlsx
library(readxl)
library(data.table)

input <- "data/08 fdi/mof_fdi2024.xlsx"
output <- "data/08 fdi/japan_fdi_by_country_industry_2024.csv"
industries <- c("Manufacturing (total)", "Food", "Textile", "Lumber and pulp",
                "Chemicals and pharmaceuticals", "Petroleum", "Rubber and leather",
                "Glass and ceramics", "Iron, non-ferrous, and metals", "General machinery",
                "Electric machinery", "Transportation equipment", "Precision machinery",
                "Non-manufacturing (total)", "Farming and forestry", "Fishery and marine products",
                "Mining", "Construction", "Transportation", "Communications",
                "Wholesale and retail", "Finance and insurance", "Real estate", "Services", "Total")
normalise <- function(x) trimws(gsub("[[:space:]]+", " ", as.character(x)))
country_names <- c("P.R.China" = "China", "R.Korea" = "South Korea", "Viet Nam" = "Vietnam",
                   "U.S.A." = "United States", "U.K." = "United Kingdom")
records <- list()
for (sheet_number in 1:4) {
  tab <- read_excel(input, sheet = as.character(sheet_number), col_names = FALSE,
                    .name_repair = "minimal")
  country_sheet <- sheet_number %in% c(3L, 4L)
  direction <- if (sheet_number %in% c(1L, 3L)) "Outward" else "Inward"
  header_row <- if (country_sheet) 11L else 13L
  columns <- if (country_sheet) 5:ncol(tab) else c(6L, 16L)
  for (label_row in seq_len(nrow(tab))) {
    labels <- normalise(unlist(tab[label_row, 1:4]))
    matched <- labels[!is.na(labels) & labels %in% industries]
    if (length(matched) != 1L) next
    industry <- sub(" \\(total\\)$", "", matched)
    value_row <- label_row - 1L
    for (column in columns) {
      destination <- normalise(tab[[column]][header_row])
      if (is.na(destination) || destination == "") next
      if (destination %in% names(country_names)) destination <- country_names[[destination]]
      raw_value <- normalise(tab[[column]][value_row])
      value <- suppressWarnings(as.numeric(raw_value))
      status <- if (is.finite(value)) "reported" else if (!is.na(raw_value) && raw_value == "X") {
        "confidential"
      } else if (!is.na(raw_value) && raw_value == ".") "no reports" else "missing"
      # Keep spreadsheet cell coordinates for every extracted observation.
      col_number <- column
      col_letters <- ""
      while (col_number > 0L) {
        col_letters <- paste0(LETTERS[(col_number - 1L) %% 26L + 1L], col_letters)
        col_number <- (col_number - 1L) %/% 26L
      }
      records[[length(records) + 1L]] <- data.table(
        year = 2024L, direction, destination, industry,
        value_100million_yen = value, status, source_value = raw_value,
        source_sheet = sheet_number, source_cell = paste0(col_letters, value_row)
      )
    }
  }
}
result <- rbindlist(records)
stopifnot(!anyDuplicated(result[, .(direction, destination, industry)]))
for (direction_name in c("Outward", "Inward")) {
  for (area in c("World", "ASEAN")) {
    values <- result[direction == direction_name & destination == area &
                       industry %in% c("Manufacturing", "Non-manufacturing", "Total")]
    stopifnot(nrow(values) == 3L, all(is.finite(values$value_100million_yen)),
              abs(values[industry == "Total", value_100million_yen] -
                    values[industry != "Total", sum(value_100million_yen)]) < 0.001)
  }
}
for (direction_name in c("Outward", "Inward")) {
  for (industry_name in c("Manufacturing", "Non-manufacturing", "Total")) {
    region <- result[direction == direction_name & destination == "ASEAN" & industry == industry_name]
    singapore <- result[direction == direction_name & destination == "Singapore" & industry == industry_name]
    stopifnot(nrow(region) == 1L, nrow(singapore) == 1L,
              is.finite(region$value_100million_yen), is.finite(singapore$value_100million_yen))
    derived <- copy(region)
    derived[, `:=`(destination = "ASEAN excl. Singapore",
                   value_100million_yen = region$value_100million_yen - singapore$value_100million_yen,
                   status = "derived", source_sheet = NA_integer_,
                   source_value = paste(region$source_value, "-", singapore$source_value),
                   source_cell = paste0(region$source_sheet, ":", region$source_cell,
                                        " - ", singapore$source_sheet, ":", singapore$source_cell))]
    result <- rbind(result, derived)
  }
}
fwrite(result, output, na = "")
cat("Saved", nrow(result), "observations to", output, "\n")
print(result[direction == "Inward" & industry == "Total" & status == "reported"
             ][order(-value_100million_yen)][1:12, .(destination, value_100million_yen)])
print(result[direction == "Inward" & destination == "World" & industry %in%
               c("Manufacturing", "Non-manufacturing", "Finance and insurance", "Communications",
                 "Services", "Electric machinery", "Transportation equipment", "Wholesale and retail", "Total"),
             .(industry, value_100million_yen)])
