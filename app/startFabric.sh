#!/bin/bash
# Exit on first error

set -e

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1

starttime=$(date +%s)

if [ ! -d ~/.hfc-key-store/ ]; then
	mkdir ~/.hfc-key-store/
fi

# launch network; create channel and join peer to channel
cd ../network
./start.sh

# Now launch the CLI container in order to install, instantiate chaincode
# and prime the ledger with our 10 tuna catches
docker-compose -f ./docker-compose-cli.yaml up -d cli

docker exec -e "CORE_PEER_LOCALMSPID=100MBMSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/100mb.jet-network.com/users/Admin@100mb.jet-network.com/msp" cli peer chaincode install -n tuna-app -v 1.0 -p github.com/tuna-app
docker exec -e "CORE_PEER_LOCALMSPID=100MBMSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/100mb.jet-network.com/users/Admin@100mb.jet-network.com/msp" cli peer chaincode instantiate -o orderer.jet-network.com:7050 -C mychannel -n tuna-app -v 1.0 -c '{"Args":[""]}' -P "OR ('100MBMSP.peer','ThinkRightMSP.peer')"
sleep 10
docker exec -e "CORE_PEER_LOCALMSPID=100MBMSP" -e "CORE_PEER_MSPCONFIGPATH=opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/100mb.jet-network.com/users/Admin@100mb.jet-network.com/msp" cli peer chaincode invoke -o orderer.jet-network.com:7050 -C mychannel -n tuna-app -c '{"function":"initLedger","Args":[""]}'

printf "\nTotal execution time : $(($(date +%s) - starttime)) secs ...\n\n"
printf "\nStart with the registerAdmin.js, then registerUser.js, then server.js\n\n"
