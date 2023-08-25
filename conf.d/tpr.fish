function _tpr_install --on-event tpr_install
    for cmd in latexmk copier git fd
        if not which $cmd &> /dev/null
            set --function __tpr_install_error 1
            set_color red
            echo "Error: program '$cmd' is missing which breaks core functionality."
            set_color normal
        end
    end

    for cmd in yq gh
        if not which $cmd &> /dev/null
            set --function __tpr_install_error 1

            set_color yellow
            echo "Warning: program '$cmd' is missing which breaks `tpr remote` functionality."
            set_color normal
        end
    end

    for cmd in arxiv_latex_cleaner
        if not which $cmd &> /dev/null
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

function _tpr_uninstall --on-event tpr_uninstall
    functions --erase tpr
    functions --erase __tpr_FAIL
    functions --erase __tpr_main_tex
    functions --erase __tpr_make_tempdir
end
