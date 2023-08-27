# BEGIN content from https://github.com/fish-shell/fish-shell/blob/master/share/completions/git.fish
function __tpr_git_branches
    git for-each-ref --format='%(refname:strip=2)%09Local Branch' --sort=-committerdate refs/heads/ 2>/dev/null
    git for-each-ref --format='%(refname:strip=2)%09Remote Branch' refs/remotes/ 2>/dev/null
end

function __tpr_git_tags
    git tag --sort=-creatordate 2>/dev/null
end

function __tpr_git_commits
    git log --pretty=tformat:"%H"\t"%<(64,trunc)%s" --all --max-count=1000 2>/dev/null \
        | string replace -r '^([0-9a-f]{10})[0-9a-f]*\t(.*)' '$1\t$2'
end
# END

set -l tpr_subcommands init diff remote archive validate compile list template update
set -l tpr_template_subcommands install uninstall update

# disable file completions
complete -c tpr -f

# flags for base command
complete -c tpr -s h -l help -d "Print help and exit"
complete -c tpr -n "not __fish_seen_subcommand_from $tpr_subcommands" -s v -l version -d "Print version and exit"
complete -c tpr -n "not __fish_seen_subcommand_from $tpr_subcommands" -s C -l directory -r -F -d "Specify working directory"

complete -c tpr -n "not __fish_seen_subcommand_from $tpr_subcommands" -a archive -d "Export files"
complete -c tpr -n "not __fish_seen_subcommand_from $tpr_subcommands" -a compile -d "Compile to PDF"
complete -c tpr -n "not __fish_seen_subcommand_from $tpr_subcommands" -a diff -d "Generate diff file"
complete -c tpr -n "not __fish_seen_subcommand_from $tpr_subcommands" -a init -d "Create a new project"
complete -c tpr -n "not __fish_seen_subcommand_from $tpr_subcommands" -a remote -d "Create a remote repository"
complete -c tpr -n "not __fish_seen_subcommand_from $tpr_subcommands" -a template -d "Manage templates"
complete -c tpr -n "not __fish_seen_subcommand_from $tpr_subcommands" -a update -d "Update local template"
complete -c tpr -n "not __fish_seen_subcommand_from $tpr_subcommands" -a validate -d "Verify compilation"

# tpr {archive, compile, diff}
complete -c tpr -n "__fish_seen_subcommand_from archive compile diff" -F
complete -c tpr -n "__fish_seen_subcommand_from archive" -s b -l bare -d "Clean export files"
complete -c tpr -n "__fish_seen_subcommand_from archive" -rf -s I -l include -d "Include additional files"
complete -c tpr -n "__fish_seen_subcommand_from archive compile" -s f -l force -d "Overwrite output"
complete -c tpr -n "__fish_seen_subcommand_from archive compile" -rf -s F -l format -a "tar gz dir" -d "Specify output format"

# tpr {archive, compile, validate}
complete -c tpr -n "__fish_seen_subcommand_from archive compile validate" -rf -s r -l reference -d "Use git ref" -ka '(__tpr_git_branches)'
complete -c tpr -n "__fish_seen_subcommand_from archive compile validate" -rf -s r -l reference -d "Use git ref" -ka '(__tpr_git_tags)'
complete -c tpr -n "__fish_seen_subcommand_from archive compile validate" -rf -s r -l reference -d "Use git ref" -ka '(__tpr_git_commits)'

# tpr init
complete -c tpr -n "__fish_seen_subcommand_from init" -a "(tpr template list)"

# tpr template
complete -c tpr -n "__fish_seen_subcommand_from template" -n "not __fish_seen_subcommand_from $tpr_template_subcommands" -a install -d "Install template"
complete -c tpr -n "__fish_seen_subcommand_from template" -n "not __fish_seen_subcommand_from $tpr_template_subcommands" -a uninstall -d "Uninstall template"
complete -c tpr -n "__fish_seen_subcommand_from template" -n "not __fish_seen_subcommand_from $tpr_template_subcommands" -a update -d "Update installed templates"

complete -c tpr -n "__fish_seen_subcommand_from template" -n "__fish_seen_subcommand_from install" -f
complete -c tpr -n "__fish_seen_subcommand_from template" -n "__fish_seen_subcommand_from uninstall" -a "(tpr template list)"
complete -c tpr -n "__fish_seen_subcommand_from template" -n "__fish_seen_subcommand_from update" -f

# tpr {remote, update, validate}
complete -c tpr -n "__fish_seen_subcommand_from remote update validate" -f
