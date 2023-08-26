set -l tpr_subcommands init diff remote archive validate compile list template update
set -l tpr_template_subcommands install uninstall update

# disable file completions
complete -c tpr -f

# flags for base command
complete -c tpr -s h -l help -d "Print help and exit"
complete -c tpr -l version -d "Print version and exit"
complete -c tpr -s C -l directory -r -F -d "Specify working directory"

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
complete -c tpr -n "__fish_seen_subcommand_from archive" -s I -l include -r -d "Include additional files"
complete -c tpr -n "__fish_seen_subcommand_from archive compile" -s f -l force -d "Overwrite output"
complete -c tpr -n "__fish_seen_subcommand_from archive compile" -s F -l format -a "tar gz dir" -d "Specify output format"

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
