#!/bin/sh

# Debug purposes: echo the command before issuing it
# set -x

readonly BASEDIR="$HOME/dev/PhD"
readonly VM1="$BASEDIR/cozy-vm1"
readonly VM2="$BASEDIR/cozy-vm2"


load_modules() {
    local mods="vboxdrv vboxnetadp vboxnetflt"
    for module in $mods
    do
        if ! (lsmod | grep $module &> /dev/null)
        then
            echo "[SUDO] Loading: $module"
            sudo modprobe $module
        fi
    done
}


update_git_repositories() {
    # Add the ssh key linked to my github account
    local ssh_key="$HOME/.ssh/a-julien--github"
    # The "ssh-add -l" list all the ssh keys that are actually loaded ; we then
    # grep the results to check if the ssh key linked to my account is among
    # them
    if ! (ssh-add -l | grep $ssh_key &> /dev/null)
    then
        ssh-add $ssh_key
    fi

    # Go through each dir of both virtual machines and update the git
    # repositories if a branch sharing exists
    local branch="sharing"
    for vm in $VM1 $VM2
    do
        cd $vm
        for dir in */
        do
            # Checks if we do are trying to cd an existing dir
            if [ -d $dir ]
            then
                cd $dir

                # check that the current dir is indeed a git repository and
                # has a branch sharing
                if [ -d .git ] && (git rev-parse --verify $branch &> /dev/null)
                then
                    git checkout $branch
                    git pull
                fi

                # we don't forget to go back to the parent directory
                cd $vm
            fi
        done
        # we don't forget to go back to the parent directory of the vm
        cd $BASEDIR
    done
}

main() {
    load_modules
    update_git_repositories
}

main
