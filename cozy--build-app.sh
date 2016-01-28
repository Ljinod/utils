#!/bin/sh

readonly SCRIPT_BASE_DIR="$HOME/dev/PhD/utils"

source $SCRIPT_BASE_DIR/check_node_version.sh
source $SCRIPT_BASE_DIR/echo_script.sh

SCRIPT_NAME="cozy--build-app"


set_directory()
{
    if [ ! -d $1 ]
    then
        echo_script $ERROR "Directory \`$1\` does not exist."
        exit -1
    fi

    # Move to the directory specified
    cd $1

    # Change the name of the script to that of the directory (without the full
    # path). It is supposed to be the name of the application.
    SCRIPT_NAME=${PWD##*/}
}


build_client()
{
    # Check if the directory client exists and return if not
    if [ ! -d client ]; then return; fi

    echo_script " __ Building client."

    cd client

    # XXX I should ask if npm should be run or not OR, better, find a way to
    # check if it should be run
    if [ -f package.json ]
    then
        echo_script "(client) Installing node modules."
        npm install --silent &> /dev/null
        echo_script "(client) Installing node modules: done."
    fi

    if [ -f bower.json ]
    then
        echo_script "Running \`bower install\`."
        if !(bower install --silent)
        then
            echo_script $ERROR "\`bower install\` failed."
            exit -1
        fi
        echo_script "Running \`bower install\`: done."
    fi

    # XXX Find an indicator to tell me wether or not brunch build should be run
    echo_script "Running \`brunch build\`."
    if !(brunch build)
    then
        echo_script $ERROR "\`brunch build\` failed."
        exit -1
    fi
    echo_script "Running \`brunch build\`: done."

    cd ..

    echo_script " __ Building client: done."
}


build_app()
{
    echo_script " __ Building app."

    echo_script "Trying to run: \`npm run build\`."

    local log_file=".npm_run_build.log"

    if (npm run build --silent &> $log_file)
    then
        if [ -f $log_file ]; then rm $log_file; fi
        echo_script "Running \`npm run build\`: done."

    else

        echo_script $WARNING "\`npm run build\` failed. " \
            "See the log file $log_file for details."
        echo_script "Trying to build application \"manually\""

        if [ -f Cakefile ]
        then
            if [ -f package.json ]
            then
                echo_script "(server) Installing node modules."
                npm install --silent &> /dev/null
                echo_script "(server) Installing node modules: done."
            fi

            build_client

            echo_script "Running \`cake build\`."
            if !(cake build)
            then
                echo_script $ERROR "\`cake build\` failed."
                exit -2
            fi
            echo_script "Running \`cake build\`: done."
        fi
    fi

    echo_script " __ Building app: done."
}


main()
{
    set_directory $1
    check_node_version
    build_app
}


# In order to work this script needs the path of the application to build
# so if no argument was provided then we cannot work
if [ "$#" -eq 0 ]
then
    echo_script $ERROR "You need to specify the directory of the " \
        "application to build."
    exit -3
fi

main $1
