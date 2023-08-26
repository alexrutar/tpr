function __tpr_install --on-event tpr_install
    for cmd in latexmk git fd
        if not type -q $cmd
            set --function __tpr_install_error 1
            set_color red
            echo "Error: program '$cmd' is missing which breaks core functionality."
            set_color normal
        end
    end

    if not type -q copier
        set --function __tpr_install_error 1
        set_color yellow
        echo "Warning: program '$cmd' is missing which breaks `tpr init` and `tpr template` functionality."
        set_color normal
    end

    for cmd in yq gh
        if not type -q $cmd
            set --function __tpr_install_error 1

            set_color yellow
            echo "Warning: program '$cmd' is missing which breaks `tpr remote` functionality."
            set_color normal
        end
    end

    for cmd in arxiv_latex_cleaner
        if not type -q $cmd
            set --function __tpr_install_error 1
            set_color yellow
            echo "Warning: program '$cmd' is missing which breaks `tpr archive --bare` functionality."
            set_color normal
        end
    end

    if set --query __tpr_install_error
        set --erase __tpr_install_error
        echo "See https://github.com/alexrutar/tpr#dependencies for more details."
    end
end

function __tpr_uninstall --on-event tpr_uninstall
    # functions/tpr.fish
    functions --erase \
        tpr __tpr_FAIL __tpr_WARN __tpr_missing_arg __tpr_main_tex \
        __tpr_compile  __tpr_compile_force __tpr_tar __tpr_populate_tempdir \
        __tpr_list_templates

    # functions/tpr_help.fish
    functions --erase \
        tpr_help __tpr_echo_code __tpr_echo_url __tpr_echo_header \
        __tpr_echo_usage

    # conf.d/tpr.fish
    functions --erase __tpr_install __tpr_uninstall
end
