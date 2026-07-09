## `scriptr`

`scriptr` is an quarto extension that will extract and save code blocks and use the `filename` attribute in the codeblock to save it within the project at the specified path.

It is meant to help in a scripting course to manage code blocks and scripts as a single source, rather than having to update scripts in multiple places.

## Setting up code blocks

Code blocks that you want to extract to individual script files should have the `filename:` attribute with a path and filename.

```{{r}}
#| filename: scripts/week1/my_script.sh
```

## Setting up `_quarto.yml`

In your `_quarto.yml` file, or in your individual scripts, add the following lines:

```
filters:
    - scriptr: true
```

## Using scriptr

In a quarto project, run scriptr by using `quarto render` as usual. The folder should create the folder (if it isn't yet created), and save the scripts under that filename.

## Language support

scriptr is language- and engine-agnostic. It extracts any executable cell carrying a `filename` option, regardless of which language or Quarto engine produced it, because Quarto normalizes every engine's cells into the same internal AST shape before the filter runs. This is verified for the knitr engine (R, Bash, `sh`, `zsh`, Python, SQL, Ruby, Perl, JavaScript/Node, CSS, …), the Jupyter engine (Python and other kernels), and Quarto-native Observable JS (`ojs`).

Extraction depends only on the cell being echoed into the rendered document, not on it being executed, so a tagged cell with `eval: false` is still written to its `filename`.

The `filename` option is written using the language's own cell-option comment prefix — `#|` for most languages, `--|` for SQL/Lua/Haskell, `//|` for Observable JS/JavaScript/CSS. This prefix is a Quarto/knitr convention that scriptr does not need to handle itself.