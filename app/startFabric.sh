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

printf "\nCreating channel..."
docker exec -e "CORE_PEER_LOCALMSPID=100MBMSP" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/100mb.jet-network.com/peers/peer0.100mb.jet-network.com/tls/ca.crt" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/100mb.jet-network.com/users/Admin@100mb.jet-network.com/msp" -e "CORE_PEER_ADDRESS=peer0.100mb.jet-network.com:7051" cli peer channel create -o orderer.jet-network.com:7050 -c mychannel -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/channel.tx --tls false --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/jet-network.com/orderers/orderer.jet-network.com/msp/tlscacerts/tlsca.jet-network.com-cert.pem

printf "\nPeers join the channel..."
docker exec -e "CORE_PEER_LOCALMSPID=100MBMSP" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/100mb.jet-network.com/peers/peer0.100mb.jet-network.com/tls/ca.crt" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/100mb.jet-network.com/users/Admin@100mb.jet-network.com/msp" -e "CORE_PEER_ADDRESS=peer0.100mb.jet-network.com:7051" cli peer channel join -b mychannel.block

printf "\nInstalling chaincode on peer0.100mb..."
docker exec -e "CORE_PEER_LOCALMSPID=100MBMSP" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/100mb.jet-network.com/peers/peer0.100mb.jet-network.com/tls/ca.crt" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/100mb.jet-network.com/users/Admin@100mb.jet-network.com/msp" -e "CORE_PEER_ADDRESS=peer0.100mb.jet-network.com:7051" cli peer chaincode install -n tuna-app -v 1.0 -l golang -p github.com/chaincode/tuna-app

printf "\nInstantiating chaincode on peer0.100mb..."
docker exec -e "CORE_PEER_LOCALMSPID=100MBMSP" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/100mb.jet-network.com/peers/peer0.100mb.jet-network.com/tls/ca.crt" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/100mb.jet-network.com/users/Admin@100mb.jet-network.com/msp" -e "CORE_PEER_ADDRESS=peer0.100mb.jet-network.com:7051" cli peer chaincode instantiate -o orderer.jet-network.com:7050 --tls false --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/jet-network.com/orderers/orderer.jet-network.com/msp/tlscacerts/tlsca.jet-network.com-cert.pem -C mychannel -n tuna-app -l golang -v 1.0 -c '{"Args":[""]}' -P "OR ('100MBMSP.peer','ThinkRightMSP.peer')"

sleep 10

printf "\nSending invoke transaction on peer0.100mb..."
docker exec -e "CORE_PEER_LOCALMSPID=100MBMSP" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/100mb.jet-network.com/peers/peer0.100mb.jet-network.com/tls/ca.crt" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/100mb.jet-network.com/users/Admin@100mb.jet-network.com/msp" -e "CORE_PEER_ADDRESS=peer0.100mb.jet-network.com:7051" cli peer chaincode invoke -o orderer.jet-network.com:7050 --tls false --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/jet-network.com/orderers/orderer.jet-network.com/msp/tlscacerts/tlsca.jet-network.com-cert.pem -C mychannel -n tuna-app --peerAddresses peer0.100mb.jet-network.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/100mb.jet-network.com/peers/peer0.100mb.jet-network.com/tls/ca.crt -c '{"function":"initLedger","Args":[""]}'

printf "\nTotal execution time : $(($(date +%s) - starttime)) secs ...\n\n"
printf "\nStart with the registerAdmin.js, then registerUser.js, then server.js\n\n"
