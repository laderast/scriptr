# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What `scriptr` is

`scriptr` is a Quarto extension (a Lua filter) that extracts code cells out of a rendered `.qmd` document and saves them as standalone script files, using a `filename` cell option to determine the save path. The goal is to let a scripting course maintain code as a single source of truth inside the Quarto doc, rather than keeping standalone scripts in sync by hand with the versions embedded in course materials.

Full behavior spec: see `spec.md`. User-facing usage docs: see `README.md`.

## Commands

Render an example document (also extracts its tagged cells to `scripts/`):
```
quarto render test.qmd --to html
quarto render multi-language.qmd --to html
```

Run the integration test suite (all fixtures, or a subset by name):
```
tests/run-tests.sh
tests/run-tests.sh test
```

There is no separate build or lint step — `_extensions/scriptr/scriptr.lua` is the whole implementation and is loaded directly by Quarto at render time.

## Architecture

`_extensions/scriptr/scriptr.lua` is a Pandoc Lua filter. The one thing to understand before touching it: Quarto's built-in `filename` cell option (normally used to show a filename banner above a rendered code cell) does **not** survive into the AST as a plain attribute. Quarto consumes it into a custom AST node type, `DecoratedCodeBlock`, and that node only wraps the *first* source fragment of a cell. When a cell has multiple top-level statements that each auto-print output (common in R chunks), knitr splits the remaining source into separate sibling `CodeBlock`s in the enclosing cell `Div`, with no link back to the `filename` value.

The filter handles this with two sequential passes (two separate tables in the array returned from the script — Pandoc runs each as its own full-document walk, in order):

1. A `DecoratedCodeBlock` handler records each node's `filename`, keyed by the node's internal `__quarto_custom_id`.
2. A `Div` handler matches each `cell`-class `Div`, looks up whether its first child is a decorated node with a recorded `filename`, and if so walks *all* of that `Div`'s children (decorated wrapper and any plain sibling fragments alike) collecting every `cell-code` `CodeBlock`'s text in order, then writes the reassembled source to `filename`.

This reassembly step is why cells with multiple auto-printing statements still extract correctly — extracting only from inside the `DecoratedCodeBlock` node itself would silently truncate the file.

Directory creation and file writes use `pandoc.system.make_directory(dir, true)` and `pandoc.system.write_file`, not Lua's `io` library (which has no recursive mkdir).

The mechanism is language-agnostic: it has been verified working for R, Python, Bash, and SQL cells. SQL cells use `--` for comments, so their cell options need a `--|` prefix instead of `#|` — this is a Quarto/knitr convention, not something the filter has to handle.

## Test fixtures

`test.qmd` (R only, including a multi-statement chunk to exercise the reassembly logic) and `multi-language.qmd` (one tagged R/Python/SQL/Bash cell each, plus an untagged control cell per language) double as both human-readable usage examples and the fixtures `tests/run-tests.sh` renders and diffs against `tests/expected/<fixture>/`.

Mixing engines in one document is why some cells carry options that look unnecessary at first glance: any document containing an R chunk uses knitr as its master engine, and knitr's own `python` engine requires the R `reticulate` package unless a chunk sets `#| python.reticulate: false` (which instead shells out to a plain system `python`). This keeps the fixtures renderable without needing `reticulate` installed or a live database connection for the SQL example.

When `tests/expected/` needs regenerating after an intentional behavior change, render each fixture in an isolated temp directory (copy `_extensions/`, `_quarto.yml`, and the one `.qmd` file being tested — rendering fixtures in place at the repo root will pollute the working tree's own `scripts/`), then copy the resulting `scripts/` tree over the corresponding `tests/expected/<fixture>/` directory.
