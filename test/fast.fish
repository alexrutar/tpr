# INITIALIZATION
# --------------

# set initial variables
set --local tpr_dir /Users/alexrutar/Documents/20_29-Programming/20-Development/22.14-tpr
set --local test_dir $tpr_dir/test
set --local test_tempdir $test_dir/temp

mkdir $test_tempdir
cd $test_tempdir

# install correct vs version from directory
fisher remove alexrutar/tpr &> /dev/null
fisher install $tpr_dir &> /dev/null

function __tpr_test
    set_color green
    echo "* running: 'tpr $argv'"
    set_color normal
    tpr $argv
    switch $status
        case 0
            set_color blue; echo "* completed with no error"; set_color normal
        case '*'
            set_color red; echo "* completed with error"; set_color normal
    end
end


# TESTING
# -------

__tpr_test help
__tpr_test help list
__tpr_test help install

# CLEANUP
# -------

# remove sessions
rm --force --recursive $test_tempdir
functions -e __vs_test

# reinstall original vs version
fisher remove $tpr_dir &> /dev/null
fisher install alexrutar/tpr &> /dev/null
