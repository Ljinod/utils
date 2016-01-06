#!/bin/sh

readonly BASEDIR="/vagrant"
readonly BRANCH="sharing"


# This function is supposed to be run the very first time the VM is created. It
# does the following things:
# - install all node dependencies in the client and the server parts of an
#   application
# - launch the brunch build of the client
init_replacement_app() {

    cd $BASEDIR

    # Install brunch and bower globally as they are required to build the
    # client part of the applications
    sudo npm install -g brunch@1 --silent
    sudo npm install -g bower --silent

    for dir in */
    do
        cd "$BASEDIR/$dir"

        if [ $(git rev-parse --verify $BRANCH &> /dev/null) ]
        then
            echo "[INIT] $(pwd) npm install --silent"
            sudo npm install --silent

            if [ -d client ]
            then
                cd client
                echo "[INIT] $(pwd) npm install --silent"
                sudo npm install --silent

                if [ -f bower.json ]
                then
                    echo "[INIT] $(pwd) bower install --silent"
                    bower install --config.interactive=false --silent
                fi

                echo "[INIT] $(pwd) brunch build"
                brunch build

                cd ..
            fi

            echo "[INIT] $(pwd) cake build"
            cake build
        fi

        cd $BASEDIR

    done
}

init_replacement_app
