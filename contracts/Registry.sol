pragma solidity ^0.4.23;


import "./Index.sol";
import "./RegistryStorage.sol";
import "./Token.sol";

/**
 * The Registry contract implements functionality for 
 */
contract Registry{

	Index private index;

	constructor (address _indexAddress) public{
		require(_indexAddress != 0x0);
		index = Index(_indexAddress);
	}

	modifier onlySpecified(string _contractName) { 
		require (index.checkContract(msg.sender,_contractName)); 
		_; 
	}

	modifier isUser() { 
		assert(ifUser(msg.sender));
		_; 
	}

	modifier isCustomer() { 
		assert(ifCustomer(msg.sender));
		_; 
	}	

	function ifUser (address _address)public view returns(bool res) {
		return RegistryStorage(index.getContract("registryS")).isUser(_address);
	}

	function ifCustomer (address _address)public view returns(bool res) {
		return RegistryStorage(index.getContract("registryS")).isCustomer(_address);
	}	

	function isCustomerFrozen (address _address) public view returns(bool res) {
		return RegistryStorage(index.getContract("registryS")).isCustomerFrozen(_address);
	}

	function isCustomerBlocked (address _address) public view returns(bool res) {
		return RegistryStorage(index.getContract("registryS")).isCustomerBlocked(_address);
	}

	function isCustomerActive (address _address) public view returns(bool res) {
		return RegistryStorage(index.getContract("registryS")).isCustomerActive(_address);
	}

	function isEscrow (address _escrow)public view returns(bool res){
		RegistryStorage rs = RegistryStorage(index.getContract("registryS"));
		return rs.isEscrow(_escrow);
	} 

	/**
	* @dev register a new CASHe user , can only be done by another existing user 
	* @param _address The address of user
	* @param _id Identifier of the User
	*/
	function registerUser (address _address,uint256 _id) public isUser returns(bool res) {
		assert(RegistryStorage(index.getContract("registryS")).registerUser(_address,_id));
		return true;
	}

	function pauseUser(address _address) public isUser returns(bool res){
		assert(RegistryStorage(index.getContract("registryS")).pauseUser(_address));
		return true;
	}

	function activateUser(address _address) public isUser returns(bool res){
		assert(RegistryStorage(index.getContract("registryS")).activateUser(_address));
		return true;
	}

	/**
	* @dev register a new CASHe customer , can only be done by existing CASHe User 
	* @param _address The address of customer 
	* @param _id Identifier of the Customer
	*/
	function registerCustomer(address _address,uint256 _id) public isUser returns(bool res) {
		assert(RegistryStorage(index.getContract("registryS")).registerCustomer(_address,_id));
		return true;
	}

	/**
	* @dev register a new CASHe customer who has an existing escrow  
	* @param _address The address of customer  
	* @param _address The address of escrow 
	* @param _id Identifier of the Customer
	*/
	function registerCustomerEscrow(address _address,address _escrow,uint256 _id) public isUser returns(bool res){
		RegistryStorage rs = RegistryStorage(index.getContract("registryS"));
		assert (rs.isEscrow(_escrow));
		assert (rs.registerCustomer(_address,_id));
		assert (Token(index.getContract("token")).receiveFunds(_address,_escrow));
		assert (rs.deactivateEscrow(_escrow));		
		return true;
	}	
	
	function getCustomer(address _address) public view isUser returns(uint256 res) {
		return RegistryStorage(index.getContract("registryS")).getCustomer(_address);
	}

	function getUser(address _address) public view isUser returns(uint256 res) {
		return RegistryStorage(index.getContract("registryS")).getUser(_address);
	}
	
	/**
	* @dev pause an Escrow account 
	* @param _address Address of the escrow to be paused
	*/
	function pauseEscrow (address _address)public isUser returns(bool res){
		assert (RegistryStorage(index.getContract('registryS')).deactivateEscrow(_address));
		return true;				
	}	

	/**
	* @dev activate an escrow account 
	* @param _address Address of the escrow to be activated
	*/
	function activateEscrow (address _address)public returns(bool res){
		bool result = (ifUser(msg.sender) || (index.getContract('token') == msg.sender));
		assert(result);
		assert (RegistryStorage(index.getContract('registryS')).activateEscrow(_address));
		return true;		
	}
	
	function freezeCustomer (address _address) public onlySpecified('loan') returns(bool res){
		assert(RegistryStorage(index.getContract('registryS')).freezeCustomer(_address));
		return true;
	}

	function unFreezeCustomer (address _address)public onlySpecified('loan') returns(bool res){
		assert(RegistryStorage(index.getContract('registryS')).unFreezeCustomer(_address));
		return true;
	}

	
														
}