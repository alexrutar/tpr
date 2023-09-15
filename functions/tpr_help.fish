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


function __tpr_echo_header --argument header
    set_color cyan --bold
    switch $header
        case usage-nl
            echo -n 'Usage: '
        case usage
            echo 'Usage:'
        case description
            echo; echo 'Description:'
        case options
            echo; echo 'Options:'
        case config
            echo; echo 'Configuration:'
        case subcommands
            echo 'Subcommands:'
    end
    set_color normal
end


function __tpr_echo_usage
    __tpr_echo_header usage-nl
    echo "$argv"
end


# TODO: create --staged option for `tpr validate` which only checks if there are changed files that would impact
# compilation, and only validates staged files (and not changes in the current working directory)
# possible trick: run arxiv_latex_cleaner and check if the resulting directories are different?
function tpr_help --argument cmd
    switch $cmd
        case ''
            __tpr_echo_header usage
            echo '  tpr init TEMPLATE        Create new project from TEMPLATE'
            echo '  tpr template ...         Subcommands for managing templates'
            echo '  tpr compile OUT          Compile and output to OUT'
            echo '  tpr validate             Verify compilation'
            echo '  tpr archive OUT          Export files to OUT'
            echo '  tpr remote REPONAME      Create a remote repository'
            echo '  tpr update               Update existing project'
            echo '  tpr diff PDF OLD [NEW]   Create diff PDF'
            echo '                             NEW: diff against commit'
            __tpr_echo_header options
            echo '  -C/--directory           Specify working directory (default: .)'
            echo '  -h/--help                Print help and exit.'
            echo '  -v/--version                Print version and exit.'
            echo
            echo -n 'Run '; __tpr_echo_code 'tpr [subcommand] --help'; echo ' for more information, or visit'
            echo -n '  '; __tpr_echo_url 'github.com/alexrutar/tpr'; echo

        case init
            __tpr_echo_usage 'tpr init TEMPLATE'
            __tpr_echo_header options
            echo '  -h/--help                Print help and exit.'
            __tpr_echo_header description
            echo '  Create a new project in the working directory from TEMPLATE.'
            echo '  For information about template specification and installation,'
            echo -n '  run '
            __tpr_echo_code 'tpr install --help'
            echo '.'

        case update
            __tpr_echo_usage 'tpr update'
            __tpr_echo_header options
            echo '  -h/--help                Print help and exit.'
            __tpr_echo_header description
            echo '  Update the project in the working directory.'

        case compile
            __tpr_echo_usage 'tpr compile OUT'
            __tpr_echo_header options
            echo '  -f/--force               Overwrite OUT.'
            echo '  -F/--format=FMT          Format of the output file (default: pdf).'
            echo '  -r/--reference=REF       Use git reference REF.'
            __tpr_echo_header description
            echo '  Compile tex file specified with .latexmain in the current directory'
            echo '  and check for errors. Output the compiled file to OUT using command'
            echo
            echo -n '  > '; set_color brgreen; echo -n 'latexmk -pdf -interaction=nonstopmode -silent -Werror'; set_color normal; echo
            echo
            echo '  If FMT is given, output the file <main_tex>.$FMT.'
            echo
            echo '  If --force is given overwrite file OUT.'
            echo
            echo '  If REF is given, use the commit specified by REF'
            echo -n '  The REF argument is used as the argument to '; __tpr_echo_code 'git archive'; echo '.'

        case diff
            __tpr_echo_usage 'tpr diff PDF OLD [NEW]'
            __tpr_echo_header options
            echo '  -h/--help                Print help and exit.'
            __tpr_echo_header description
            echo '  Create a diff PDF showing changes between OLD and HEAD.'
            echo '  If NEW is given, instead show changes between OLD and'
            echo '  NEW'

        case validate
            __tpr_echo_usage 'tpr validate'
            __tpr_echo_header options
            echo '  -h/--help                Print help and exit.'
            echo '  -r/--reference=REF       Use git reference REF.'
            __tpr_echo_header description
            echo '  Compile tex file specified with .latexmain in the current'
            echo '  directory and check for errors. The command used is'
            echo
            echo -n '  > '; set_color brgreen; echo -n 'latexmk -pdf -interaction=nonstopmode -silent -Werror'; set_color normal; echo
            echo
            echo '  If REF is given, use the commit specified by REF.'
            echo -n '  The REF argument is used as the argument to '; __tpr_echo_code 'git archive'; echo '.'

        case archive
            __tpr_echo_usage 'tpr archive OUT'
            __tpr_echo_header options
            echo '  -b/--bare                 Clean export files.'
            echo '  -h/--help                 Print help and exit.'
            echo '  -I/--include=EXTENSION    Include additional files in archive.'
            echo '  -f/--force                Overwrite OUT.'
            echo '  -F/--format=[tar|gz|dir]  Format of the archive (default: gz).'
            echo '  -r/--reference=REF       Use git reference REF.'
            __tpr_echo_header description
            echo '  Export files in the current repository to the file OUT.'
            echo '  The export respects your .gitignore. Include additional files'
            echo '  with -I. Clean export files with --bare, which automatically'
            echo '  removes all files not required for compilation and removes'
            echo '  comments from .tex files.'
            echo
            echo '  Specify the format of the output with --format. If tar or gz,'
            echo '  create a (compressed) tarball with the contents. The tarball'
            echo '  will extract directly into the directory in which it is opened.'
            echo '  If the dir option is specified, write output to the specified'
            echo '  directory instead.'
            echo
            echo '  If the --force option is used, delete OUT before archiving.'
            echo
            echo '  If REF is given, use the commit specified by REF.'
            echo -n '  The REF argument is used as the argument to '; __tpr_echo_code 'git archive'; echo '.'

        case remote
            __tpr_echo_usage 'tpr remote REPONAME'
            __tpr_echo_header options
            echo '  -h/--help                Print help and exit.'
            __tpr_echo_header description
            echo '  Create a new private remote GitHub repository with name'
            echo '  REPONAME. REPONAME is an identifier of the form username/repo.'
            __tpr_echo_header config
            echo '  tpr reads configuration from `$XDG_CONFIG_HOME/tpr/config.toml`,'
            echo '  which is often `~/.config/tpr/config.toml`. The following keys'
            echo '  are supported:'
            echo
            echo '  homepage: default homepage for your reporitory'

        case template
            __tpr_echo_header subcommands
            echo '  install NAME GIT    Install new template'
            echo '  uninstall NAME      Uninstall template'
            echo '  update              Update existing templates'
            __tpr_echo_header options
            echo '  -h/--help                Print help and exit.'
            echo
            echo -n 'Run '; __tpr_echo_code 'tpr template [subcommand] --help'; echo ' for more information, or visit'
            echo -n '  '; __tpr_echo_url 'github.com/alexrutar/tpr'; echo

        case template-install
            __tpr_echo_usage 'tpr template install NAME GIT'
            __tpr_echo_header options
            echo '  -h/--help                Print help and exit.'
            __tpr_echo_header description
            echo '  Install new templates with name NAME from the git repository GIT.'
            echo '  This is an error if the template already exists (remove first'
            echo -n '  with '; __tpr_echo_code "tpr template remove"; echo '.)'
            echo
            echo '  Templates for the project are rendered using copier. See'
            echo
            echo -n '    '; __tpr_echo_url 'copier.readthedocs.io/en/stable/'; echo
            echo
            echo '  for more details about template creation.'

        case template-uninstall
            __tpr_echo_usage 'tpr uninstall NAME'
            __tpr_echo_header options
            echo '  -h/--help                Print help and exit.'
            __tpr_echo_header description
            echo '  Uninstall the templates with name NAME.'

        case template-update
            __tpr_echo_usage 'tpr template update'
            __tpr_echo_header options
            echo '  -h/--help                Print help and exit.'
            __tpr_echo_header description
            echo '  Apply upstream template changes to the current project.'

        case template-list
            __tpr_echo_usage 'tpr template list'
            __tpr_echo_header options
            echo '  -h/--help                Print help and exit.'
            __tpr_echo_header description
            echo '  List all available templates. Install new templates'
            echo -n '  with '; __tpr_echo_code 'tpr install'; echo '.'
    end
end
