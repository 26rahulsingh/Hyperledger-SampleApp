#!/bin/bash

# Exit on first error, print all commands.
set -ev

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1

CHANNEL_NAME="mychannel"
CLI_DELAY=3
LANGUAGE="node"
CLI_TIMEOUT=10
VERBOSE=false

# stop the network
docker-compose -f docker-compose-cli.yaml down

# start the network
docker-compose -f docker-compose-cli.yaml up -d
if [ $? -ne 0 ]; then
    echo "ERROR !!!! Unable to start network"
    exit 1
fi

# now run the end to end script
docker exec cli scripts/script.sh $CHANNEL_NAME $CLI_DELAY $LANGUAGE $CLI_TIMEOUT $VERBOSE
if [ $? -ne 0 ]; then
    echo "ERROR !!!! Test failed"
    exit 1
fi
