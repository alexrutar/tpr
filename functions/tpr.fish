function __tpr_FAIL --argument message
    set_color red; echo -n "Error: "; set_color normal
    echo $message >&2
    return 1
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


function __tpr_make_tempdir --description "archive the current directory to a temporary tarfile" --argument tpr_working_dir commit
    set --local temp_dir (mktemp --directory)
    trap "rm -rf $temp_dir" INT TERM HUP EXIT

    set --local tarfile (mktemp)
    trap "rm -f $tarfile" INT TERM HUP EXIT

    if test -n "$commit" >/dev/null
        # use `git archive` to dump to $tarfile if commit specified
        if not git -C $tpr_working_dir archive --format=tar $commit --output $tarfile
            return 1
        end
    else
        # otherwise, populate $tarfile with current contents
        if not fd -H --exclude '.git' --base-directory $tpr_working_dir --print0 | xargs -0 tar -rf $tarfile -C $tpr_working_dir
            return 1
        end
    end

    # untar and return tempdir on success
    tar -xf $tarfile -C $temp_dir
    and echo $temp_dir
end


function __tpr_list_templates --argument template_directory
    if not path basename $template_directory/*
        return 0
    end
end


function __tpr_echo_code
    echo -n '`'
    set_color brgreen
    echo -n "$argv"
    set_color normal
    echo -n '`'
end


function __tpr_echo_url
    set_color blue
    echo -n 'https://'
    echo -n "$argv"
    set_color normal
end


function __tpr_echo_usage
    set_color cyan --bold
    echo -n 'Usage: '
    set_color normal
    echo "$argv"
    echo
end


# also add files with tpr archive GZ --pdf --bbl ...?
function __tpr_help --argument cmd
    switch $cmd
        case ''
            set_color cyan --bold
            echo 'Usage:'
            set_color normal
            echo '  tpr init TEMPLATE         Create new project from TEMPLATE'
            echo '  tpr list                  List available templates'
            echo '  tpr compile PDF [COMMIT]  Compile and output to PDF'
            echo '                              COMMIT: use commit'
            echo '  tpr validate [COMMIT]     Verify compilation'
            echo '                              COMMIT: use commit'
            echo '  tpr archive GZ [COMMIT]   Export files to GZ'
            echo '                              COMMIT: use commit'
            echo '  tpr remote REPONAME       Create a remote repository'
            echo '  tpr pull                  Update existing project'
            echo '  tpr install NAME GIT      Install new template'
            echo '  tpr uninstall NAME        Uninstall template'
            echo '  tpr update                Update existing templates'
            echo
            set_color cyan --bold
            echo 'Options:'
            set_color normal
            echo '  -h/--help                 Print help and exit.'
            echo '  -v/-version              Print version and exit.'
            echo '  -C/--directory            Specify working directory (default: .)'
            echo
            echo -n 'Run '; __tpr_echo_code 'tpr help [subcommand]'; echo ' for more information, or visit'
            echo -n '  '
            __tpr_echo_url 'github.com/alexrutar/tpr'
            echo

        case init
            __tpr_echo_usage 'tpr init TEMPLATE'
            echo '  Create a new project in the current directory from TEMPLATE.'
            echo '  For information about template specification and installation,'
            echo -n '  run '
            __tpr_echo_code 'tpr help install'
            echo '.'

        case list
            __tpr_echo_usage 'tpr list'
            echo '  List all available templates. Install or update templates'
            echo -n '  with '
            __tpr_echo_code 'tpr install'
            echo '.'

        case compile
            __tpr_echo_usage 'tpr compile PDF'
            echo '  Compile tex file specified with .latexmain in the current directory'
            echo '  and check for errors. Output the compiled file to PDF.'
            echo
            echo -n '  > '; set_color brgreen; echo -n 'latexmk -pdf -interaction=nonstopmode -silent -Werror'; set_color normal; echo
            echo
            echo '  If COMMIT is given, use the commit specified by COMMIT.'
            echo -n '  The COMMIT argument is used as the argument to '; __tpr_echo_code 'git archive'; echo '.'

        case validate
            __tpr_echo_usage 'tpr validate'
            echo '  Compile tex file specified with .latexmain in the current'
            echo '  directory and check for errors. The command used is'
            echo
            echo '  > latexmk -pdf -interaction=nonstopmode -silent -Werror'
            echo
            echo '  If COMMIT is given, use the commit specified by COMMIT.'
            echo -n '  The COMMIT argument is used as the argument to '; __tpr_echo_code 'git archive'; echo '.'

        case archive
            __tpr_echo_usage 'tpr archive GZ [COMMIT]'
            echo '  Export files in the current repository as a g-zipped archive'
            echo '  to the file specified with GZ. The export respects'
            echo '  your .gitignore.'
            echo
            echo '  If COMMIT is given, use the commit specified by COMMIT.'
            echo -n '  The COMMIT argument is used as the argument to '; __tpr_echo_code 'git archive'; echo '.'

        case remote
            __tpr_echo_usage 'tpr remote REPONAME'
            echo '  Create a new private remote GitHub repository with name'
            echo '  REPONAME. REPONAME is an identifier of the form username/repo.'
            echo
            echo 'Example usage:'
            echo
            echo '  Create a new private repository at alexrutar/test-repo.'
            echo '  > tpr remote alexrutar/test-repo'
            echo
            echo 'Configuration:'
            echo '  tpr reads configuration from `$XDG_CONFIG_HOME/tpr/config.toml`,'
            echo '  which is often `~/.config/tpr/config.toml`. The following keys'
            echo '  are supported:'
            echo
            echo '`homepage`: default homepage for your reporitory'


        case install
            __tpr_echo_usage 'tpr install NAME GIT'
            echo '  Install new templates with name NAME from the git repository GIT.'
            echo '  This is an error if the template already exists: to update, run'
            echo '  `tpr update`, and to remote a template, run `tpr remove-template`.'
            echo
            echo '  Templates for the project are rendered using copier. See'
            echo
            echo -n '    '; __tpr_echo_url 'copier.readthedocs.io/en/stable/'; echo
            echo
            echo '  for more details about template creation.'

        case uninstall
            __tpr_echo_usage 'tpr uninstall NAME'
            echo '  Uninstall the templates with name NAME.'

        case pull
            __tpr_echo_usage 'tpr pull'
            echo '  Apply upstream template changes to the current project.'

        case '*'
            __tpr_FAIL "Invalid subcommand '$cmd'"; return 1
    end
end


function tpr --description 'Initialize LaTeX project repositories' --argument command
    set --local options (fish_opt --short=h --long=help)
    set --local options $options (fish_opt --short=v --long=version)
    set --local options $options (fish_opt --short=C --long=directory --required-val)

    # TODO: add include options for archive (to copy bbl, pdf, etc.)

    if not argparse $options -- $argv
        return 1
    end

    set --function tpr_version 0.3

    # catch help and version flags
    if set --query _flag_help
        __tpr_help
        return 0
    end

    if set --query _flag_version
        echo "tpr, version $tpr_version"
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
        __tpr_help; return 1
    end

    switch "$argv[1]"
        case help
            __tpr_help $argv[2]


        case install
            set --local NAME $argv[2]
            set --local GIT $argv[3]

            if not test (count $argv) -eq 3
                __tpr_FAIL "incorrect number of arguments"; return 1
            end

            set --local matched_name (string match --regex '[a-zA-Z0-9_\-]+' $NAME)

            if not test "$matched_name" = "$NAME"
                __tpr_FAIL "Invalid template name!"; return 1
            end

            if test -e "$tpr_template_dir/$NAME"
                __tpr_FAIL "Template with name $NAME already installed!"; return 1
            end

            git clone $GIT "$tpr_template_dir/$NAME" > /dev/null


        case uninstall
            set --local NAME $argv[2]

            set --local matched_name (string match --regex '[a-zA-Z0-9_\-]+' $NAME)

            if not test "$matched_name" = "$NAME"
                __tpr_FAIL "Invalid template name!"; return 1
            end

            if test -e "$tpr_template_dir/$NAME"
                rm -rf $tpr_template_dir/$NAME
            end


        case update
            for file in $tpr_template_dir/*
                fish --command "git -C $file pull --force" &
                set --append pid_list (jobs --last --pid)
            end

            wait $pid_list 2>/dev/null


        case init
            if string length -q -- (ls -A $tpr_working_dir)
                __tpr_FAIL "Working directory is not empty"; return 1
            end

            if not test (count $argv) -eq 2
                __tpr_FAIL "missing template name"; return 1
            end

            set --local TEMPLATE $argv[2]

            set --function available_templates (__tpr_list_templates $tpr_template_dir)
            if not contains $TEMPLATE $available_templates
                __tpr_FAIL "Invalid template '$TEMPLATE'"; return 1
            end

            copier copy $tpr_template_dir/$TEMPLATE $tpr_working_dir

            and git -C $tpr_working_dir init
            and git -C $tpr_working_dir add -A
            and git -C $tpr_working_dir commit -m "Initialize new project repository."

            set --local commit_file $tpr_resource_dir/pre-commit
            if test -f "$commit_file"
                cp $commit_file $tpr_working_dir/.git/hooks/pre-commit
            end


        case remote
            set --local REPONAME $argv[2]
            if git -C $tpr_working_dir config --get remote.origin.url
                __tpr_FAIL "remote 'origin' already exists"; return 1
            end

            if test -z "$REPONAME"
                __tpr_FAIL "missing remote repository name"; return 1
            end

            set --function homepage (yq '.homepage' $tpr_config_file)
            if test -n "$homepage"
                set --function homepage_opt --homepage $homepage
            end

            gh repo create $REPONAME --remote origin --source $tpr_working_dir --disable-issues --disable-wiki --private --push $homepage_opt


        case list ls
            __tpr_list_templates $tpr_template_dir


        case archive export
            # check for all arguments and parse to variables
            if not test (count $argv) -gt 1
                __tpr_FAIL "missing argument 'GZ'"; return 1
            end

            set --function GZ $argv[2]
            set --function COMMIT $argv[3]

            if test -z "$COMMIT"
                # if no commit is provided, populate $tarfile with current contents
                if not git -C $tpr_working_dir ls-files -z | xargs -0 tar -czf $GZ -C $tpr_working_dir
                    return 1
                end
            else
                # otherwise, use `git archive` to dump to $tarfile
                if not git -C $tpr_working_dir archive --format=tar.gz $COMMIT --output $GZ
                    return 1
                end
            end


        case validate
            # get and validate main.tex
            set --local main_tex (__tpr_main_tex $tpr_working_dir)
            if not test -f "$tpr_working_dir/$main_tex"
                __tpr_FAIL "no tex file specified with .latexmain"; return 1
            end

            set --local COMMIT $argv[2]

            # make tempdir with latex contents
            set --local temp_dir (__tpr_make_tempdir $tpr_working_dir $COMMIT)
            if not test -f "$temp_dir/$main_tex"
                __tpr_FAIL "failed to generate archive"; return 1
            end

            __tpr_compile $temp_dir/$main_tex


        case compile
            # get and validate main.tex
            set --local main_tex (__tpr_main_tex $tpr_working_dir)
            if not test -f "$tpr_working_dir/$main_tex"
                __tpr_FAIL "no tex file specified with .latexmain"; return 1
            end

            # check for all arguments and parse to variables
            if not test (count $argv) -gt 1
                __tpr_FAIL "missing argument 'PDF'"; return 1
            end

            set --local PDF $argv[2]
            set --local COMMIT $argv[3]

            # make tempdir with latex contents
            set --local temp_dir (__tpr_make_tempdir $tpr_working_dir $COMMIT)
            if not test -f "$temp_dir/$main_tex"
                __tpr_FAIL "failed to generate archive"; return 1
            end

            __tpr_compile $temp_dir/$main_tex
            and mv -i (path change-extension pdf $temp_dir/$main_tex) $PDF


        case pull
            copier update $tpr_working_dir


        case '*'
            __tpr_FAIL "Unknown command: \"$argv[1]\""; return 1
    end
end
