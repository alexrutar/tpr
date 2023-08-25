function __tpr_FAIL --argument message
    set_color red; echo -n "Error: " >&2; set_color normal
    echo $message >&2
    return 1
end


function __tpr_WARN --argument message
    set_color yellow; echo -n "Warning: " >&2; set_color normal
    echo $message >&2
end


function __tpr_main_tex --argument tpr_working_dir
    # get the main tex file, and ensure it exists and has the expected extension
    set --local main_tex_relative (path change-extension '' $tpr_working_dir/*.latexmain | head -n 1)
    set --local main_tex (path basename $main_tex_relative)
    set --local main_tex_extension (path extension $main_tex)

    if not test -f $main_tex_relative
        return 1
    end
    
    if not test "$main_tex_extension" = ".tex"
        return 1
    end
    echo $main_tex
end


function __tpr_compile --argument texfile
    latexmk -pdf -interaction=nonstopmode -silent -Werror -file-line-error -cd $texfile > /dev/null
end


function __tpr_tar --argument source_dir tarfile
    fd -H --exclude '.git' --base-directory $source_dir --print0 | xargs -0 tar -rf $tarfile -C $source_dir
end


function __tpr_populate_tempdir --description "archive the current directory to a temporary tarfile" --argument temp_dir tpr_working_dir commit
    # get and validate main.tex
    set --local main_tex (__tpr_main_tex $tpr_working_dir)
    if not test -f "$tpr_working_dir/$main_tex"
        __tpr_FAIL "no tex file specified with .latexmain"; return 1
    end

    if test -n "$commit" >/dev/null
        # use `git archive` to dump to $tarfile if commit specified
        if not git -C $tpr_working_dir archive --format=tar $commit --output $temp_dir/source.tar
            return 1
        end
    else
        # otherwise, populate $tarfile with current contents
        if not __tpr_tar $tpr_working_dir $temp_dir/source.tar
            return 1
        end
    end

    # untar
    mkdir $temp_dir/source
    tar -xf $temp_dir/source.tar -C $temp_dir/source

    # check that archive was generated properly
    if not test -f "$temp_dir/source/$main_tex"
        __tpr_FAIL "failed to generate archive"; return 1
    end

    # if so, return
    echo "$main_tex"
end


function __tpr_list_templates --argument template_directory
    if not path basename $template_directory/*
        return 0
    end
end


# add tpr diff command OLD [NEW] to automatically generate a diff PDF.
function tpr --description 'Initialize LaTeX project repositories' --argument command
    set --local options (fish_opt --short=h --long=help)
    set --local options $options (fish_opt --short=v --long=version)
    set --local options $options (fish_opt --short=C --long=directory --required-val)

    if not argparse --stop-nonopt $options -- $argv
        return 1
    end

    set --function tpr_version 0.3

    # catch help and version flags
    if set --query _flag_help
        tpr_help; return 0
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
        set --function tpr_working_dir $_flag_directory
    else
        set --function tpr_working_dir (pwd)
    end

    mkdir --parents $tpr_data_dir
    mkdir --parents $tpr_config_dir

    set --function tpr_resource_dir $tpr_data_dir/resources
    set --function tpr_template_dir $tpr_data_dir/templates
    set --function tpr_config_file $tpr_config_dir/config.toml

    if test (count $argv) -eq 0
        tpr_help; return 1
    end

    set --local temp_dir (mktemp --directory)
    trap "rm -rf $temp_dir" INT TERM HUP EXIT


    set --local options (fish_opt --short=h --long=help)
    switch "$argv[1]"

        case template
            # parse options and catch help
            if not argparse --stop-nonopt $options -- $argv[2..]
                return 1
            end

            if set --query _flag_help
                tpr_help template; return 0
            end

            if test (count $argv) -eq 0
                tpr_help template; return 1
            end


            switch $argv[1]
                case install
                    # parse options and catch help
                    if not argparse $options -- $argv[2..]
                        return 1
                    end

                    if set --query _flag_help
                        tpr_help template-install; return 0
                    end

                    # first positional
                    set --local NAME $argv[1]
                    if not set --query NAME
                        __tpr_FAIL "missing positional argument NAME"; return 1
                    end

                    # second positional
                    set --local GIT $argv[2]
                    if not set --query GIT
                        __tpr_FAIL "missing positional argument GIT"; return 1
                    end

                    # validate template name
                    set --local matched_name (string match --regex '[a-zA-Z0-9_\-]+' $NAME)

                    if not test "$matched_name" = "$NAME"
                        __tpr_FAIL "Invalid template name!"; return 1
                    end

                    if test -e "$tpr_template_dir/$NAME"
                        __tpr_FAIL "Template with name $NAME already installed!"; return 1
                    end

                    # install to directory
                    git clone $GIT "$tpr_template_dir/$NAME" > /dev/null


                case uninstall
                    # parse options and catch help
                    if not argparse $options -- $argv[2..]
                        return 1
                    end

                    if set --query _flag_help
                        tpr_help template-uninstall; return 0
                    end

                    # first positional
                    set --local NAME $argv[1]
                    if not set --query NAME
                        __tpr_FAIL "missing positional argument NAME"; return 1
                    end

                    # validate template name
                    set --local matched_name (string match --regex '[a-zA-Z0-9_\-]+' $NAME)

                    if not test "$matched_name" = "$NAME"
                        __tpr_FAIL "Invalid template name!"; return 1
                    end

                    if test -e "$tpr_template_dir/$NAME"
                        rm -rf "$tpr_template_dir/$NAME"
                    end


                case update
                    # parse options and catch help
                    if not argparse $options -- $argv[2..]
                        return 1
                    end

                    if set --query _flag_help
                        tpr_help template-update; return 0
                    end

                    for file in $tpr_template_dir/*
                        fish --command "git -C $file pull --force" &
                        set --append pid_list (jobs --last --pid)
                    end

                    wait $pid_list 2>/dev/null


                case list ls
                    # parse options and catch help
                    if not argparse $options -- $argv[2..]
                        return 1
                    end

                    if set --query _flag_help
                        tpr_help template-list; return 0
                    end

                    __tpr_list_templates $tpr_template_dir


                case '*'
                    __tpr_FAIL "Unknown template subcommand: \"$argv[2]\""; return 1
            end


        case init
            set --local options $options (fish_opt --short=F --long=force)
            if not argparse $options -- $argv[2..]
                return 1
            end

            if set --query _flag_help
                tpr_help init; return 0
            end

            if string length -q -- (ls -A $tpr_working_dir)
            and not set --query _flag_force
                __tpr_FAIL "Working directory is not empty"; return 1
            end

            set --local TEMPLATE $argv[1]
            if not set --query TEMPLATE
                __tpr_FAIL "missing positional argument TEMPLATE"; return 1
            end

            set --function available_templates (__tpr_list_templates $tpr_template_dir)
            if not contains $TEMPLATE $available_templates
                __tpr_FAIL "Invalid template '$TEMPLATE'"; return 1
            end

            copier copy $tpr_template_dir/$TEMPLATE $tpr_working_dir

            # not a git directory: initialize new repository
            if not test -d $tpr_working_dir/.git
                git -C $tpr_working_dir init
                and git -C $tpr_working_dir add -A
                and git -C $tpr_working_dir commit -m "Initialize new project repository."

                set --local commit_file $tpr_resource_dir/pre-commit
                if test -f "$commit_file"
                    cp -i $commit_file $tpr_working_dir/.git/hooks/pre-commit
                end
            end


        case remote
            if not argparse $options -- $argv[2..]
                return 1
            end

            if set --query _flag_help
                tpr_help remote; return 0
            end

            set --local REPONAME $argv[1]
            if not test --query REPONAME
                __tpr_FAIL "missing positional argument REPONAME"; return 1
            end

            if git -C $tpr_working_dir config --get remote.origin.url
                __tpr_FAIL "remote 'origin' already exists"; return 1
            end

            set --function homepage (yq '.homepage' $tpr_config_file)
            if test -n "$homepage"
                set --function homepage_opt --homepage $homepage
            end

            gh repo create $REPONAME --remote origin --source $tpr_working_dir --disable-issues --disable-wiki --private --push $homepage_opt


        # add --include / -I option to tpr archive with a regex
        # add --bare option to prune all un-needed files with arxiv_latex_cleaner
        case archive export
            set --local options $options (fish_opt --short=I --long=include --multiple-vals)
            set --local options $options (fish_opt --short=b --long=bare)

            if not argparse $options -- $argv[2..]
                return 1
            end

            if set --query _flag_help
                tpr_help archive; return 0
            end

            # check for all arguments and parse to variables
            if not test (count $argv) -gt 0
                __tpr_FAIL "missing argument 'GZ'"; return 1
            end

            set --function GZ $argv[1]
            if not set --query GZ
                __tpr_FAIL "missing positional argument GZ"; return 1
            end

            set --function COMMIT $argv[2]

            set --local main_tex (__tpr_populate_tempdir $temp_dir $tpr_working_dir $COMMIT)
            or return 1

            # if --bare: replace tarfile with modified contents
            if set --query _flag_bare
                arxiv_latex_cleaner $temp_dir/source
                rm --force $temp_dir/source.tar
                __tpr_tar $temp_dir/source_arXiv $temp_dir/source.tar
            end

            # include additional requested files
            if set --query _flag_include
                __tpr_compile "$temp_dir/source/$main_tex"
                for file_end in $_flag_include
                    set --local include_file (path change-extension $file_end $main_tex)
                    if test -f $temp_dir/source/$include_file
                        tar -rf $temp_dir/source.tar -C $temp_dir/source (path change-extension $file_end $main_tex)
                    else
                        __tpr_WARN "File '$include_file' was not generated before or during compilation."
                    end
                end
            end

            # compress tarfile and export
            gzip -9 $temp_dir/source.tar
            and mv -i $temp_dir/source.tar.gz $GZ


        case validate
            if not argparse $options -- $argv[2..]
                return 1
            end

            if set --query _flag_help
                tpr_help validate; return 0
            end

            set --local COMMIT $argv[1]

            set --local main_tex (__tpr_populate_tempdir $temp_dir $tpr_working_dir $COMMIT)
            or return 1

            __tpr_compile "$temp_dir/source/$main_tex"


        case compile
            if not argparse $options -- $argv[2..]
                return 1
            end

            if set --query _flag_help
                tpr_help compile; return 0
            end

            set --local PDF $argv[1]
            if not set --query PDF
                __tpr_FAIL "missing positional argument PDF"; return 1
            end

            set --local COMMIT $argv[2]

            set --local main_tex (__tpr_populate_tempdir $temp_dir $tpr_working_dir $COMMIT)
            or return 1

            __tpr_compile "$temp_dir/source/$main_tex"
            and mv -i (path change-extension pdf $temp_dir/source/$main_tex) $PDF


        case update
            if not argparse $options -- $argv[2..]
                return 1
            end

            if set --query _flag_help
                tpr_help update; return 0
            end

            copier update $tpr_working_dir


        case '*'
            __tpr_FAIL "Unknown command: \"$argv[1]\""; return 1
    end
end
