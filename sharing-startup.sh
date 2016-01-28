#!/bin/sh

# Debug purposes: echo the command before issuing it
# set -x

# Sources that were helpful in creating this script:
# https://stackoverflow.com/questions/171550/find-out-which-remote-branch-a-local-branch-is-tracking
# https://unix.stackexchange.com/questions/146942/how-can-i-test-if-a-variable-is-empty-or-contains-only-spaces

readonly SCRIPT_BASE_DIR="$HOME/dev/PhD/utils"
source $SCRIPT_BASE_DIR/echo_script.sh
source $SCRIPT_BASE_DIR/check_node_version.sh

# Global variables
readonly BASEDIR="$HOME/dev/PhD"
readonly VM1="$BASEDIR/cozy-vm1"
readonly VM2="$BASEDIR/cozy-vm2"
readonly VMS="$VM1 $VM2"
readonly BRANCH="sharing"
readonly SCRIPT_NAME="startup"


# In Archlinux I have to load the three following modules if I want my virtual
# machines to launch and if I want to be able to communicate an host-only
# network.
# The vboxdrv module is required by virtualbox, the other - vboxnetadp &
# vboxnetflt - to be able to use an host-only network.
load_modules() {
    echo_script "Loading modules."

    local mods="vboxdrv vboxnetadp vboxnetflt"
    for module in $mods
    do
        if !(lsmod | grep $module &> /dev/null)
        then
            echo_script $SUDO "Loading: $module"
            # Putting the command inside parantheses runs it within a subshell
            # in which we ask to output every command issued with the "set -x".
            (set -x ; sudo -k modprobe $module)
        fi
    done

    echo_script "Loading modules: done."
}


# This is just here so that I don't forget to do it...
load_ssh_key() {
    echo_script "Adding ssh key."

    # Add the ssh key linked to my github account
    local ssh_key="$HOME/.ssh/a-julien--github"
    # The "ssh-add -l" list all the ssh keys that are actually loaded ; we then
    # grep the results to check if the ssh key linked to my account is among
    # them
    if !(ssh-add -l | grep $ssh_key &> /dev/null)
    then
        (set -x ; ssh-add $ssh_key)
    fi

    echo_script "Adding ssh key: done."
}


update_git_repositories() {
    echo_script "Updating repositories."

    # Go through each dir of both virtual machines and update the git
    # repositories if a branch sharing exists
    for vm in $VMS
    do
        cd $vm
        for dir in */
        do
            # Checks if we do are trying to cd an actual dir. This test exists
            # because if there are no folder inside the vm's then an error is
            # displayed
            if [ -d $dir ]
            then
                cd $vm/$dir

                # First case: the dir is a git repository and has a local
                # branch that has the name specified
                if (git rev-parse --verify $BRANCH &> /dev/null)
                then

                    local current_branch=$(git symbolic-ref --short -q HEAD)
                    local remote_branch=$(git branch -r | \
                        grep $BRANCH &> /dev/null)

                    # Switch the repository to the branch we are interested in
                    if [ $current_branch != $BRANCH ]
                    then
                        echo_script "$(pwd): switching to $BRANCH"
                        git checkout $BRANCH
                    fi

                    local symbolic_ref=$(git symbolic-ref -q HEAD)
                    local remote_tracked_branch=$(git for-each-ref \
                        --format='%(upstream:short)' $symbolic_ref)

                    # If there is a remote
                    if [ $remote_tracked_branch ]
                    then
                        # First update the remote information
                        git remote update &> /dev/null
                        # Then get the number of commits that are behind the
                        # remote
                        local nb_commit=$(git rev-list \
                            $branch..$remote_tracked_branch --count)

                        # If that number is greater than 0 then we can pull
                        if [ $nb_commit -gt 0 ]
                        then
                            echo_script "$(pwd): pull possible"

                            echo_script "$(pwd): checkout build"
                            if !(git checkout -- build)
                            then
                                echo_script $ERROR "$(pwd) could " \
                                    "not checkout the build/ folder"
                                exit -2
                            fi

                            # XXX Maybe I should ask if pulling is okay?
                            if !(git pull)
                            then
                                echo_script $ERROR "$(pwd): git pull failed"

                                # XXX Add an option to ask if I want to reset
                                # hard the repo to force the pull. I don't mind
                                # this behavior because I don't work on the
                                # repos that are located on the VM so there is
                                # normally nothing to preserve.
                                exit -1
                            else
                                # The files has been updated, the application
                                # should be rebuilt
                                $SCRIPT_BASE_DIR/cozy--build-app.sh "$(pwd)"
                            fi
                        fi
                    fi

                # Second case: there is no local branch but there is a remote
                # branch that has the same name. We create a local branch that
                # will follow this particular remote.
                elif [ $remote_branch ]
                then
                    echo_script "$vm/$dir: creating branch $BRANCH" \
                        " and trying to set its upstream to:" \
                        " origin/$BRANCH"

                    # XXX What if there are several matches to the grep made at
                    # line 70-71? What if the name of the remote branch we are
                    # interested in does not follow this pattern?
                    git checkout -b $BRANCH
                    git branch --set-upstream-to=origin/$BRANCH $BRANCH
                    if !(git pull)
                    then
                        echo_script $ERROR "$(pwd): git pull failed"
                        exit -1
                    fi
                fi
            fi

            # I need to explicitly go back to the parent directory, otherwise
            # the script tries to access the next $dir in the list from the
            # current directory which is $vm/$dir
            cd $vm

        done
    done

    echo_script "Updating repositories: done."
}


start_vms() {
    for vm in $VM1
    do
        cd $vm

        # Start the virtual machine
        cozy-dev vm:start

        # XXX --- DOES NOT WORK YET ---
        #
        # ATTENTION FOR THIS PART TO WORK ONE NEEDS TO ADD THE FOLLOWING
        # LINE TO THE VAGRANTFILE OF THE VM BEFORE THE FINAL "END" AT THE END
        # OF THE VAGRANTFILE. THE PATH OF THE SCRIPT MUST BE ADAPTED TO YOUR
        # NEEDS.
        # IT MUST BE DONE FOR EACH VM. I insist.
        #
        # config.vm.provision "shell", path: "../utils/sharing-vm-setup.sh"

        # Execute the script within the vm (see above)
        # vagrant provision
        # XXX --- DOES NOT WORK YET ---

    done
}


main() {
    load_modules
    load_ssh_key
    update_git_repositories
    # start_vms
}

main
