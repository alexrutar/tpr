set -l tpr_subcommands init remote archive validate build list
complete --command tpr --exclusive
complete --command tpr --exclusive --long help --description "Print help"
complete --command tpr --exclusive --long version --description "Print version"

complete --command tpr --exclusive --condition "not __fish_seen_subcommand_from $tpr_subcommands" --arguments init --description "Create a new project"
complete --command tpr --exclusive --condition "not __fish_seen_subcommand_from $tpr_subcommands" --arguments remote --description "Create a remote repository"
complete --command tpr --exclusive --condition "not __fish_seen_subcommand_from $tpr_subcommands" --arguments archive --description "Export files"
complete --command tpr --exclusive --condition "not __fish_seen_subcommand_from $tpr_subcommands" --arguments validate --description "Verify compilation"
complete --command tpr --exclusive --condition "not __fish_seen_subcommand_from $tpr_subcommands" --arguments build --description "Compile to PDF"
complete --command tpr --exclusive --condition "not __fish_seen_subcommand_from $tpr_subcommands" --arguments list --description "List available templates"

complete --command tpr --exclusive --condition "__fish_seen_subcommand_from init" --arguments "(tpr list)" 
complete --command tpr --exclusive --condition "__fish_seen_subcommand_from build archive" --arguments "(__fish_complete_path)"
