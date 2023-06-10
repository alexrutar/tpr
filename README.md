# LaTeX Project Manager
TexProject is a LaTeX project manager that performs basic project templating and also includes other utilities for compiling and exporting your files in a well-defined way.

## Installation
If you have something like [fisher](https://github.com/jorgebucaran/fisher), you can
```
fisher install alexrutar/tpr
```
Otherwise, the function is in [functions/tpr.fish](functions/tpr.fish) and the completions are in [completions/tpr.fish](completions/tpr.fish) and you can just copy them to the relevant folders.

## Basic usage

### Dependencies
In order to use `tpr`, you need a few dependencies.

1. You need a somewhat recent [git](https://git-scm.com/) installation.
2. You need a somewhat recent [fd](https://github.com/sharkdp/fd) installation.
3. You need a working LaTeX distribution which supports `latexmk`.

If you want to use the `tpr remote` command, you need the following additional dependencies.
4. You need the [yq](https://github.com/mikefarah/yq) command.
5. You need the [github cli](https://cli.github.com/)
