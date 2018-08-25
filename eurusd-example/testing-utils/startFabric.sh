#!/bin/bash

# Do not rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1
starttime=$(date +%s)
LANGUAGE=${1:-"golang"}
# CC_SRC_PATH refers to the docker cli container
CC_SRC_PATH=github.com/user-chaincode/go
if [ "$LANGUAGE" = "node" -o "$LANGUAGE" = "NODE" ]; then
    CC_SRC_PATH=/opt/gopath/src/github.com/oraclize-connector/node
fi

# Clean the keystore
rm -rf ./hfc-key-store
# Remove all the previously generated containers, representing entities and chaincodes
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker rmi dev-peer0.org1.example.com-oraclize-connector-1.0-7765c3fb5c4224a4a2784d8a64a5488e570d39940695306f78f8e54009d89102
docker rmi dev-peer0.org1.example.com-user-chaincode-1.0-58b4cc4747da6f30d7cb2cea6511560c9fdad78c58ba6881b33801a2d69aebae

# Exit on first error
set -e
# Go in the fabric-samples/basic-network folder to launch the network;
cd ../basic-network
./start.sh

# Now launch the CLI container in order to install, instantiate chaincodes
docker-compose -f ./docker-compose.yml up -d cli

# Instantiating the user chaincode (user-chaincode)
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode install -n user-chaincode -v 1.0 -p "$CC_SRC_PATH" -l "$LANGUAGE"
# Installing the user chaincode (user-chaincode)
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n user-chaincode -l "golang" -v 1.0 -c '{"Args":[""]}' -P "OR ('Org1MSP.member','Org2MSP.member')"

# Instantiating the Oraclize chaincode (oraclize-connector)
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode install -n oraclize-connector -v 1.0 -p "/opt/gopath/src/github.com/oraclize-connector/node" -l "node"
# Installing the Oraclize chaincode (oraclize-connector)
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n oraclize-connector -l "node" -v 1.0 -c '{"Args":[""]}' -P "OR ('Org1MSP.member','Org2MSP.member')"

printf "\nTotal setup execution time : $(($(date +%s) - starttime)) secs...\n\n\n"
printf "Start by installing required packages run 'npm install'\n"
printf "Then run 'node enrollAdmin.js', then 'node registerUser'\n\n"
printf "The 'node user-application-query.js' may be run at anytime once the user has been registered\n\n"

# Go back to the user application folder and install all the node_modules
cd ../oraclize-integration
npm install

# Enroll the admin
node enrollAdmin.js
# Register the user
node registerUser.js