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