package main

import (
	"fmt"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	sc "github.com/hyperledger/fabric/protos/peer"
	oraclizeapi "github.com/oraclize/fabric-api"
)

// SmartContract defines the Smart Contract structure
type SmartContract struct {
}

func (s *SmartContract) Init(APIstub shim.ChaincodeStubInterface) sc.Response {
	return shim.Success(nil)
}

func (s *SmartContract) Invoke(APIstub shim.ChaincodeStubInterface) sc.Response {
	// Retrieve the requested Smart Contract function and arguments
	function, args := APIstub.GetFunctionAndParameters()
	// Route to the appropriate handler function to interact with the ledger appropriately
	if function == "fetchEURUSDviaOraclize" {
		return s.fetchEURUSDviaOraclize(APIstub)
	}
	fmt.Println("function:", function, args[0])
	return shim.Error("Invalid Smart Contract function name.")
}

func (s *SmartContract) fetchEURUSDviaOraclize(APIstub shim.ChaincodeStubInterface) sc.Response {
	fmt.Println("============= START : Calling the oraclize chaincode =============")
	var datasource = "URL"                                                                  // Setting the Oraclize datasource
	var query = "json(https://min-api.cryptocompare.com/data/price?fsym=EUR&tsyms=USD).USD" // Setting the query
	result, proof := oraclizeapi.OraclizeQuery_sync(APIstub, datasource, query, oraclizeapi.TLSNOTARY)
	fmt.Printf("proof: %s", proof)
	fmt.Printf("\nresult: %s\n", result)
	fmt.Println("Do something with the result...")
	fmt.Println("============= END : Calling the oraclize chaincode =============")
	return shim.Success(result)
}

// The main function is only relevant in unit test mode. Only included here for completeness.
func main() {
	// Create a new Smart Contract
	err := shim.Start(new(SmartContract))
	if err != nil {
		fmt.Printf("Error creating new Smart Contract: %s", err)
	}
}
