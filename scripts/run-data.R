args <- commandArgs(trailingOnly = TRUE)
walkthroughs <- c(
  madison = "scripts/data-madison.qmd",
  pwt = "scripts/data-pwt.qmd",
  wits = "scripts/data-wits.qmd"
)

if (length(args) != 3L || !args[1] %in% names(walkthroughs)) {
  stop("Usage from the repository root: Rscript scripts/run-data.R <madison|pwt|wits> <input-dir> <output-dir>",
       call. = FALSE)
}

walkthrough <- walkthroughs[[args[1]]]
if (!file.exists(walkthrough) || !dir.exists(args[2])) {
  stop("Run from the repository root and provide an existing input directory.", call. = FALSE)
}

dir.create(args[3], recursive = TRUE, showWarnings = FALSE)
Sys.setenv(
  JWE_RAW_DIR = normalizePath(args[2], winslash = "/", mustWork = TRUE),
  JWE_OUTPUT_DIR = normalizePath(args[3], winslash = "/", mustWork = TRUE)
)

# Execute the same transformation code students see in the walkthrough.
script <- tempfile(tmpdir = tempdir(), fileext = ".R")
invisible(knitr::purl(walkthrough, output = script, documentation = 0, quiet = TRUE))
source(script, encoding = "UTF-8")
