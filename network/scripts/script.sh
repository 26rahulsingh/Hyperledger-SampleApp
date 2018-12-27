#!/bin/bash

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Build your first network (BYFN) end-to-end test"
echo
CHANNEL_NAME="$1"
DELAY="$2"
LANGUAGE="$3"
TIMEOUT="$4"
VERBOSE="$5"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${LANGUAGE:="node"}
: ${TIMEOUT:="12"}
: ${VERBOSE:="true"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=10

CC_SRC_PATH="github.com/chaincode/chaincode_example02/go/"
if [ "$LANGUAGE" = "node" ]; then
	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/node/"
fi

if [ "$LANGUAGE" = "java" ]; then
	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/java/"
fi

echo "Channel name : "$CHANNEL_NAME

# import utils
. scripts/utils.sh

createChannel() {
	setGlobals 0 1

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
        set -x
		peer channel create -o orderer.jet-network.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx >&log.txt
		res=$?
        set +x
	else
		set -x
		peer channel create -o orderer.jet-network.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
		set +x
	fi
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel '$CHANNEL_NAME' created ===================== "
	echo
}

joinChannel () {
	for org in 1 2; do
	    for peer in 0 1; do
		joinChannelWithRetry $peer $org
		if [ $org -eq 1 ]; then
			echo "===================== peer${peer}.100mb joined channel '$CHANNEL_NAME' ===================== "
		else
			echo "===================== peer${peer}.thinkright joined channel '$CHANNEL_NAME' ===================== "
		fi
		sleep $DELAY
		echo
	    done
	done
}

## Create channel
echo "Creating channel..."
createChannel

## Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for 100MB..."
updateAnchorPeers 0 1
echo "Updating anchor peers for ThinkRight..."
updateAnchorPeers 0 2

## Install chaincode on peer0.100mb and peer0.thinkright
echo "Installing chaincode on peer0.100mb..."
installChaincode 0 1
echo "Install chaincode on peer0.thinkright..."
installChaincode 0 2

# Instantiate chaincode on peer0.thinkright
echo "Instantiating chaincode on peer0.thinkright..."
instantiateChaincode 0 2

# Query chaincode on peer0.100mb
echo "Querying chaincode on peer0.100mb..."
chaincodeQuery 0 1 100

# Invoke chaincode on peer0.100mb and peer0.thinkright
echo "Sending invoke transaction on peer0.100mb peer0.thinkright..."
chaincodeInvoke 0 1 0 2

## Install chaincode on peer1.thinkright
echo "Installing chaincode on peer1.thinkright..."
installChaincode 1 2

# Query on chaincode on peer1.thinkright, check if the result is 90
echo "Querying chaincode on peer1.thinkright..."
chaincodeQuery 1 2 90

echo
echo "========= All GOOD, BYFN execution completed =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
