#!/bin/sh


readonly BASEDIR="/vagrant"
readonly BRANCH="sharing"
readonly APPLICATIONS="home proxy data-system"
readonly REPLACEMENTS="paul-data-system paul-proxy paul-home"

setup_env() {
    # Stop the different applications
    for app in $APPLICATIONS
    do
        cozy-monitor stop $app
    done

    # Start the custom replacement
    cd $BASEDIR
    for repl in $REPLACEMENTS
    do
        cd $repl

        # Simple test to check if the current directory is a git repository
        if (git rev-parse --verify $BRANCH &> /dev/null)
        then
            # if we are on the $BRANCH
            local repl_branch=$(git symbolic-ref --short -q HEAD)
            if [ $repl_branch = $BRANCH ]
            then
                # In every replacement application there is a server.coffee
                # file that needs to be launched in order to start it.
                # Since the script is launched with Vagrant the "nohup" is
                # mandatory otherwise the process would be killed just
                # after the script has ended. The shell that would hold it
                # would be destroyed by Vagrant as soon as the script has
                # ended.
                HOST=0.0.0.0 nohup coffee server.coffee &

                # We ask the script to take a 10 seconds break so that the
                # command above has some time to run
                sleep 10
            fi
        fi

        # We go back to the parent folder
        cd $BASEDIR
    done
}


setup_env
