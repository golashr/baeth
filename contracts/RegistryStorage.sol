pragma solidity ^0.4.23;


import "./SafeMath.sol";
import "./Index.sol";
/**
* @title RegistryDao
* @dev The Registry contract is pausable and facilitates basic user & customer onboarding process
* functions, this simplifies the implementation of "user permissions".
*/
contract RegistryStorage{

	using SafeMath for uint256;

	enum State {
		UNREGISTERED,
		ACTIVE, 
		FREEZE, 
		BLOCK
	}
	
	struct User {
		uint256 identifier;
		bool paused;  		// to be changed
	}

	struct Customer{
		uint256 identifier;
		State state;
	}

	mapping (address => User)     private userMapping;
	mapping (address => Customer) private customerMapping;
	mapping (address => bool)     private escrowMapping;
	

	Index private index;

	constructor (address _indexAddress,address _address) public {
		require(_indexAddress != 0x0);
		index = Index(_indexAddress);
		userMapping[_address].identifier = 0x21233112312; //add the first user 
		userMapping[_address].paused = false;
	}
	
	event customerRegistered(address indexed _address,uint256 id);
	event userRegistered(address indexed _address,uint256 id);
	event pausedEntity(address indexed _customer,bool value,string who);
	event escrowRegistered(address indexed _customer,address indexed );

	modifier onlySpecified(string _contractName) { 
		require (index.checkContract(msg.sender,_contractName)); 
		_; 
	}			

	function isUser(address _user) public view returns(bool res) {
		User memory u = userMapping[_user];
		uint256 temp;
		return (!u.paused)&&(temp!=u.identifier);
	}

	function isCustomer (address _customer) public view returns(bool res) {
		Customer memory c = customerMapping[_customer];
		uint256 temp;
		return (c.state != State.UNREGISTERED)&&(temp!=c.identifier);
	}

	function isCustomerFrozen (address _user) public view returns(bool res){
		return customerMapping[_user].state == State.FREEZE;
	}

	function isCustomerBlocked (address _user)public view returns(bool res){
		return customerMapping[_user].state == State.BLOCK;
	}	

	function isCustomerActive (address _user)public view returns(bool res){
		return customerMapping[_user].state == State.ACTIVE;
	}	

	function isEscrow(address _address)public view returns(bool res){
		return escrowMapping[_address];
	}	

	function registerUser(address _user, uint256 _user_identifier) public onlySpecified('registry') returns (bool){
		require(!isUser(_user));
		require (_user_identifier !=0 );
		userMapping[_user].identifier = _user_identifier;
		userMapping[_user].paused     = false;
		emit userRegistered(_user,_user_identifier);
		return true;
	}

	function registerCustomer(address _customer,uint256 _details)public onlySpecified('registry') returns(bool res) {
		require(!isCustomer(_customer));
		require (_details !=0 );
		customerMapping[_customer].identifier = _details;
		customerMapping[_customer].state = State.ACTIVE;
		emit customerRegistered(_customer,_details);
		return true;
	}

	function activateEscrow(address _address) public onlySpecified('registry') returns (bool res){
		//require(!isEscrow(_address));
		escrowMapping[_address] = true;
		return true;
	}

	function deactivateEscrow (address _address) public onlySpecified('registry') returns(bool res){
		require (isEscrow(_address));
		escrowMapping[_address] = false;
		return true;
	}

	function getUser(address _user) public view returns (uint256){
		User memory u = userMapping[_user];
		return u.identifier;
	}

	function getCustomer (address _customer)public view returns(uint256) {
		Customer memory c = customerMapping[_customer];
		return c.identifier;
	}

	function pauseUser(address _address) public onlySpecified('registry') returns(bool){
		require(isUser(_address));
		userMapping[_address].paused = true;
		emit pausedEntity(_address,true,"user");
		return true;
	}

	function activateUser(address _address) public onlySpecified('registry') returns(bool){
		require(userMapping[_address].paused);
		userMapping[_address].paused = false;
		emit pausedEntity(_address,false,"user");
		return true;
	}
	
	function freezeCustomer (address _address) public onlySpecified('registry') returns(bool res){
		require (!isCustomerFrozen(_address));
		customerMapping[_address].state = State.FREEZE;
		return true;
	}

	function unFreezeCustomer (address _address)public onlySpecified('registry') returns(bool res){
		require (isCustomerFrozen(_address));
		customerMapping[_address].state = State.ACTIVE;
		return true;
	}
	
	function blockCustomer(address _address)public onlySpecified('registry') returns(bool res){
		customerMapping[_address].state = State.BLOCK;
		return true;
	}

	function unBlockCustomer(address _address)public onlySpecified('registry') returns (bool res){
		require(isCustomerBlocked(_address));
		customerMapping[_address].state = State.ACTIVE;
		return true;
	}
	
}