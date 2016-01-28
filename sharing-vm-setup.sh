#!/bin/sh

readonly GREEN="\\033[1;32m"
readonly NORMAL="\\033[0;39m"
readonly RED="\\033[1;31m"
readonly ROSE="\\033[1;35m"
readonly ORANGE='\e[0;33m'
readonly BLEU="\\033[1;34m"
readonly BLANC="\\033[0;02m"
readonly BLANCLAIR="\\033[1;08m"
readonly JAUNE="\\033[1;33m"
readonly CYAN="\\033[1;36m"

readonly BASEDIR="/vagrant"
readonly BRANCH="sharing"
readonly APPLICATIONS="home proxy data-system"
readonly REPLACEMENTS="/home/paul-data-system $BASEDIR/paul-home \
    $BASEDIR/paul-proxy"


echo_script() {
    echo -e -n "${Green}startup${Color_Off} - "
    if [ "$#" -gt 0 ]
    then
        for arg in "$@"
        do
            echo -e "$arg"
        done
    fi
}

setup_env() {

    # Stop the different applications
    echo_script "Stopping base applications."

    for app in $APPLICATIONS
    do
        cozy-monitor stop $app
    done

    echo_script "Stopping base applications: done."

    # Start the custom replacement
    echo_script "Starting custom replacement applications."

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

                if [ $repl = "$BASEDIR/paul-home" ]
                then
                    rm -rf node_modules/bcrypt
                    sudo npm install bcrypt --silent
                fi

                echo_script "$(pwd): Launching server..."

                # In every replacement application there is a server.coffee
                # file that needs to be launched in order to start it.
                # Since the script is launched with Vagrant the "nohup" is
                # mandatory otherwise the process would be killed just
                # after the script has ended. The shell that would hold it
                # would be destroyed by Vagrant as soon as the script has
                # ended.
                # HOST=0.0.0.0 nohup coffee server.coffee &
                if !(HOST=0.0.0.0 coffee server.coffee &)
                then
                    echo_script -en "${RED}[ERROR]${NORMAL} " \
                        "An error occurred trying to launch $(pwd)"

                    # XXX Should we kill the processes that were launched
                    # before if any?
                    exit -1
                fi

                # We ask the script to take a 10 seconds break so that the
                # command above has some time to run
                sleep 10
            fi
        fi

        # We go back to the parent folder
        cd $BASEDIR
    done
    echo_script "Starting custom replacement applications: done."
}


setup_env
