set -l tpr_subcommands init diff remote archive validate compile list template update
set -l tpr_template_subcommands install uninstall update

complete --command tpr --exclusive
complete --command tpr --exclusive --short-option h --long-option help --description "Print help"
complete --command tpr --exclusive --short-option v --long-option version --description "Print version"
complete --command tpr --short-option C --long-option directory --force-files --description "Specify working directory"

complete --command tpr --exclusive --condition "not __fish_seen_subcommand_from $tpr_subcommands" --arguments init --description "Create a new project"
complete --command tpr --exclusive --condition "not __fish_seen_subcommand_from $tpr_subcommands" --arguments remote --description "Create a remote repository"
complete --command tpr --exclusive --condition "not __fish_seen_subcommand_from $tpr_subcommands" --arguments archive --description "Export files"
complete --command tpr --exclusive --condition "not __fish_seen_subcommand_from $tpr_subcommands" --arguments validate --description "Verify compilation"
complete --command tpr --exclusive --condition "not __fish_seen_subcommand_from $tpr_subcommands" --arguments compile --description "Compile to PDF"
complete --command tpr --exclusive --condition "not __fish_seen_subcommand_from $tpr_subcommands" --arguments list --description "List available templates"
complete --command tpr --exclusive --condition "not __fish_seen_subcommand_from $tpr_subcommands" --arguments update --description "Update local template"
complete --command tpr --exclusive --condition "not __fish_seen_subcommand_from $tpr_subcommands" --arguments diff --description "Generate diff file"
complete --command tpr --exclusive --condition "not __fish_seen_subcommand_from $tpr_subcommands" --arguments template --description "Manage templates"
# complete --command tpr --exclusive --condition "not __fish_seen_subcommand_from $tpr_subcommands" --arguments install --description "Install new template"
# complete --command tpr --exclusive --condition "not __fish_seen_subcommand_from $tpr_subcommands" --arguments uninstall --description "Uninstall existing template"
# complete --command tpr --exclusive --condition "not __fish_seen_subcommand_from $tpr_subcommands" --arguments update --description "Update installed templates"
#
complete --command tpr --exclusive --condition "__fish_seen_subcommand_from template and not __fish_seen_subcommand_from uninstall" --arguments $tpr_template_subcommands
complete --command tpr --exclusive --condition "__fish_seen_subcommand_from init" --arguments "(tpr template list)" 
complete --command tpr --exclusive --condition "__fish_seen_subcommand_from template and __fish_seen_subcommand_from uninstall" --arguments "(tpr template list)" 
complete --command tpr --force-files --condition "__fish_seen_subcommand_from compile archive diff"
