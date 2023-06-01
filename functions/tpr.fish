function __tpr_FAIL --argument message
    set_color red; echo -n "Error: "; set_color normal
    echo $message >&2
    return 1
end


function __tpr_main_tex
    # get the main tex file, and ensure it exists and has the expected extension
    set --local main_tex (path change-extension '' *.latexmain | head -n 1)
    set --local main_tex_extension (path extension $main_tex)

    if not test -f $main_tex
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


function __tpr_make_tempdir --description "archive the current directory to a temporary tarfile" --argument commit
    set --function temp_dir (mktemp --directory)
    trap "rm -rf $temp_dir" INT TERM HUP EXIT

    set --local tarfile (mktemp)
    trap "rm -f $tarfile" INT TERM HUP EXIT

    if test -z "$commit"
        # if no commit is provided, populate $tarfile with current contents
        if not git ls-files -z | xargs -0 tar -cf $tarfile
            return 1
        end
    else
        # otherwise, use `git archive` to dump to $tarfile
        if not git archive --format=tar $commit --output $tarfile
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


function __tpr_help --argument cmd
    switch $cmd
        case ''
            echo 'Usage: tpr init TEMPLATE        Create new project from TEMPLATE'
            echo '       tpr list                 List available templates'
            echo '       tpr validate [COMMIT]    Verify compilation'
            echo '       tpr build PDF [COMMIT]   Compile and output to PDF'
            echo '                                  COMMIT: use commit'
            echo '       tpr archive GZ [COMMIT]  Export files to GZ'
            echo '                                  COMMIT: use commit'
            echo '       tpr remote REPONAME      Create a remote repository'
            echo '       tpr pull                 Update the existing templates'
            echo '       tpr install NAME GIT     Install new template'
            echo
            echo 'Run `tpr help [subcommand]` for more information on each'
            echo 'subcommand, or visit https://github.com/alexrutar/tpr for more'
            echo 'detailed information.'

        case list
            echo 'Usage: tpr list'
            echo
            echo '  List all available templates. Note that this only lists'
            echo '  templates that been installed. Install or update templates'
            echo '  with `tpr install`.'

        case validate
            echo 'Usage: tpr validate'
            echo
            echo '  Compile tex file specified with .latexmain in the current'
            echo '  directory and check for errors. The command used is'
            echo
            echo '  > latexmk -pdf -interaction=nonstopmode -silent -Werror'
            echo
            echo '  If COMMIT is given, use the commit specified by COMMIT.'
            echo '  The COMMIT argument is used as the argument to'
            echo '  `git archive`'

        case archive
            echo '       tpr archive GZ [COMMIT]  Export files to GZ'
            echo '                                  COMMIT: use commit'
            echo
            echo '  Export files in the current repository as a g-zipped archive'
            echo '  to the file specified with GZ. The export respects'
            echo '  your .gitignore.'
            echo
            echo '  If COMMIT is given, use the commit specified by COMMIT.'
            echo '  The COMMIT argument is used as the argument to'
            echo '  `git archive`'

        case build
            echo 'Usage: tpr build PDF'
            echo
            echo '  Compile tex file specified with .latexmain in the current directory'
            echo '  and check for errors. Output the compiled file to PDF.'
            echo
            echo '  > latexmk -pdf -interaction=nonstopmode -silent -Werror'
            echo
            echo '  If COMMIT is given, use the commit specified by COMMIT.'
            echo '  The COMMIT argument is used as the argument to'
            echo '  `git archive`'

        case init
            echo 'Usage: tpr init TEMPLATE'
            echo
            echo '  Create a new project in the current directory from TEMPLATE.'
            echo '  For information about template specification and installation,'
            echo '  run `tpr help install`.'
            echo

        case install
            echo 'Usage: tpr install [NAME] [GIT]'
            echo
            echo '  Install new templates with name NAME from the git repository GIT.'
            echo '  This is an error if the template already exists: to update, run'
            echo '  `tpr update`, and to remote a template, run `tpr remove-template`.'
            echo
            echo '  Templates for the project are rendered using copier. See'
            echo
            echo '    https://copier.readthedocs.io/en/stable/.'
            echo
            echo '  for more details about template creation.'

        case remote
            echo 'Usage: tpr remote REPONAME'
            echo
            echo '  Create a new private remote GitHub repository with name'
            echo '  REPONAME. REPONAME is an identifier of the form username/repo.'
            echo
            echo 'Example usage:'
            echo
            echo '  Create a new private repository at alexrutar/test-repo.'
            echo '  > tpr remote alexrutar/test-repo'

        case '*'
            __tpr_FAIL "Invalid subcommand '$argv[2]'"; return 1
    end
end


function tpr --description 'Initialize LaTeX project repositories' --argument command
    set --function tpr_version 0.2

    set --function tpr_data_dir $XDG_DATA_HOME/tpr
    set --function tpr_config_dir $XDG_CONFIG_HOME/tpr

    mkdir --parents $tpr_data_dir
    mkdir --parents $tpr_config_dir

    set --function tpr_resource_dir $tpr_data_dir/resources
    set --function tpr_template_dir $tpr_data_dir/templates
    set --function tpr_config_file $tpr_config_dir/config.toml

    switch $command
        case -v --version
            echo "tpr, version $tpr_version"


        case '' -h --help
            __tpr_help


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
                fish --command "git -C $file pull" &
                set --append pid_list (jobs --last --pid)
            end

            wait $pid_list 2>/dev/null


        case init
            if string length -q -- (ls -A)
                __tpr_FAIL "Current directory is not empty"; return 1
            end

            if not test (count $argv) -eq 2
                __tpr_FAIL "missing template name"; return 1
            end

            set --local TEMPLATE $argv[2]

            set --function available_templates (__tpr_list_templates $tpr_template_dir)
            if not contains $TEMPLATE $available_templates
                __tpr_FAIL "Invalid template '$TEMPLATE'"; return 1
            end

            copier $tpr_template_dir/$TEMPLATE .

            and git init
            and git add -A
            and git commit -m "Initialize new project repository."

            set --local commit_file $tpr_resource_dir/pre-commit
            if test -f "$commit_file"
                cp $commit_file .git/hooks/pre-commit
            end



        case remote
            set --local REPONAME $argv[2]
            if git config --get remote.origin.url
                __tpr_FAIL "remote 'origin' already exists"; return 1
            end

            if test -z "$REPONAME"
                __tpr_FAIL "missing remote repository name"; return 1
            end

            set --function homepage (yq '.homepage' $tpr_config_file)
            if test -n "$homepage"
                set --function homepage_cmd --homepage $homepage
            end

            gh repo create $REPONAME --remote origin --source . --disable-issues --disable-wiki --private --push $homepage_cmd


        case list
            __tpr_list_templates $tpr_template_dir


        case archive
            # check for all arguments and parse to variables
            if not test (count $argv) -gt 1
                __tpr_FAIL "missing argument 'PDF'"; return 1
            end

            set --function GZ $argv[2]
            set --function COMMIT $argv[3]

            if test -z "$COMMIT"
                # if no commit is provided, populate $tarfile with current contents
                if not git ls-files -z | xargs -0 tar -czf $GZ
                    return 1
                end
            else
                # otherwise, use `git archive` to dump to $tarfile
                if not git archive --format=tar.gz $COMMIT --output $GZ
                    return 1
                end
            end


        case validate
            # get and validate main.tex
            set --local main_tex (__tpr_main_tex)
            if not test -f "$main_tex"
                __tpr_FAIL "no tex file specified with .latexmain"; return 1
            end

            set --function COMMIT $argv[2]

            # make tempdir with latex contents
            set --local temp_dir (__tpr_make_tempdir $COMMIT)
            if not test -f "$temp_dir/$main_tex"
                __tpr_FAIL "failed to generate archive"; return 1
            end

            __tpr_compile $temp_dir/$main_tex


        case build
            # get and validate main.tex
            set --local main_tex (__tpr_main_tex)
            if not test -f "$main_tex"
                __tpr_FAIL "no tex file specified with .latexmain"; return 1
            end

            # check for all arguments and parse to variables
            if not test (count $argv) -gt 1
                __tpr_FAIL "missing argument 'PDF'"; return 1
            end

            set --local PDF $argv[2]
            set --function COMMIT $argv[3]

            # make tempdir with latex contents
            set --local temp_dir (__tpr_make_tempdir $COMMIT)
            if not test -f "$temp_dir/$main_tex"
                __tpr_FAIL "failed to generate archive"; return 1
            end

            __tpr_compile $temp_dir/$main_tex
            and mv -i (path change-extension pdf $temp_dir/$main_tex) $PDF


        case pull
            copier update


        case '*'
            echo "tpr: Unknown command: \"$command\"" >&2
            return 1
    end
end
