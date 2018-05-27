pragma solidity ^0.4.23;


import "./Pauseable.sol";


/**
* @title IndexContract
* The index contract keeps track of all the contracts with their respective addresses
*/
contract Index is Pauseable{
	mapping (string => address) private contractMapping;
	uint16 private version;

	// mapping (address => bool) active; // for maintaining internal(contract address check)
	
	
	constructor () public {
		version = 1;
		contractMapping['registryS']    = 0x0;
		contractMapping['registry']     = 0x0;
		contractMapping['tokenS']       = 0x0;
		contractMapping['token']        = 0x0;
		contractMapping['loanS']        = 0x0;
		contractMapping['loan']         = 0x0;
	}

	event newContractAdded(address caddress);
	event updatedContractAddress(address uaddress);	

	function updateContract (string _contractName,address _address) public onlyOwner whenNotPaused returns(bool res) {
		bytes memory b = bytes(_contractName);
		require(b[0] != 0);
		// active[getContract(_contractName)] = false;
		// active[_address] = true;
		contractMapping[_contractName] = _address;
		emit updatedContractAddress(_address);
		return true;
	}
	
	function getContract (string _contractName) public view whenNotPaused returns(address res) {
		bytes memory b = bytes(_contractName);
		require(b[0] != 0);
		//assert(b.length > 0);
		return contractMapping[_contractName];
	}

	function checkContract (address _address,string _contractName) public view whenNotPaused returns(bool res){
		bytes memory b = bytes(_contractName);
		require(b[0] != 0);
		//assert(b.length > 0);
		address temp = contractMapping[_contractName];
		return _address == temp && temp != 0x0;
	}

	/* function isInternal (address _address) public returns(bool res){
		return active[msg.sender];
	} */
	
}