function __tpr_FAIL --argument message
    set_color red
    echo -n "Error: " >&2
    set_color normal
    echo $message >&2
    return 1
end


function __tpr_missing_arg --argument arg_name
    __tpr_FAIL "Missing positional argument $arg_name."
    return 1
end


function __tpr_WARN --argument message
    set_color yellow
    echo -n "Warning: " >&2
    set_color normal
    echo $message >&2
end


function __tpr_main_tex --argument tpr_working_dir
    # get the main tex file, and ensure it exists and has the expected extension
    set --local main_tex_relative (path change-extension '' $tpr_working_dir/*.latexmain | head -n 1)
    set --local main_tex (path basename $main_tex_relative)
    set --local main_tex_extension (path extension $main_tex)

    if not test -f $main_tex_relative
        or not test "$main_tex_extension" = ".tex"
        __tpr_FAIL "no valid tex file specified with .latexmain"
        return 1
    end

    echo $main_tex
end


function __tpr_compile --argument texfile
    latexmk -pdf -interaction=nonstopmode -silent -Werror -file-line-error -cd $texfile >/dev/null
end


function __tpr_compile_force --argument texfile
    latexmk -pdf -f -interaction=nonstopmode -silent -cd $texfile >/dev/null
end


function __tpr_tar --description "create an uncompressed tarfile from `source_dir`" --argument source_dir tarfile
    if test -f "$source_dir/.gitignore"
        set --function ignore_file --ignore-file $source_dir/.gitignore
    end
    fd -H --exclude '.git' $ignore_file --base-directory $source_dir --exec-batch tar -rf $tarfile -C $source_dir
end


function __tpr_populate_tempdir --description "archive the current directory to a temporary tarfile" --argument temp_dir tpr_working_dir commit
    # get and validate main.tex
    set --local main_tex (__tpr_main_tex $tpr_working_dir)
    or return 1


    if test -n "$commit" >/dev/null
        # use `git archive` to dump to $tarfile if commit specified
        git -C $tpr_working_dir archive --format=tar $commit --output $temp_dir/source.tar
        or return 1
    else
        # otherwise, populate $tarfile with current contents
        __tpr_tar $tpr_working_dir $temp_dir/source.tar
        or return 1
    end

    # untar
    mkdir $temp_dir/source
    tar -xf $temp_dir/source.tar -C $temp_dir/source

    # check that archive was generated properly
    if not test -f "$temp_dir/source/$main_tex"
        __tpr_FAIL "failed to generate archive"
        return 1
    end

    # if so, return
    echo "$main_tex"
end


function __tpr_list_templates --argument template_directory
    path basename $template_directory/*
    or return 0
end


function tpr --description 'Manage LaTeX project repositories' --argument command
    set --local options (fish_opt --short=h --long=help)
    set --local options $options (fish_opt --short=v --long=version)
    set --local options $options (fish_opt --short=C --long=directory --required-val)

    argparse --stop-nonopt $options -- $argv
    or return 1

    set --function tpr_version 1.3

    # catch help and version flags
    if set --query _flag_help
        tpr_help
        return 0
    end

    if set --query _flag_version
        echo "tpr (version $tpr_version)"
        return 0
    end

    # set main directory locations
    if set --query XDG_DATA_HOME
        set --function tpr_data_dir $XDG_DATA_HOME/tpr
    else
        set --function tpr_data_dir $HOME/.local/share/tpr
    end

    if set --query XDG_CONFIG_HOME
        set --function tpr_config_dir $XDG_CONFIG_HOME/tpr
    else
        set --function tpr_config_dir $HOME/.config/tpr
    end

    if set --query _flag_directory
        set --function tpr_working_dir (path resolve $_flag_directory)
        if not test -d "$tpr_working_dir"
            __tpr_FAIL "Working directory '$_flag_directory' does not exist"
            return 1
        end
    else
        set --function tpr_working_dir (pwd)
    end

    mkdir --parents $tpr_data_dir
    mkdir --parents $tpr_config_dir

    set --function tpr_resource_dir $tpr_data_dir/resources
    set --function tpr_template_dir $tpr_data_dir/templates
    set --function tpr_config_file $tpr_config_dir/config.toml

    if test (count $argv) -eq 0
        tpr_help
        return 1
    end

    set --local temp_dir (mktemp --directory)
    and trap "rm -rf $temp_dir" INT TERM HUP EXIT


    set --local options (fish_opt --short=h --long=help)
    switch "$argv[1]"

        case template
            if not type -q copier
                __tpr_FAIL "Dependency `copier` missing: command `tpr template` not supported"
                return 1
            end

            # parse options and catch help
            argparse --name "tpr template" --stop-nonopt $options -- $argv[2..]
            or return 1

            if set --query _flag_help
                tpr_help template
                return 0
            end

            if test (count $argv) -eq 0
                tpr_help template
                return 1
            end


            switch $argv[1]
                case install
                    # parse options and catch help
                    argparse --name "tpr template install" --min-args 2 --max-args 2 $options -- $argv[2..]
                    or return 1

                    if set --query _flag_help
                        tpr_help template-install
                        return 0
                    end

                    set --local NAME $argv[1]
                    if not set --query NAME
                        __tpr_missing_arg NAME
                        return 1
                    end
                    set --local GIT $argv[2]
                    if not set --query GIT
                        __tpr_missing_arg GIT
                        return 1
                    end

                    # validate template name
                    set --local matched_name (string match --regex '[a-zA-Z0-9_\-]+' $NAME)

                    if not test "$matched_name" = "$NAME"
                        __tpr_FAIL "Invalid template name!"
                        return 1
                    end

                    if test -e "$tpr_template_dir/$NAME"
                        __tpr_FAIL "Template with name $NAME already installed!"
                        return 1
                    end

                    # install to directory
                    git clone $GIT "$tpr_template_dir/$NAME" >/dev/null


                case uninstall
                    # parse options and catch help
                    argparse --name "tpr template uninstall" --min-args 1 --max-args 1 $options -- $argv[2..]
                    or return 1

                    if set --query _flag_help
                        tpr_help template-uninstall
                        return 0
                    end

                    set --local NAME $argv[1]
                    if not set --query NAME
                        __tpr_missing_arg NAME
                        return 1
                    end

                    # validate template name
                    set --local matched_name (string match --regex '[a-zA-Z0-9_\-]+' $NAME)

                    if not test "$matched_name" = "$NAME"
                        __tpr_FAIL "Invalid template name!"
                        return 1
                    end

                    if test -e "$tpr_template_dir/$NAME"
                        rm -rf "$tpr_template_dir/$NAME"
                    end


                case update
                    # parse options and catch help
                    argparse --name "tpr template update" --max-args 0 $options -- $argv[2..]
                    or return 1

                    if set --query _flag_help
                        tpr_help template-update
                        return 0
                    end

                    for file in $tpr_template_dir/*
                        fish --command "git -C $file pull --force" &
                        set --append pid_list (jobs --last --pid)
                    end

                    wait $pid_list 2>/dev/null


                case list
                    # parse options and catch help
                    argparse --name "tpr template list" --max-args 0 $options -- $argv[2..]
                    or return 1

                    if set --query _flag_help
                        tpr_help template-list
                        return 0
                    end

                    __tpr_list_templates $tpr_template_dir


                case '*'
                    __tpr_FAIL "Unknown template subcommand: \"$argv[2]\""
                    return 1
            end


        case init
            if not type -q copier
                __tpr_FAIL "Dependency `copier` missing: command `tpr init` not supported"
                return 1
            end
            set --local options $options (fish_opt --short=F --long=force)
            argparse --name "tpr init" --min-args 1 --max-args 1 $options -- $argv[2..]
            or return 1

            if set --query _flag_help
                tpr_help init
                return 0
            end

            set --local TEMPLATE $argv[1]
            if test -z "$TEMPLATE"
                __tpr_missing_arg TEMPLATE
                return 1
            end

            set --function available_templates (__tpr_list_templates $tpr_template_dir)
            if not contains $TEMPLATE $available_templates
                __tpr_FAIL "Invalid template '$TEMPLATE'"
                return 1
            end

            copier copy $tpr_template_dir/$TEMPLATE $tpr_working_dir

            set --function first_commit_msg (yq '.first_commit_msg' $tpr_config_file)
            if test -z "$first_commit_msg"
                set --function init_msg first_commit_msg "Initialize new project repository"
            end

            # not a git directory: initialize new repository
            if not test -d $tpr_working_dir/.git
                git -C $tpr_working_dir init
                and git -C $tpr_working_dir add -A
                and git -C $tpr_working_dir commit -m "$first_commit_msg"

                set --local commit_file $tpr_resource_dir/pre-commit
                if test -f "$commit_file"
                    cp -i $commit_file $tpr_working_dir/.git/hooks/pre-commit
                end
            end


        case remote
            if not type -q yq
                and not type -q gh
                __tpr_FAIL "Dependencies `yq` and `gh` missing: command `tpr remote` not supported"
                return 1
            end

            argparse --name "tpr remote" --min-args 1 --max-args 1 $options -- $argv[2..]
            or return 1

            if set --query _flag_help
                tpr_help remote
                return 0
            end

            set --local REPONAME $argv[1]
            if test -z "$REPONAME"
                __tpr_missing_arg REPONAME
                return 1
            end


            if git -C $tpr_working_dir config --get remote.origin.url
                __tpr_FAIL "remote 'origin' already exists"
                return 1
            end

            set --function homepage (yq '.homepage' $tpr_config_file)
            if test -n "$homepage"
                set --function homepage_opt --homepage $homepage
            end

            set --function remote (yq '.remote' $tpr_config_file)
            if test -z "$homepage"
                set --function remote origin
            end


            gh repo create $REPONAME --remote $remote --source $tpr_working_dir --disable-issues --disable-wiki --private --push $homepage_opt


        case archive
            set --local options $options (fish_opt --short=I --long=include --multiple-vals)
            set --local options $options (fish_opt --short=b --long=bare)
            set --local options $options (fish_opt --short=r --long=reference --required-val)
            set --local options $options (fish_opt --short=f --long=force)
            set --local options $options (fish_opt --short=F --long=format --required-val)

            argparse --name "tpr archive" --min-args 1 --max-args 1 $options -- $argv[2..]
            or return 1

            if set --query _flag_help
                tpr_help archive
                return 0
            end

            if set --query _flag_format
                set --local allowed_formats gz tar dir
                set --function FORMAT $_flag_format
                if not contains $FORMAT $allowed_formats
                    __tpr_FAIL "invalid option for --format: $FORMAT"
                end
            else
                set --function FORMAT gz
            end

            set --function OUT $argv[1]
            if test -z "$OUT"
                __tpr_missing_arg OUT
                return 1
            end

            # if force, delete OUT
            # it is important to do this now in case the file is in the current directory
            # in which case the old version would be included in the archive
            if set --query _flag_force
                rm --recursive --force $OUT
            end

            set --local main_tex (__tpr_populate_tempdir $temp_dir $tpr_working_dir $_flag_reference)
            or return 1


            # if --bare: replace tarfile with modified contents
            if set --query _flag_bare
                if type -q arxiv_latex_cleaner
                    arxiv_latex_cleaner --keep_bib $temp_dir/source
                else
                    __tpr_WARN "Command `arxiv_latex_cleaner` not found: skipping some cleaning steps"
                    cp -r $temp_dir/source $temp_dir/source_arXiv
                end

                # delete all hidden files
                fd --hidden --regex "^\." --no-ignore $temp_dir/source_arXiv --exec-batch rm -rf

                set --local delete_endings \
                    aux bcf blg brf fdb_latexmk fls \
                    gz latexmain log run.xml tar thm toc toml \
                    yml yaml zip

                rm --force $temp_dir/source_arXiv/**/*.{$delete_endings}
                rm --force --recursive $temp_dir/source_arXiv/{.gitignore, .git, .github, .copier-answers.yml}

                rm --force $temp_dir/source.tar
                __tpr_tar $temp_dir/source_arXiv $temp_dir/source.tar
            end

            # include additional requested files
            if set --query _flag_include
                __tpr_compile_force "$temp_dir/source/$main_tex"
                or __tpr_WARN "Compilation failed: some files may not be included."

                for file_end in $_flag_include
                    set --local include_file (path change-extension $file_end $main_tex)
                    if test -f $temp_dir/source/$include_file
                        tar -rf $temp_dir/source.tar -C $temp_dir/source ./$include_file
                    else
                        __tpr_WARN "File '$include_file' was not generated before or during compilation."
                    end
                end
            end

            # compress tarfile and export
            switch $FORMAT
                case gz
                    gzip -9 $temp_dir/source.tar
                    and mv --interactive $temp_dir/source.tar.gz $OUT

                case tar
                    mv --interactive $temp_dir/source.tar $OUT

                case dir
                    if test -e $OUT
                        __tpr_FAIL "File or directory '$OUT' already exists. Override with --force."
                    end
                    mkdir --parents $OUT
                    and tar -xf $temp_dir/source.tar -C $OUT
            end


        case diff
            argparse --name "tpr diff" --min-args 2 --max-args 3 $options -- $argv[2..]
            or return 1

            if set --query _flag_help
                tpr_help diff
                return 0
            end

            set --function PDF $argv[1]
            if test -z "$PDF"
                __tpr_missing_arg PDF
                return 1
            end
            set --function COMMIT $argv[2]
            if not set --query COMMIT
                __tpr_missing_arg COMMIT
                return 1
            end
            set --function REV $argv[3]

            set --local main_tex (__tpr_populate_tempdir $temp_dir $tpr_working_dir $REV)
            or return 1

            set --local diff_tex (path change-extension '' $temp_dir/source/$main_tex)-diff.tex

            if latexdiff (git show $COMMIT:$main_tex | psub) $main_tex >$diff_tex
                and __tpr_compile_force $diff_tex
                mv -i (path change-extension pdf $diff_tex) $PDF
            else
                __tpr_FAIL "Failed to compile diff file"
                return 1
            end


        case validate
            set --local options $options (fish_opt --short=r --long=reference --required-val)
            argparse --name "tpr validate" --max-args 0 $options -- $argv[2..]
            or return 1

            if set --query _flag_help
                tpr_help validate
                return 0
            end

            set --local main_tex (__tpr_populate_tempdir $temp_dir $tpr_working_dir $_flag_reference)
            or return 1

            __tpr_compile "$temp_dir/source/$main_tex"


        case compile
            set --local options $options (fish_opt --short=F --long=format --required-val)
            set --local options $options (fish_opt --short=f --long=force)
            set --local options $options (fish_opt --short=r --long=reference --required-val)
            argparse --name "tpr compile" --max-args 1 $options -- $argv[2..]
            or return 1
            if set --query _flag_help
                tpr_help compile
                return 0
            end


            if set --query _flag_format
                set --function FORMAT $_flag_format
            else
                set --function FORMAT pdf
            end

            set --local OUT $argv[1]
            if test -z "$OUT"
                __tpr_missing_arg OUT
                return 1
            end

            set --local main_tex (__tpr_populate_tempdir $temp_dir $tpr_working_dir $_flag_reference)
            or return 1

            if not __tpr_compile "$temp_dir/source/$main_tex"
                __tpr_FAIL "Failed to compile project."
                return 1
            end

            if set --query _flag_force
                set --function mv_flags --force
            else
                set --function mv_flags --interactive
            end

            if not mv $mv_flags (path change-extension $FORMAT $temp_dir/source/$main_tex 2> /dev/null) $OUT
                __tpr_FAIL "Failed to obtain file '$(path change-extension $FORMAT $main_tex)' after compilation."
                return 1
            end


        case snap
            if not type -q yq
                __tpr_FAIL "Dependency `yq` missing: command `tpr snap` not supported"
                return 1
            end

            argparse --name "tpr snap" $options -- $argv[2..]
            or return 1

            if set --query _flag_help
                tpr_help snap
                return 0
            end

            set --local FIGURES $argv
            if test (count $FIGURES) -eq 0
                __tpr_missing_arg FIGURE
                return 1
            end

            set --local snap_preamble (yq '.snap_preamble' "$tpr_config_file")
            if test -z "$snap_preamble"
                __tpr_FAIL "Configuration value 'snap_preamble' is empty."
                return 1
            end

            set --local latex_search_path "$tpr_working_dir//:"
            set --local figure_index 0
            for FIGURE in $FIGURES
                set figure_index (math $figure_index + 1)

                if path is -a "$FIGURE"
                    set --function figure_file (path resolve "$FIGURE")
                else
                    set --function figure_file (path resolve "$tpr_working_dir/$FIGURE")
                end

                if not test -f "$figure_file"
                    __tpr_FAIL "Figure file '$FIGURE' does not exist."
                    return 1
                end

                if not test (path extension "$figure_file") = .tex
                    __tpr_FAIL "Figure file '$FIGURE' is not a .tex file."
                    return 1
                end

                set --local snap_source "$temp_dir/snap-$figure_index.tex"
                printf '%s\n' \
                    '\documentclass{standalone}' \
                    '\usepackage{amsmath,amssymb,amsfonts}' \
                    '\usepackage{tikz,pgfplots}' \
                    '\usetikzlibrary{intersections,positioning,cd,calc,bending}' \
                    '\usetikzlibrary{decorations.markings,shapes}' \
                    '\usetikzlibrary{arrows,arrows.meta}' \
                    '\usetikzlibrary{patterns}' \
                    $snap_preamble \
                    '\begin{document}' \
                    "\\input{$figure_file}" \
                    '\end{document}' >$snap_source

                if not env TEXINPUTS="$latex_search_path" latexmk -pdf -interaction=nonstopmode -silent -Werror -file-line-error -outdir="$temp_dir" "$snap_source" >/dev/null
                    __tpr_FAIL "Failed to compile figure '$FIGURE'."
                    return 1
                end

                set --local output_file (path change-extension pdf "$figure_file")
                if not mv -f "$temp_dir/snap-$figure_index.pdf" "$output_file"
                    __tpr_FAIL "Failed to write figure PDF '$output_file'."
                    return 1
                end
            end


        case update
            argparse --name "tpr update" --max-args 0 $options -- $argv[2..]
            or return 1

            if set --query _flag_help
                tpr_help update
                return 0
            end

            copier update $tpr_working_dir


        case '*'
            __tpr_FAIL "Unknown command: '$argv[1]'"
            return 1
    end
end
