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


function tpr --description 'Initialize LaTeX project repositories' --argument command
    set --function tpr_version 0.1
    set --function available_templates preprint

    switch $command
        case -v --version
            echo "tpr, version $tpr_version"


        case '' -h --help help
            echo 'Usage: tpr init TEMPLATE        Create new project from TEMPLATE'
            echo '       tpr remote REPONAME      Create a remote repository'
            echo '       tpr archive GZ [COMMIT]  Export files to GZ'
            echo '                                  COMMIT: use commit'
            echo '       tpr validate             Verify compilation'
            echo '       tpr build PDF [COMMIT]   Compile and output to PDF'
            echo '                                  COMMIT: use commit'
            echo '       tpr list                 List available templates'


        case init
            if string length -q -- (ls -A)
                __tpr_FAIL "Current directory is not empty"; return 1
            end

            if not test (count $argv) -eq 2
                __tpr_FAIL "missing template name"; return 1
            end

            set --local TEMPLATE $argv[2]

            if not contains $TEMPLATE $available_templates
                __tpr_FAIL "Invalid template '$TEMPLATE'"; return 1
            end

            copier "gh:rutar-academic/template-$TEMPLATE" .

            and git init
            and git add -A
            and git commit -m "Initialize new project repository."


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
            echo $available_templates


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



        case '*'
            echo "tpr: Unknown command: \"$command\"" >&2
            return 1
    end
end
