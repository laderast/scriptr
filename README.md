# scriptr

`scriptr` is a Quarto extension that extracts code cells out of a rendered
`.qmd` document and saves them as standalone script files, using a
`filename` cell option to say where each one goes. It's meant for scripting
courses that want to maintain code as a single source of truth inside the
course notes, rather than keeping standalone scripts in sync by hand with
the versions embedded in the notes.

## Installing

Copy the `_extensions/scriptr` directory into your Quarto project (this is
the standard way to install a Quarto extension that hasn't been published
to a registry).

## Using scriptr

Enable the filter in `_quarto.yml`, or in the YAML front matter of an
individual document:

```yaml
filters:
  - scriptr
```

Tag any executable code cell you want extracted with a `filename` cell
option giving a project-relative path:

````
```{r}
#| filename: scripts/week1/my_script.R
print("hello")
```
````

Running `quarto render` as usual will create any missing intermediate
directories and write the cell's source to that path. Cells without a
`filename` option are left alone.

### Any language

scriptr is language- and engine-agnostic: it works for any executable cell
Quarto knows how to render, because Quarto normalizes every engine's cells
into the same internal shape before the filter runs. This has been verified
for the knitr engine (R, Bash, `sh`, `zsh`, Python, SQL, Ruby, Perl,
JavaScript/Node, CSS, …), the Jupyter engine (Python and other kernels),
and Quarto-native Observable JS (`ojs`). Extraction depends only on the cell
being echoed, not executed, so a tagged cell with `eval: false` is still
written out.

The only per-language wrinkle is the cell-option comment prefix, which
follows the language's own line-comment characters (a Quarto/knitr
convention, not something scriptr handles):

- `#|` — R, Python, Bash, and most languages
- `--|` — SQL, Lua, Haskell (comments start with `--`)
- `//|` — Observable JS, JavaScript, CSS (comments start with `//`)

````
```{sql}
--| filename: scripts/query.sql
SELECT * FROM students;
```
````

````
```{ojs}
//| filename: scripts/plot.js
data = [1, 2, 3]
```
````

## Examples

- `test.qmd` — R-only example, including a chunk with multiple auto-printed
  statements to exercise reassembly of a cell whose source knitr splits
  across several output blocks.
- `multi-language.qmd` — one R, Python, SQL, Bash, and Observable JS cell,
  each tagged with `filename`, alongside an untagged control cell per
  language to show they're left untouched. The `ojs` cell also exercises
  the `//|` comment prefix and the Quarto-native (non-knitr) engine.

## Running tests

```
tests/run-tests.sh
```

This renders each example above in an isolated temp directory and diffs the
extracted `scripts/` tree against the checked-in output in
`tests/expected/`. Pass one or more fixture names to run a subset, e.g.
`tests/run-tests.sh test`.

## How it works

Quarto's built-in `filename` cell option (normally used to show a filename
banner above a rendered code cell) is consumed into a `DecoratedCodeBlock`
custom AST node that only wraps the *first* source fragment of a cell —
when later top-level statements in the same cell auto-print output, knitr
splits the remaining source into separate sibling code blocks with no link
back to the `filename` value.

`_extensions/scriptr/scriptr.lua` handles this in two passes over the
document:

1. Record each `DecoratedCodeBlock`'s `filename` value, keyed by the node's
   internal id.
2. Walk each cell's enclosing `Div` (which still holds every source
   fragment, decorated or not) and reassemble the full original source in
   order, using the id to look up the `filename` that fragment belongs to.

The reassembled source is written out with
`pandoc.system.write_file`, creating parent directories as needed with
`pandoc.system.make_directory`.
