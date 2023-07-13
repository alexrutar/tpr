# LaTeX Project Manager
TexProject is a LaTeX project manager that performs basic project templating and also includes other utilities for compiling and exporting your files in a well-defined way.

Jump to:
- [Installation](#installation)
- [Dependencies](#dependencies)
- [Basic usage](#basic-usage)

## Installation
If you have something like [fisher](https://github.com/jorgebucaran/fisher), you can
```fish
fisher install alexrutar/tpr
```
Otherwise, the function is in [functions/tpr.fish](functions/tpr.fish) and the completions are in [completions/tpr.fish](completions/tpr.fish) and you can just copy them to the relevant folders.

### Dependencies
In order to use `tpr`, you need a few dependencies.

1. You need a somewhat recent [git](https://git-scm.com/) installation.
2. You need a somewhat recent [fd](https://github.com/sharkdp/fd) installation.
3. You need a working LaTeX distribution which supports `latexmk`.
4. You need [copier](https://copier.readthedocs.io/en/stable/).

If you want to use the `tpr remote` command, you need the following additional dependencies.

5. You need the [yq](https://github.com/mikefarah/yq) command.
6. You need the [github cli](https://cli.github.com/)

## Basic usage
### Initialization
In order to use templates, we first need to install some templates.
We can use this [preprint template](https://github.com/rutar-academic/template-preprint).
Simply run
```fish
tpr install preprint https://github.com/rutar-academic/template-preprint
```
This installs the template located at the URL `https://github.com/rutar-academic/template-preprint` under the name `preprint`.
You can install templates from any valid git URL or a local git repository.

List available templates with `tpr list`
Templates are installed in the directory `$XDG_DATA_HOME/tpr/templates`.

Now, create a new directory, change to it, and initialize
```fish
mkdir my-project
cd my-project
tpr init preprint
```
This will copy a number of files to the current directory and initialize a git repository.

### Compilation and exports
To build a PDF file from the project, run
```fish
tpr compile out.pdf
```
This generates a file `out.pdf` in the current directory.
The compilation can take a while since it is compiled from scratch.

To export the project, run
```fish
tpr archive out.tar.gz
```
to create an archive file `out.tar.gz`.

### More help
Run
```fish
tpr help
```
or
```fish
tpr help <subcommand>
```
for more information.

## Advanced features
### Compiling and exporting specific commits
Some commands, such as `tpr compile` or `tpr archive`, take an optional `COMMIT` argument.
This can be any git tree-ish reference, as accepted by `git archive`.
For instance, if you have a tag `v0.1`, you can run
```
tpr archive out.tar.gz v0.1
```
to create an export using the `v0.1` tag.

### Remote repository management
You can create remote repositories on GitHub using the `tpr remote` subcommand.
Simply run with
```fish
tpr remote username/repo
```
to create a private GitHub repository at `https://github.com/username/repo`.

Note that `tpr remote` reads some default settings from `$XDG_CONFIG_HOME/tpr/config.toml`.

### Managing templates
You can update all existing templates with
```
tpr update
```
Uninstall template `<name>` with
```
tpr uninstall <name>
```


### Writing your own templates
Templates for `tpr` are managed using [copier](https://copier.readthedocs.io/en/stable/).
A valid template is any copier template that contains a file at the root `<main>.tex` as well as an empty file `<main>.tex.latexmain`.
Of course, `<main>` can be anything you would like: the `.latexmain` file is used to determine the main TeX file in the current directory.

You can view my [preprint template](https://github.com/rutar-academic/template-preprint) for some quick-start information, and otherwise read the [copier documentation](https://copier.readthedocs.io/en/stable/) for more detail.

It is recommended that you include a reasonable `.gitignore` file which includes some common ignores for `.tex` files.
The [GitHub TeX Gitignore](https://github.com/github/gitignore/blob/main/TeX.gitignore) is a good starting point.
