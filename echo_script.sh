#!/bin/sh

# Colors!
readonly Green='\e[0;32m'
readonly Yellow='\e[0;33m'
readonly IRed='\e[0;91m'
readonly On_Red='\e[41m'
readonly Blue='\e[0;34m'
readonly Color_Off='\e[0m'

# Global variables
readonly INFO="info"
readonly ERROR="ERROR"
readonly WARNING="warning"
readonly SUDO="sudo"


echo_script() {
    # the "-e" argument is to process the colors, the "-n" is so that the next
    # echo command is not printed on a new line but appended to this one
    if [ ! -z $SCRIPT_NAME ]
    then
        echo -en "${Green}${SCRIPT_NAME}${Color_Off} - "
    fi

    # if there is an argument then process it: there should normally be more
    # than one but this tests is there just to make sure no errors linked to
    # the script itself are printed...
    if [ "$#" -gt 0 ]
    then

        local color=${Color_Off}

        for arg in "$@"
        do
            case $arg in
                $ERROR)
                    echo -en "${On_Red}(${arg})${Color_Off} "
                    ;;
                $WARNING)
                    echo -en "${Yellow}(${arg})${Color_Off} "
                    ;;
                $SUDO)
                    echo -en "${IRed}(${arg})${Color_Off} "
                    ;;
                *)
                    # If this is not a special message - meaning it does not
                    # match the case expressed before - then it is an
                    # informative message hence I want to display "INFO" before
                    if [ "$arg" = "${1}" ]
                    then
                        echo -en "${Blue}(${INFO})${Color_Off} "
                    fi

                    # I don't want to have the next message appended to this
                    # one so if it's the last argument I omit the "-n" option
                    if [ "$arg" = "${@:$#}" ]
                    then
                        echo -e "$arg"
                    # Not the first argument nor the last: I want to append
                    # what appears next
                    else
                        echo -en "$arg"
                    fi
                    ;;
            esac
        done
    fi
}
