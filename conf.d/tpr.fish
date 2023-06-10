function _tpr_install --on-event tpr_install
    for cmd in copier git latexmk gh yq fd
        if not which $cmd &> /dev/null
            set_color yellow; echo "Warning: cannot find command '$cmd'. See https://github.com/alexrutar/tpr#dependencies for more details."; set_color normal
        end
    end
end

function _tpr_uninstall --on-event tpr_uninstall
    functions --erase tpr
    functions --erase __tpr_FAIL
    functions --erase __tpr_main_tex
    functions --erase __tpr_make_tempdir
end
