#!/bin/sh
export PATH=/home/rahul/work/hyperledger/fabric-samples/bin:${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
CHANNEL_NAME=mychannel

# remove previous crypto material and config transactions
rm -fr crypto-config/*

# generate crypto material
cryptogen generate --config=./crypto-config.yaml
if [ "$?" -ne 0 ]; then
  echo "Failed to generate crypto material..."
  exit 1
fi

# replace private key file names for the two CAs.
ARCH=$(uname -s | grep Darwin)
if [ "$ARCH" == "Darwin" ]; then
  OPTS="-it"
else
  OPTS="-i"
fi

CURRENT_DIR=$PWD
cd crypto-config/peerOrganizations/100mb.jet-network.com/ca/
PRIV_KEY=$(ls *_sk)
cd "$CURRENT_DIR"
sed $OPTS "s/CA1_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose-e2e.yaml
  cd crypto-config/peerOrganizations/org2.example.com/ca/
  PRIV_KEY=$(ls *_sk)
  cd "$CURRENT_DIR"


# generate genesis block for orderer
configtxgen -profile OrdererGenesis -outputBlock ./channel-artifacts/genesis.block
if [ "$?" -ne 0 ]; then
  echo "Failed to generate orderer genesis block..."
  exit 1
fi

# generate channel configuration transaction
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
if [ "$?" -ne 0 ]; then
  echo "Failed to generate channel configuration transaction..."
  exit 1
fi

# generate anchor peer transaction for 100MB
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/100MBMSPanchors.tx -channelID $CHANNEL_NAME -asOrg 100MBMSP
if [ "$?" -ne 0 ]; then
  echo "Failed to generate anchor peer update for 100MBMSP..."
  exit 1
fi

# generate anchor peer transaction for ThinkRight
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/ThinkRightMSPanchors.tx -channelID $CHANNEL_NAME -asOrg ThinkRightMSP
if [ "$?" -ne 0 ]; then
  echo "Failed to generate anchor peer update for ThinkRightMSP..."
  exit 1
fi