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


function tpr_help --argument cmd
    switch $cmd
        case ''
            set_color cyan --bold
            echo 'Usage:'
            set_color normal
            echo '  tpr init TEMPLATE          Create new project from TEMPLATE'
            echo '  tpr template ...           Subcommands for managing templates'
            echo '  tpr compile PDF [COMMIT]   Compile and output to PDF'
            echo '                               COMMIT: use commit'
            echo '  tpr validate [COMMIT]      Verify compilation'
            echo '                               COMMIT: use commit'
            echo '  tpr archive OUT [COMMIT]   Export files to OUT'
            echo '                               COMMIT: use commit'
            echo '  tpr remote REPONAME        Create a remote repository'
            echo '  tpr update                 Update existing project'
            echo '  tpr diff PDF COMMIT [REV]  Create diff PDF'
            echo
            set_color cyan --bold
            echo 'Options:'
            set_color normal
            echo '  -h/--help                Print help and exit.'
            echo '  -V/--version                Print version and exit.'
            echo '  -C/--directory           Specify working directory (default: .)'
            echo
            echo -n 'Run '; __tpr_echo_code 'tpr [subcommand] --help'; echo ' for more information, or visit'
            echo -n '  '
            __tpr_echo_url 'github.com/alexrutar/tpr'
            echo

        case init
            __tpr_echo_usage 'tpr init TEMPLATE'
            echo '  Create a new project in the working directory from TEMPLATE.'
            echo '  For information about template specification and installation,'
            echo -n '  run '
            __tpr_echo_code 'tpr install --help'
            echo '.'

        case update
            __tpr_echo_usage 'tpr update'
            echo '  Update the project in the working directory.'

        case compile
            __tpr_echo_usage 'tpr compile PDF [COMMIT]'
            set_color cyan --bold; echo 'Options:'; set_color normal
            echo '  -f/--force               Overwrite OUT.'
            echo '  -F/--format FMT          Format of the output file (default: pdf).'
            echo
            echo '  Compile tex file specified with .latexmain in the current directory'
            echo '  and check for errors. Output the compiled file to OUT using command'
            echo
            echo -n '  > '; set_color brgreen; echo -n 'latexmk -pdf -interaction=nonstopmode -silent -Werror'; set_color normal; echo
            echo
            echo '  If FMT is given, output the file <main_tex>.$FMT.'
            echo
            echo '  If --force is given overwrite file OUT.'
            echo
            echo '  If COMMIT is given, use the commit specified by COMMIT.'
            echo -n '  The COMMIT argument is used as the argument to '; __tpr_echo_code 'git archive'; echo '.'

        case diff
            __tpr_echo_usage 'tpr diff PDF COMMIT [REV]'
            echo '  Create a diff PDF showing changes between COMMIT and HEAD.'
            echo '  If REV is given, instead show changes between COMMIT and'
            echo '  REV.'

        case validate
            __tpr_echo_usage 'tpr validate [COMMIT]'
            echo '  Compile tex file specified with .latexmain in the current'
            echo '  directory and check for errors. The command used is'
            echo
            echo '  > latexmk -pdf -interaction=nonstopmode -silent -Werror'
            echo
            echo '  If COMMIT is given, use the commit specified by COMMIT.'
            echo -n '  The COMMIT argument is used as the argument to '; __tpr_echo_code 'git archive'; echo '.'

        case archive
            __tpr_echo_usage 'tpr archive OUT [COMMIT]'
            set_color cyan --bold; echo 'Options:'; set_color normal
            echo '  -b/--bare                 Clean export files.'
            echo '  -I/--include EXTENSION    Include additional files in archive.'
            echo '  -f/--force                Overwrite OUT.'
            echo '  -F/--format [tar|gz|dir]  Format of the archive (default: gz).'
            echo
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


        case template
            set_color cyan --bold
            echo 'Subcommands:'
            set_color normal
            echo '  install NAME GIT    Install new template'
            echo '  uninstall NAME      Uninstall template'
            echo '  update              Update existing templates'
            echo
            echo -n 'Run '; __tpr_echo_code 'tpr template [subcommand] --help'; echo ' for more information, or visit'
            echo -n '  '
            __tpr_echo_url 'github.com/alexrutar/tpr'
            echo


        case template-install
            __tpr_echo_usage 'tpr template install NAME GIT'
            echo '  Install new templates with name NAME from the git repository GIT.'
            echo '  This is an error if the template already exists: to update, run'
            echo '  `tpr update`, and to remote a template, run `tpr remove-template`.'
            echo
            echo '  Templates for the project are rendered using copier. See'
            echo
            echo -n '    '; __tpr_echo_url 'copier.readthedocs.io/en/stable/'; echo
            echo
            echo '  for more details about template creation.'


        case template-uninstall
            __tpr_echo_usage 'tpr uninstall NAME'
            echo '  Uninstall the templates with name NAME.'


        case template-update
            __tpr_echo_usage 'tpr template update'
            echo '  Apply upstream template changes to the current project.'


        case template-list
            __tpr_echo_usage 'tpr template list'
            echo '  List all available templates. Install or update templates'
            echo -n '  with '
            __tpr_echo_code 'tpr install'
            echo '.'
    end
end
