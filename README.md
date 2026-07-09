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

SQL cells use `--` for comments instead of `#`, so cell options there use a
`--|` prefix instead of `#|`:

````
```{sql}
--| filename: scripts/query.sql
SELECT * FROM students;
```
````

## Examples

- `test.qmd` — R-only example, including a chunk with multiple auto-printed
  statements to exercise reassembly of a cell whose source knitr splits
  across several output blocks.
- `multi-language.qmd` — one R, one Python, and one SQL cell, each tagged
  with `filename`, alongside an untagged control cell per language to show
  they're left untouched.

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
