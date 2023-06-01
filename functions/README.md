# LaTeX Project Manager
## Installation
If you have something like [fisher](https://github.com/jorgebucaran/fisher), you can
```
fisher install alexrutar/tpr
```
Otherwise, the function is in [functions/tpr.fish](functions/tpr.fish) and the completions are in [completions/tpr.fish](completions/tpr.fish) and you can just copy them to the relevant folders.

### Dependencies
In order to use `tpr`, you need a few dependencies.

1. You need a somewhat recent [git](https://git-scm.com/) installation.
2. You need a working LaTeX distribution which supports `latexmk`.
3. You need the [yq](https://github.com/mikefarah/yq) command.
4. If you want to use the `tpr remote` command, you need the [github cli](https://cli.github.com/)
