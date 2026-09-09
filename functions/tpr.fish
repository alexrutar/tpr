function __tpr_FAIL --argument message
    begin
        set_color red
        echo -n 'Error: '
        set_color normal
        echo "$message"
    end >&2
    return 1
end

function __tpr_missing_arg --argument arg_name
    __tpr_FAIL "Missing positional argument $arg_name."
end

function __tpr_WARN --argument message
    begin
        set_color yellow
        echo -n 'Warning: '
        set_color normal
        echo "$message"
    end >&2
end

function __tpr_require
    for dependency in $argv
        if not type -q "$dependency"
            __tpr_FAIL "Dependency `$dependency` missing."
            return 1
        end
    end
end

function __tpr_config_get --argument config_file key default
    if not test -e "$config_file"
        printf '%s\n' "$default"
        return 0
    end

    __tpr_require yq
    or return 1
    set --local value (yq -r ".$key // \"\"" "$config_file")
    or return 1
    if test -n "$value"
        printf '%s\n' $value
    else
        printf '%s\n' "$default"
    end
end

function __tpr_main_tex --argument source_dir
    set --local markers "$source_dir"/*.latexmain
    if test (count $markers) -ne 1
        __tpr_FAIL 'Expected exactly one .latexmain file.'
        return 1
    end
    set --local main_tex (path change-extension '' -- "$markers[1]")
    if not test -f "$main_tex"; or test (path extension -- "$main_tex") != .tex
        __tpr_FAIL 'no valid tex file specified with .latexmain'
        return 1
    end
    path basename -- "$main_tex"
end

function __tpr_compile --argument texfile
    latexmk -pdf -interaction=nonstopmode -silent -Werror -file-line-error -cd "$texfile" >/dev/null
end

function __tpr_compile_force --argument texfile
    latexmk -pdf -f -interaction=nonstopmode -silent -cd "$texfile" >/dev/null
end

function __tpr_tar --argument source_dir tarfile
    # Exclude output/staging paths inside the source without deleting them first.
    set --local excludes --exclude .git
    set --local prefix "$source_dir/"
    for excluded_path in $argv[3..]
        if test (string sub --length (string length -- "$prefix") -- "$excluded_path") = "$prefix"
            set --local relative (string sub --start (math (string length -- "$prefix") + 1) -- "$excluded_path")
            set --append excludes --exclude "/$(string escape --style=regex -- "$relative")"
        end
    end

    # fd applies ignore rules; tar must not traverse the returned directories again.
    fd -H --no-require-git $excludes --base-directory "$source_dir" --print0 \
        | tar -cf "$tarfile" -C "$source_dir" --no-recursion --null -T -
    set --local results $pipestatus
    for result in $results
        if test "$result" -ne 0
            return 1
        end
    end
end

function __tpr_populate_tempdir --argument temp_dir working_dir commit
    if test -n "$commit"
        git -C "$working_dir" archive --format=tar --output "$temp_dir/source.tar" "$commit"
        or return 1
    else
        __tpr_tar "$working_dir" "$temp_dir/source.tar" "$temp_dir" $argv[4..]
        or return 1
    end

    mkdir "$temp_dir/source"
    and tar -xf "$temp_dir/source.tar" -C "$temp_dir/source"
    or return 1

    # Resolve metadata in the selected snapshot, including historical filenames.
    __tpr_main_tex "$temp_dir/source"
end

function __tpr_list_templates --argument template_directory
    path basename "$template_directory"/*/
    or return 0
end

function __tpr_populate_index --argument temp_dir working_dir
    # checkout-index silently skips unmerged entries; reject them explicitly.
    set --local unmerged (git -C "$working_dir" ls-files --unmerged -- :/)
    or return 1
    if test -n "$unmerged"
        __tpr_FAIL 'Cannot use --staged with unresolved merge conflicts.'
        return 1
    end
    set --local prefix (git -C "$working_dir" rev-parse --show-prefix)
    or return 1
    mkdir "$temp_dir/index"
    and git -C "$working_dir" checkout-index --all --ignore-skip-worktree-bits --prefix="$temp_dir/index/"
    or return 1
    # checkout-index retains the repository-relative prefix when using -C.
    command mv -- "$temp_dir/index/$prefix" "$temp_dir/source"
    or return 1
    __tpr_main_tex "$temp_dir/source"
end

function __tpr_with_tempdir --argument worker
    set --local temp_dir (mktemp -d)
    or return 1
    if not test -d "$temp_dir"
        __tpr_FAIL 'Failed to create temporary directory.'
        return 1
    end
    set temp_dir (path resolve -- "$temp_dir")

    $worker "$temp_dir" $argv[2..]
    set --local result $status
    command rm -rf -- "$temp_dir"
    if test $status -ne 0; and test "$result" -eq 0
        return 1
    end
    return "$result"
end

function __tpr_publish --argument source output force
    # Stage on the destination filesystem so replacement uses renames.
    set --local parent (path dirname -- "$output")
    mkdir -p -- "$parent"
    or return 1
    set --local staging (mktemp -d "$parent/.tpr-output.XXXXXXXXXX")
    or return 1
    if not command mv -- "$source" "$staging/new"
        command rm -rf -- "$staging"
        return 1
    end

    set --local had_output 0
    if test -e "$output"; or test -L "$output"
        if test -z "$force"
            __tpr_FAIL "File or directory '$output' already exists. Override with --force."
            command rm -rf -- "$staging"
            return 1
        end
        if not command mv -- "$output" "$staging/previous"
            command rm -rf -- "$staging"
            return 1
        end
        set had_output 1
    end

    if not command mv -- "$staging/new" "$output"
        if test "$had_output" -eq 1
            if not command mv -- "$staging/previous" "$output"
                __tpr_FAIL "Could not restore output; previous output is preserved at '$staging/previous'."
                return 1
            end
        end
        command rm -rf -- "$staging"
        return 1
    end
    command rm -rf -- "$staging"
end

function __tpr_archive --argument temp_dir working_dir output format force reference bare
    set --local includes $argv[8..]
    set --local main_tex (__tpr_populate_tempdir "$temp_dir" "$working_dir" "$reference" "$output")
    or return 1

    # Historical archives may also contain a previous output at this path.
    set --local prefix "$working_dir/"
    if test (string sub --length (string length -- "$prefix") -- "$output") = "$prefix"
        set --local relative (string sub --start (math (string length -- "$prefix") + 1) -- "$output")
        if test -e "$temp_dir/source/$relative"; or test -L "$temp_dir/source/$relative"
            command rm -rf -- "$temp_dir/source/$relative"
            or return 1
            __tpr_main_tex "$temp_dir/source" >/dev/null
            or return 1
            tar -cf "$temp_dir/source.tar" -C "$temp_dir/source" .
            or return 1
        end
    end

    if test -n "$bare"
        if type -q arxiv_latex_cleaner
            arxiv_latex_cleaner --keep_bib "$temp_dir/source"
            or return 1
        else
            __tpr_WARN 'Command `arxiv_latex_cleaner` not found: skipping some cleaning steps'
            cp -R "$temp_dir/source" "$temp_dir/source_arXiv"
            or return 1
        end

        fd --hidden --regex '^\.' --no-ignore "$temp_dir/source_arXiv" --prune --exec-batch rm -rf --
        or return 1
        fd --hidden --no-ignore --type f --regex '\.(aux|bcf|blg|brf|fdb_latexmk|fls|gz|latexmain|log|run\.xml|tar|thm|toc|toml|yml|yaml|zip)$' \
            "$temp_dir/source_arXiv" --exec-batch rm -f --
        or return 1
        __tpr_tar "$temp_dir/source_arXiv" "$temp_dir/source.tar"
        or return 1
    end

    if test (count $includes) -gt 0
        __tpr_compile_force "$temp_dir/source/$main_tex"
        or __tpr_WARN 'Compilation failed: some files may not be included.'
        for file_end in $includes
            set --local include_file (path change-extension "$file_end" -- "$main_tex")
            if test -f "$temp_dir/source/$include_file"
                tar -rf "$temp_dir/source.tar" -C "$temp_dir/source" "./$include_file"
                or return 1
            else
                __tpr_WARN "File '$include_file' was not generated before or during compilation."
            end
        end
    end

    set --local artifact "$temp_dir/source.tar"
    switch "$format"
        case gz
            gzip -9 "$artifact"
            or return 1
            set artifact "$artifact.gz"
        case dir
            set artifact "$temp_dir/output"
            mkdir "$artifact"
            and tar -xf "$temp_dir/source.tar" -C "$artifact"
            or return 1
    end
    __tpr_publish "$artifact" "$output" "$force"
end

function __tpr_diff --argument temp_dir working_dir output old_revision new_revision staged
    mkdir "$temp_dir/old" "$temp_dir/new"
    or return 1
    set --local old_main (__tpr_populate_tempdir "$temp_dir/old" "$working_dir" "$old_revision")
    or return 1
    set --local new_main
    if test -n "$staged"
        set new_main (__tpr_populate_index "$temp_dir/new" "$working_dir")
        or return 1
    else
        set --local output_path (path resolve -- (path dirname -- "$output"))/(path basename -- "$output")
        set new_main (__tpr_populate_tempdir "$temp_dir/new" "$working_dir" "$new_revision" "$temp_dir" "$output_path")
        or return 1
    end
    set --local diff_tex (path change-extension '' -- "$temp_dir/new/source/$new_main")-diff.tex
    latexdiff "$temp_dir/old/source/$old_main" "$temp_dir/new/source/$new_main" >"$diff_tex"
    and __tpr_compile_force "$diff_tex"
    or begin
        __tpr_FAIL 'Failed to compile diff file'
        return 1
    end
    command mv -i -- (path change-extension pdf -- "$diff_tex") "$output"
end

function __tpr_build --argument temp_dir working_dir reference output format force
    set --local main_tex (__tpr_populate_tempdir "$temp_dir" "$working_dir" "$reference")
    or return 1
    __tpr_compile "$temp_dir/source/$main_tex"
    or return 1
    if test -n "$output"
        set --local mv_flags -i
        if test -n "$force"
            set mv_flags -f
        end
        command mv $mv_flags -- (path change-extension "$format" -- "$temp_dir/source/$main_tex") "$output"
        or begin
            __tpr_FAIL "Failed to obtain requested file after compilation."
            return 1
        end
    end
end

function __tpr_snap --argument temp_dir tpr_working_dir tpr_config_file
    set --local FIGURES $argv[4..]
    set --local snap_preamble (__tpr_config_get "$tpr_config_file" snap_preamble '')
    or return 1
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
            '\end{document}' >"$snap_source"
        or return 1

        if not env TEXINPUTS="$latex_search_path" latexmk -pdf -interaction=nonstopmode -silent -Werror -file-line-error -outdir="$temp_dir" "$snap_source" >/dev/null
            __tpr_FAIL "Failed to compile figure '$FIGURE'."
            return 1
        end

        set --local output_file (path change-extension pdf "$figure_file")
        if not command mv -f -- "$temp_dir/snap-$figure_index.pdf" "$output_file"
            __tpr_FAIL "Failed to write figure PDF '$output_file'."
            return 1
        end
    end
end

function tpr --description 'Manage LaTeX project repositories'
    argparse --name tpr --stop-nonopt h/help v/version C/directory= -- $argv
    or return 1
    if set --query _flag_help
        tpr_help
        return 0
    end
    if set --query _flag_version
        echo 'tpr (version 1.3)'
        return 0
    end
    if test (count $argv) -eq 0
        tpr_help
        return 1
    end

    set --local requested_directory "$PWD"
    if set --query _flag_directory
        set requested_directory "$_flag_directory"
    end
    set --local subcommand "$argv[1]"
    set --erase argv[1]
    set --local subcommand_args $argv
    if test "$subcommand" = template
        argparse --name 'tpr template' --stop-nonopt h/help -- $argv
        or return 1
        if set --query _flag_help
            tpr_help template
            return 0
        end
        if test (count $argv) -eq 0
            tpr_help template
            return 1
        end
        set subcommand "template-$argv[1]"
        set subcommand_args $argv[2..]
    end
    set argv $subcommand_args

    set --local options h/help
    set --local operands
    set --local max_args 0
    set --local dependencies
    switch "$subcommand"
        case template-install
            set operands NAME GIT
            set max_args 2
            set dependencies git
        case template-uninstall
            set operands NAME
            set max_args 1
        case template-update
            set dependencies git
        case template-list
        case init
            set operands TEMPLATE
            set max_args 1
            set dependencies copier git
        case remote
            set operands REPONAME
            set max_args 1
            set dependencies yq gh git
        case archive
            set --append options I/include=+ b/bare r/reference= f/force F/format=
            set operands OUT
            set max_args 1
            set dependencies fd
        case diff
            set --append options staged
            set operands PDF
            set max_args 3
            set dependencies git latexdiff latexmk
        case validate
            set --append options r/reference=
            set dependencies fd latexmk
        case compile
            set --append options F/format= f/force r/reference=
            set operands OUT
            set max_args 1
            set dependencies fd latexmk
        case snap
            set operands FIGURE
            set max_args -1
            set dependencies yq latexmk
        case update
            set dependencies copier
        case '*'
            __tpr_FAIL "Unknown command: '$subcommand'"
            return 1
    end

    # make help work without args, deps, setup, etc.
    argparse --name "tpr $(string replace -a - ' ' -- "$subcommand")" $options -- $argv
    or return 1
    if set --query _flag_help
        tpr_help "$subcommand"
        return 0
    end
    set --local index 1
    for operand in $operands
        if test -z "$argv[$index]"
            __tpr_missing_arg "$operand"
            return 1
        end
        set index (math "$index" + 1)
    end
    if test "$max_args" -ge 0; and test (count $argv) -gt "$max_args"
        __tpr_FAIL "Too many positional arguments for '$subcommand'."
        return 1
    end
    if test "$subcommand" = diff
        if set --query _flag_staged; and set --query argv[3]
            __tpr_FAIL '--staged cannot be combined with NEW.'
            return 1
        end
        for revision in $argv[2..]
            if test -z "$revision"
                __tpr_FAIL 'Revision arguments must not be empty.'
                return 1
            end
        end
        if not set --query _flag_staged; and not set --query argv[3]
            set --append dependencies fd
        end
    end
    __tpr_require $dependencies
    or return 1

    set --local working_dir (path resolve -- "$requested_directory")
    if not test -d "$working_dir"
        __tpr_FAIL "Working directory '$requested_directory' does not exist"
        return 1
    end
    set --local data_dir "$HOME/.local/share/tpr"
    if test -n "$XDG_DATA_HOME"
        set data_dir "$XDG_DATA_HOME/tpr"
    end
    set --local config_file "$HOME/.config/tpr/config.toml"
    if test -n "$XDG_CONFIG_HOME"
        set config_file "$XDG_CONFIG_HOME/tpr/config.toml"
    end
    set --local template_dir "$data_dir/templates"

    switch "$subcommand"
        case template-install template-uninstall
            set --local name "$argv[1]"
            if not string match --quiet --regex '^[a-zA-Z0-9_-]+$' -- "$name"
                __tpr_FAIL 'Invalid template name!'
                return 1
            end
            if test "$subcommand" = template-uninstall
                command rm -rf -- "$template_dir/$name"
            else
                if test -e "$template_dir/$name"
                    __tpr_FAIL "Template with name $name already installed!"
                    return 1
                end
                mkdir -p -- "$template_dir"
                and git clone -- "$argv[2]" "$template_dir/$name" >/dev/null
            end

        case template-update
            for template in "$template_dir"/*/
                git -C "$template" pull
                or return 1
            end

        case template-list
            __tpr_list_templates "$template_dir"

        case init
            set --local template "$argv[1]"
            if not contains -- "$template" (__tpr_list_templates "$template_dir")
                __tpr_FAIL "Invalid template '$template'"
                return 1
            end

            set --local initialize_git 0
            set --local first_commit_msg
            if not git -C "$working_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1
                set initialize_git 1
                set first_commit_msg (__tpr_config_get "$config_file" first_commit_msg 'Initialize new project repository')
                or return 1
            end
            copier copy "$template_dir/$template" "$working_dir"
            or return 1
            if test "$initialize_git" -eq 1
                git -C "$working_dir" init
                and git -C "$working_dir" add -A
                and git -C "$working_dir" commit -m "$first_commit_msg"
                or return 1
                set --local commit_file "$data_dir/resources/pre-commit"
                if test -f "$commit_file"
                    cp -i -- "$commit_file" "$working_dir/.git/hooks/pre-commit"
                    or return 1
                end
            end
            return 0

        case remote
            set --local homepage (__tpr_config_get "$config_file" homepage '')
            or return 1
            set --local remote (__tpr_config_get "$config_file" remote origin)
            or return 1
            git -C "$working_dir" rev-parse --git-dir >/dev/null
            or return 1
            if git -C "$working_dir" remote get-url "$remote" >/dev/null 2>&1
                __tpr_FAIL "remote '$remote' already exists"
                return 1
            end
            set --local homepage_opt
            if test -n "$homepage"
                set homepage_opt --homepage "$homepage"
            end
            gh repo create "$argv[1]" --remote "$remote" --source "$working_dir" --disable-issues --disable-wiki --private --push $homepage_opt

        case archive
            set --local format gz
            if set --query _flag_format
                set format "$_flag_format"
            end
            if not contains -- "$format" gz tar dir
                __tpr_FAIL "invalid option for --format: $format"
                return 1
            end
            # Resolve the parent while preserving an output symlink itself.
            set --local output (path resolve -- (path dirname -- "$argv[1]"))/(path basename -- "$argv[1]")
            set output (path normalize -- "$output")
            if test "$output" = "$working_dir"; or test (string sub --length (string length -- "$output/") -- "$working_dir/") = "$output/"
                __tpr_FAIL 'Archive output cannot be the source directory or one of its parents.'
                return 1
            end
            if test -e "$output"; or test -L "$output"
                if not set --query _flag_force
                    __tpr_FAIL "File or directory '$output' already exists. Override with --force."
                    return 1
                end
            end
            __tpr_with_tempdir __tpr_archive "$working_dir" "$output" "$format" "$_flag_force" "$_flag_reference" "$_flag_bare" $_flag_include

        case diff
            set --local old_revision HEAD
            if set --query argv[2]
                set old_revision "$argv[2]"
            end
            set --local new_revision ''
            if set --query argv[3]
                set new_revision "$argv[3]"
            end
            __tpr_with_tempdir __tpr_diff "$working_dir" "$argv[1]" "$old_revision" "$new_revision" "$_flag_staged"

        case compile validate
            set --local output ''
            set --local format pdf
            if test "$subcommand" = compile
                set output "$argv[1]"
                if set --query _flag_format
                    set format "$_flag_format"
                end
            end
            __tpr_with_tempdir __tpr_build "$working_dir" "$_flag_reference" "$output" "$format" "$_flag_force"

        case snap
            __tpr_with_tempdir __tpr_snap "$working_dir" "$config_file" $argv

        case update
            copier update "$working_dir"
    end
end
