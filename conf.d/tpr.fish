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
    functions --erase tpr
    functions --erase tpr_help
    functions --erase __tpr_FAIL
    functions --erase __tpr_WARN
    functions --erase __tpr_main_tex
    functions --erase __tpr_compile
    functions --erase __tpr_compile_force
    functions --erase __tpr_tar
    functions --erase __tpr_populate_tempdir
    functions --erase __tpr_list_templates
    functions --erase __tpr_install
    functions --erase __tpr_uninstall
end
