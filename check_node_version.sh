#!/bin/sh

readonly NODE="v0.10.25"

# Check the version of node that is currently in use
check_node_version()
{
    echo_script "Checking node version."

    local node_version=$(node --version)
    if [ $node_version != $NODE ]
    then
        echo_script $SUDO "Installing and/or switching to node version $NODE"
        (set +x ; sudo -k n $NODE)
    fi

    echo_script "Checking node version: done."
}
