"use strict";
const Fabric_Client = require("fabric-client")
const path = require("path")
// Network settings
const fabric_client = new Fabric_Client() // Creating a new client
const channel = fabric_client.newChannel("mychannel") // Setting the channel
const peer = fabric_client.newPeer("grpc://localhost:7051") // Setting the peer
const store_path = path.join(__dirname, "hfc-key-store") // Setting the store path for keys and certs
console.log("Store path: " + store_path)
channel.addPeer(peer) // Adding the peer created to the channel
let member_user = null // Var used to save the application user
// Querying the chaincode
Fabric_Client.newDefaultKeyValueStore({ path: store_path
}).then(state_store => {
	fabric_client.setStateStore(state_store) // Assign the store to the fabric client
	var crypto_suite = Fabric_Client.newCryptoSuite()
	var crypto_store = Fabric_Client.newCryptoKeyStore({ path: store_path }) // Same location for the state store (certs) and the crypto store (keys)
	crypto_suite.setCryptoKeyStore(crypto_store)
	fabric_client.setCryptoSuite(crypto_suite)
	return fabric_client.getUserContext("user1", true) // Get the enrolled user from persistence, this user will sign all requests
}).then(user_from_store => {
	member_user =
		user_from_store && user_from_store.isEnrolled()
			? (console.log("\x1b[32m%s\x1b[0m", "Successfully loaded user1 from persistence"), user_from_store)
			: new Error("\x1b[31m%s\x1b[0m", "Failed to get user1.... run registerUser.js")
	const request = { chaincodeId: "user-chaincode", fcn: "fetchEURUSDviaOraclize", args: [] } // targets : --- letting this default to the peers assigned to the channel
	console.log("Query sent, waiting for the result...");
	return channel.queryByChaincode(request) // Send the query proposal to the peer
}).then(query_responses => {
	let oraclizeQueryResult // Used to store the oraclize query result
	!query_responses || query_responses.length != 1 // query_responses could have more than one results if there multiple peers were used as targets
		? console.error("\x1b[31m%s\x1b[0m", "No payloads were returned from query")
		: query_responses[0] instanceof Error // Checking error in the response
		? console.error("\x1b[31m%s\x1b[0m", "Error from query: ", query_responses[0]) // Print the query error
		: (
			oraclizeQueryResult = query_responses[0].toString(),
			console.log("\x1b[32m%s\x1b[0m","User receive the result: ", oraclizeQueryResult)
		)
}).catch(err => console.error("\x1b[31m%s\x1b[0m", "Failed to query successfully :: " + err))