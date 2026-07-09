# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

This repository currently contains only `spec.md` — no implementation exists yet. There is no build system, package manifest, source code, or test suite to run. When implementing `scriptr`, you are starting from scratch based on the spec below.

## What `scriptr` is

`scriptr` is a Quarto extension (a Lua filter) that extracts code blocks from a rendered `.qmd` document and saves them as standalone script files, using a `filename` attribute on the code block to determine the save path. The goal is to let a scripting course maintain code as a single source of truth inside the Quarto doc, rather than keeping standalone scripts in sync with the versions embedded in course materials.

Full behavior spec: see `spec.md`.

### Intended behavior

- Authors mark a code block for extraction with a `filename:` cell attribute giving a project-relative path, e.g.:
  ```{r}
  #| filename: scripts/week1/my_script.sh
  ```
- The extension is enabled per-project (or per-document) via `_quarto.yml`:
  ```yaml
  filters:
      - scriptr: true
  ```
- Running `quarto render` as usual should trigger the filter, which creates any missing intermediate directories and writes the code block's contents to the specified path.

## Architecture notes for implementation

Since this will be a Quarto extension, expect the conventional Quarto extension layout once code is added:
- `_extensions/<name>/_extension.yml` — extension manifest (name, version, contributes).
- `_extensions/<name>/*.lua` — the Lua filter implementing the `CodeBlock` (or `Div`) handler that reads the `filename` attribute from block attributes and writes the block's source text to disk.
- Quarto Lua filters run via Pandoc's Lua filtering API; the relevant hook is almost certainly a `CodeBlock` filter function that inspects `el.attributes.filename` (or the `#| filename:` cell-attribute equivalent parsed by Quarto) and performs a file write as a side effect, typically returning the block unmodified (or removed, depending on desired rendering behavior) after extraction.
- Directory creation for nested `filename` paths (e.g. `scripts/week1/...`) needs to be handled explicitly since Lua's `io` library does not create intermediate directories.

There are no commands to build, lint, or test yet — add them here once a package/test structure is introduced.

