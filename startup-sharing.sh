#!/bin/sh

# Debug purposes: echo the command before issuing it
# set -x

# Sources:
# https://stackoverflow.com/questions/171550/find-out-which-remote-branch-a-local-branch-is-tracking

readonly BASEDIR="$HOME/dev/PhD"
readonly VM1="$BASEDIR/cozy-vm1"
readonly VM2="$BASEDIR/cozy-vm2"


load_modules() {
    echo "[STARTUP] Loading modules."

    local mods="vboxdrv vboxnetadp vboxnetflt"
    for module in $mods
    do
        if !(lsmod | grep $module &> /dev/null)
        then
            echo "[SUDO] Loading: $module"
            sudo modprobe $module
        fi
    done

    echo "[STARTUP] Loading modules: done."
}


load_ssh_key() {
    echo "[STARTUP] Adding ssh key."

    # Add the ssh key linked to my github account
    local ssh_key="$HOME/.ssh/a-julien--github"
    # The "ssh-add -l" list all the ssh keys that are actually loaded ; we then
    # grep the results to check if the ssh key linked to my account is among
    # them
    if !(ssh-add -l | grep $ssh_key &> /dev/null)
    then
        ssh-add $ssh_key
    fi

    echo "[STARTUP] Adding ssh key: done."
}


update_git_repositories() {
    echo "[STARTUP] Updating repositories."

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

                # First case: the dir is a git repository and has a local
                # branch that has the name specified
                if (git rev-parse --verify $branch &> /dev/null)
                then

                    local current_branch=$(git symbolic-ref --short -q HEAD)
                    local remote_branch=$(git branch -r | \
                        grep $branch 2> /dev/null)

                    # Switch the repository to the branch we are interested in
                    if [[ $current_branch != $branch ]]
                    then
                        echo "[INFO] $vm/$dir: switching to $branch"
                        git checkout $branch
                    fi

                    local symbolic_ref=$(git symbolic-ref -q HEAD)
                    local remote_tracked_branch=$(git for-each-ref \
                        --format='%(upstream:short)' $symbolic_ref)

                    # If there is a remote
                    if [[ ! -z $remote_tracked_branch ]]
                    then
                        # First update the remote information
                        git remote update &> /dev/null
                        # Then get the number of commits that are behind the
                        # remote
                        local nb_commit=$(git rev-list \
                            $branch..$remote_tracked_branch --count)

                        # If that number is greater than 0 then we can pull
                        if [[ $nb_commit -gt 0 ]]
                        then
                            echo "\n\n[INFO] Repository $vm/$dir: pull"
                            git pull
                        fi
                    fi

                # Second case: there is no local branch but there is a remote
                # branch that has the same name. We create a local branch that
                # will follow this particular remote.
                elif [[ ! -z $remote_branch ]]
                then
                    echo "[INFO] $vm/$dir: creating branch $branch"
                    git checkout -b $branch
                    git branch --set-upstream-to=origin/$branch $branch
                    git pull
                fi

                # we don't forget to go back to the parent directory
                cd $vm
            fi
        done
        # we don't forget to go back to the parent directory of the vm
        cd $BASEDIR
    done

    echo "[STARTUP] Updating repositories: done."
}

main() {
    load_modules
    load_ssh_key
    update_git_repositories
}

main
