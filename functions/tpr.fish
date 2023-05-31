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


function __tpr_list_templates --argument template_file
    echo (awk '{print $1}' $template_file)
end

function __tpr_help --argument cmd
    switch $cmd
        case ''
            echo 'Usage: tpr init TEMPLATE        Create new project from TEMPLATE'
            echo '       tpr remote REPONAME      Create a remote repository'
            echo '       tpr archive GZ [COMMIT]  Export files to GZ'
            echo '                                  COMMIT: use commit'
            echo '       tpr validate             Verify compilation'
            echo '       tpr build PDF [COMMIT]   Compile and output to PDF'
            echo '                                  COMMIT: use commit'
            echo '       tpr list                 List available templates'
            echo '       tpr update               Update the existing templates'
            echo '       tpr install              Install available templates'
            echo
            echo 'Run `tpr help [subcommand]` for more information on each'
            echo 'subcommand, or visit https://github.com/alexrutar/tpr for more'
            echo 'detailed information.'

        case list
            echo 'Usage: tpr list'
            echo
            echo '  List all available templates. Note that this also lists'
            echo '  templates that have not yet been installed. Install or'
            echo '  update templates with `tpr install`.'

        case '*'
            __tpr_FAIL "Invalid subcommand '$argv[2]'"; return 1
    end
end


function tpr --description 'Initialize LaTeX project repositories' --argument command
    set --function tpr_version 0.2

    set --function tpr_data_dir $XDG_DATA_HOME/tpr
    mkdir --parents $tpr_data_dir

    set --function tpr_resource_dir $tpr_data_dir/resources
    set --function tpr_template_list $tpr_data_dir/templates.txt
    set --function tpr_template_dir $tpr_data_dir/templates


    switch $command
        case -v --version
            echo "tpr, version $tpr_version"


        case '' -h --help
            __tpr_help


        case help
            __tpr_help $argv[2]


        case install
            for line in (cat $tpr_template_list)
                set --local split_line (string split ' ' $line)
                set --local repo_dir $tpr_template_dir/$split_line[1]

                if git -C $repo_dir pull &> /dev/null
                    echo "Updating template '$split_line[1]'..."
                else
                    echo "Installing new template from '$split_line[2]'..."
                    git clone $split_line[2] $repo_dir &> /dev/null
                    or __tpr_FAIL "Failed to install template '$split_line[1]'"
                end
            end


        case init
            if string length -q -- (ls -A)
                __tpr_FAIL "Current directory is not empty"; return 1
            end

            if not test (count $argv) -eq 2
                __tpr_FAIL "missing template name"; return 1
            end

            set --local TEMPLATE $argv[2]

            set --function available_templates (__tpr_list_templates $tpr_template_list)
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

            read -l -P "Create repository '$REPONAME'? [y/N] " confirm
            switch $confirm
                case Y y
                    gh repo create $REPONAME --remote origin --source . --disable-issues --disable-wiki --private --push --homepage "https://rutar.org"
                    return 0
                case '*'
                    return 1
            end


        case list
            __tpr_list_templates $tpr_template_list


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


        case update
            copier update


        case '*'
            echo "tpr: Unknown command: \"$command\"" >&2
            return 1
    end
end
