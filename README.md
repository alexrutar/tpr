# LaTeX Project Manager
TexProject is a LaTeX project manager that performs basic project templating and also includes other utilities for compiling and exporting your files in a well-defined way.

Jump to:
- [Installation](#installation)
- [Dependencies](#dependencies)
- [Basic usage](#basic-usage)
- [Advanced features](#advanced-features)

## Installation
If you have something like [fisher](https://github.com/jorgebucaran/fisher), you can
```fish
fisher install alexrutar/tpr
```
Otherwise, the function is in [functions/tpr.fish](functions/tpr.fish) and the completions are in [completions/tpr.fish](completions/tpr.fish) and you can just copy them to the relevant folders.

### Dependencies
In order to use `tpr`, you need a few dependencies.

1. A working LaTeX distribution which supports `latexmk` (such as [TeX Live](https://tug.org/texlive/)).
2. [git](https://git-scm.com/), for managing version control.
3. [fd](https://github.com/sharkdp/fd), for basic file system management.

If you want to use the `tpr init` and `tpr template` commands, you need

4. [copier](https://copier.readthedocs.io/en/stable/), for template management.

If you want to use the `tpr remote` command, you need:

5. The [github cli](https://cli.github.com/), for managing remote repositories.
6. [yq](https://github.com/mikefarah/yq), for reading configuration files.

If you want to use the `tpr archive --bare` command, you may want the following additional dependency.

7. [arxiv_latex_cleaner](https://github.com/google-research/arxiv-latex-cleaner), for removal of comments and additional cleaning of export folder.

Visit the linked pages for precise installation instructions.

## Basic usage
### Initialization
In order to use `tpr`, we first need to install some templates.
We can use this [preprint template](https://github.com/rutar-academic/template-preprint).
Simply run
```fish
tpr template install preprint https://github.com/rutar-academic/template-preprint
```
This installs the template located at the URL `https://github.com/rutar-academic/template-preprint` under the name `preprint`.
You can install templates from any valid git URL or a local git repository.

List available templates with `tpr template list`.
Templates are installed in the directory `$XDG_DATA_HOME/tpr/templates`.

Now, create a new directory, change to it, and initialize:
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
This generates a file `out.pdf` in the current directory by compiling the file `<main>.tex` specified by `<main>.tex.latexmain`.
The compilation may take a while since it ignores any intermediate files already in the folder.

To export the project, run
```fish
tpr archive out.tar.gz
```
to create an archive file `out.tar.gz`.
You can include additional files in the archive with `-I` and strip unnecessary comments and unneeded files with `--bare`.
For example, to prepare files for submission to [arXiv](https://arxiv.org), one might run
```fish
tpr archive --bare -I bbl arxiv.tar.gz
```

### More help
Run
```fish
tpr --help
```
or
```fish
tpr $subcommand --help
```
for more information.

## Advanced features
### Compiling and exporting specific commits
Some commands, such as `tpr compile` or `tpr archive`, take an optional `COMMIT` argument.
This can be any git tree-ish reference, as accepted by `git archive`.
For instance, if you have a tag `v0.1`, you can run
```fish
tpr archive out.tar.gz v0.1
```
to create an export using the `v0.1` tag.

### Creating diff files
It is often useful to visualize changes between two versions of a `.tex` file.
A convenient tool for doing this is the [`latexdiff` script](https://ctan.org/pkg/latexdiff?lang=en).
The `tpr diff` tool provides a wrapper around `latexdiff` to automatically generate the diff file and compile it.
For example
```fish
tpr diff diff.pdf
```
creates a file `diff.pdf` showing changes between `HEAD` and the working tree.
Use `--staged` to compare staged changes instead.
Run `tpr diff --help` for more options.

Note that the PDF is compiled using the main file and supporting files from the newer snapshot.
This may cause compilation errors.

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
```fish
tpr template update
```
Uninstall template `$name` with
```fish
tpr template uninstall $name
```

### Writing your own templates
Templates for `tpr` are managed using [copier](https://copier.readthedocs.io/en/stable/).
A valid template is any copier template that contains a file at the root `<main>.tex` as well as an empty file `<main>.tex.latexmain`.
Of course, `<main>` can be anything you would like: the `.latexmain` file is used to determine the main TeX file in the current directory.

You can view my [preprint template](https://github.com/rutar-academic/template-preprint) for some quick-start information, and otherwise read the [copier documentation](https://copier.readthedocs.io/en/stable/) for more detail.

It is recommended that you include a reasonable `.gitignore` file which includes some common ignores for `.tex` files.
The [GitHub TeX Gitignore](https://github.com/github/gitignore/blob/main/TeX.gitignore) is a good starting point.
