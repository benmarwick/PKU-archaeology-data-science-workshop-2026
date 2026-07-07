# extract_lesson_code.R
# Reads every lesson .R file in code/, keeps only executable R code lines
# (plus inline comments on the same line as code), adds a LESSON divider,
# and inserts blank lines between separate statements. Outputs live-demo-script.R.

lesson_files <- list.files(
  path       = "code",
  pattern    = "^[0-9]{2}-[0-9][_A-Za-z].*\\.R$",
  full.names = TRUE
)
lesson_files <- sort(lesson_files)
# exclude this script itself and placeholder files with no real code
lesson_files <- setdiff(lesson_files, c(
  "code/extract_lesson_code.R",
  "code/04-2_lesson.R"
))

# continuation operators: a line ending with one of these (optionally followed
# by an inline comment) is part of a multi-line block
continuation_re <- "\\|>\\s*(#.*)?$|\\+\\s*(#.*)?$|,\\s*(#.*)?$|\\(\\s*(#.*)?$|\\{\\s*(#.*)?$|%>%\\s*(#.*)?$"

output_lines <- character()

for (f in lesson_files) {
  lines <- readLines(f, warn = FALSE)

  # extract the LESSON divider line (e.g. "# LESSON: 01-1 (Intro)")
  divider <- grep("^#\\s*LESSON:", lines, value = TRUE)
  if (length(divider) > 0) {
    cleaned <- sub("^#\\s*", "", divider[1])
    cleaned <- gsub("\\s+", " ", trimws(cleaned))
    divider <- paste0("\n# ", cleaned)
  } else {
    divider <- paste0("\n# --- ", basename(f), " ---")
  }

  # keep lines that have code (not pure comment lines, not blank)
  code_lines <- lines[!grepl("^\\s*#", lines) & nchar(trimws(lines)) > 0]

  if (length(code_lines) == 0) next

  # insert blank lines between separate statements
  final <- character()
  for (i in seq_along(code_lines)) {
    if (i > 1) {
      prev_ends_block <- !grepl(continuation_re, code_lines[i - 1])
      # lines starting with +, ,, (, {, ), |>, or %>  are continuations
      curr_starts_stmt <- !grepl("^\\s*[+,({)]|^\\s*\\|>|^\\s*%>%", code_lines[i])
      both_library <- grepl("^\\s*library\\(", code_lines[i - 1]) && grepl("^\\s*library\\(", code_lines[i])
      if (prev_ends_block && curr_starts_stmt && !both_library) {
        final <- c(final, "")
      }
    }
    final <- c(final, code_lines[i])
  }

  output_lines <- c(output_lines, divider, "", final, "")
}

writeLines(output_lines, "code/live-demo-script.R")
message("Wrote live-demo-script.R with code from ", length(lesson_files), " lesson files")

suppressWarnings(source("code/live-demo-script.R"))
message("Ran live-demo-script.R to test it all works")

