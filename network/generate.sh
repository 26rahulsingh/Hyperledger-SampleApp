#!/bin/sh
export PATH=./bin:${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
CHANNEL_NAME=mychannel

# remove previous crypto material and config transactions
rm -Rf crypto-config/*
rm -Rf channel-artifacts/*

if [ "$?" -ne 0 ]; then
  echo "cryptogen tool not found. exiting"
  exit 1
fi
echo
echo "##########################################################"
echo "##### Generate certificates using cryptogen tool #########"
echo "##########################################################"

set -x
cryptogen generate --config=./crypto-config.yaml
res=$?
set +x
if [ $res -ne 0 ]; then
  echo "Failed to generate certificates..."
  exit 1
fi
echo

# sed on MacOSX does not support -i flag with a null extension. We will use
# 't' for our back-up's extension and delete it at the end of the function
ARCH=$(uname -s | grep Darwin)
if [ "$ARCH" = "Darwin" ]; then
  OPTS="-it"
else
  OPTS="-i"
fi

# Copy the template to the file that will be modified to add the private key
cp docker-compose-cli-template.yaml docker-compose-cli.yaml

# The next steps will replace the template's contents with the
# actual values of the private key file names for the two CAs.
CURRENT_DIR=$PWD
cd crypto-config/peerOrganizations/100mb.jet-network.com/ca/
PRIV_KEY=$(ls *_sk)
cd "$CURRENT_DIR"
sed $OPTS "s/CA1_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose-cli.yaml
cd crypto-config/peerOrganizations/thinkright.jet-network.com/ca/
PRIV_KEY=$(ls *_sk)
cd "$CURRENT_DIR"
sed $OPTS "s/CA2_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose-cli.yaml
# If MacOSX, remove the temporary backup of the docker-compose file
if [ "$ARCH" = "Darwin" ]; then
  rm docker-compose-cli.yamlt
fi


# Generate orderer genesis block, channel configuration transaction and
# anchor peer update transactions
echo "##########################################################"
echo "#########  Generating Orderer Genesis block ##############"
echo "##########################################################"
# Note: For some unknown reason (at least for now) the block file can't be
# named orderer.genesis.block or the orderer will fail to launch!
set -x
configtxgen -profile OrdererGenesis -channelID byfn-sys-channel -outputBlock ./channel-artifacts/genesis.block
res=$?
set +x
if [ $res -ne 0 ]; then
  echo "Failed to generate orderer genesis block..."
  exit 1
fi

echo
echo "#################################################################"
echo "### Generating channel configuration transaction 'channel.tx' ###"
echo "#################################################################"
set -x
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
res=$?
set +x
if [ $res -ne 0 ]; then
  echo "Failed to generate channel configuration transaction..."
  exit 1
fi

echo
echo "#################################################################"
echo "#######    Generating anchor peer update for 100MBMSP   #########"
echo "#################################################################"
set -x
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/100MBMSPanchors.tx -channelID $CHANNEL_NAME -asOrg 100MBMSP
res=$?
set +x
if [ $res -ne 0 ]; then
  echo "Failed to generate anchor peer update for 100MBMSP..."
  exit 1
fi

echo
echo "#################################################################"
echo "#######    Generating anchor peer update for ThinkRightMSP   ####"
echo "#################################################################"
set -x
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/ThinkRightMSPanchors.tx -channelID $CHANNEL_NAME -asOrg ThinkRightMSP
res=$?
set +x
if [ $res -ne 0 ]; then
  echo "Failed to generate anchor peer update for ThinkRightMSP..."
  exit 1
fi
echo

