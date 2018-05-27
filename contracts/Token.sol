pragma solidity ^0.4.23;

import "./Index.sol";
import "./Pauseable.sol";
import "./TokenStorage.sol";
import "./Registry.sol";
import "./Loan.sol";
import "./SafeMath.sol";

contract Token{

	using SafeMath for uint256;
	Index private index;	

	constructor (address _indexAddress) public{
		require(_indexAddress != 0x0);
		index =  Index(_indexAddress);
	}

	modifier onlySpecified(string _name) { 
		require(index.checkContract(msg.sender,_name)); 
		_;
	}	

	modifier onlyCustomer() {		
		require (Registry(index.getContract('registry')).ifCustomer(msg.sender)); 
		_; 
	}

	modifier onlyUser() {		
		require (Registry(index.getContract('registry')).ifUser(msg.sender)); 
		_; 
	}

	event balanceEscrow(uint256 funds);

	function checkCustomer (address _address) internal view returns(bool res){
		return Registry(index.getContract('registry')).ifCustomer(_address);
	}

	function checkEscrow (address _address) internal view returns(bool res){
		return Registry(index.getContract('registry')).isEscrow(_address);
	}

	/**
	* @dev grant a loan for a specified address 
	* @param _address The address where the loan is to be added
	* @param _amount The amount of loan disbursed i.e tokens to be minted
	*/
	function grantLoan (address _address,uint256 _amount) onlySpecified('loan') public returns(bool res) {
		TokenStorage t = TokenStorage(index.getContract('tokenS'));
		assert(t.addTotalSupply(_amount));
		assert(t.increaseBalance(_address,_amount));
		return true;
	}

	function balanceOf () public view returns(uint256 res){
		TokenStorage t = TokenStorage(index.getContract('tokenS'));
		return t.balances(msg.sender);
	}

	/**
	* @dev repay a loan for a specified address and loan ID 
	* @param _address The address of customer repaying the loan
	* @param _fields , _fields[0] - amount, _fields[1] - penalty, _fields[2] - eligibility, _fields[3] - loanId
	*/
	function repayLoan(address _address, uint256[4] _fields) internal returns(bool res) {
		TokenStorage t = TokenStorage(index.getContract('tokenS'));
		uint256 totalTokens = _fields[0].add(_fields[1]);
		require (t.getBalance(_address)>=totalTokens);
		Loan l = Loan(index.getContract('loan'));
		assert (l.repayLoanByTokens(_address,_fields));
		assert (t.decreaseBalance(_address, totalTokens));
		assert (t.subTotalSupply(totalTokens));
		return true;
	}

	/**
	* @dev repay a loan by tokens for a specified address and loan ID , can only be acessed by customer
	* @param _fields , _fields[0] - amount, _fields[1] - penalty, _fields[2] - eligibility, _fields[3] - loanId
	*/
	function repayLoanByTokens(uint256[4] _fields) onlyCustomer public returns(bool res)  {
		assert (repayLoan(msg.sender,_fields));
		return true;
	}
	
	/**
	* @dev recover the tokens for non repayment of loan for a specified address and loan ID , can only be accessed by user
	* @param _address The address of customer repaying the loan
	* @param _fields , _fields[0] - amount, _fields[1] - penalty, _fields[2] - eligibility, _fields[3] - loanId
	*/
	function recoverLoan(address _address, uint256[4] _fields) onlyUser public returns(bool res){
		assert (repayLoan(_address,_fields));
		return true;
	}
	
	function receiveFunds(address _address,address _escrow) onlySpecified('registry') public returns(bool res){
		TokenStorage t = TokenStorage(index.getContract('tokenS'));
		uint256 funds  = t.getBalance(_escrow);
		emit balanceEscrow(funds);
		bool result = t.decreaseBalance(_escrow,funds);
		result = result && t.increaseBalance(_address,funds);
		assert (result);
		assert(t.emitReceivedFunds(_address,_escrow));
		return true;
	}

	function transfer (address _from,address _to,uint256 _amount) internal returns(bool res){
		TokenStorage t = TokenStorage(index.getContract('tokenS'));
		uint256 frozenAmount = Loan(index.getContract('loan')).getFrozenAmount(_from);
		require(t.balances(_from).sub(frozenAmount) >= _amount);
		bool result = t.increaseBalance(_to,_amount);
		result = result && t.decreaseBalance(_from,_amount);
		return result;
	}

	function transferTokenToEscrow (address _from ,address _to,uint256 _amount) internal returns(bool res){
		Registry r = Registry(index.getContract('registry'));
		bool result = r.activateEscrow(_to);
		result = result && transfer(_from,_to,_amount);
		return result;
	}

	function transferToken(address _to,uint256 _amount) public returns (bool res){
		bool result = checkCustomer(msg.sender);
		assert (result);
		if(checkCustomer(_to))
			result = transfer(msg.sender,_to,_amount);
		else
			result = transferTokenToEscrow(msg.sender,_to,_amount);
		assert (result);
		return true;
	}

	function revertTransfer(address _from,address _to,uint256 _amount) onlyUser public returns (bool res){
		bool result = checkEscrow(_from) && checkCustomer(_to);
		assert (result);
		result = transfer(_from,_to,_amount);
		assert (result);
		return true;
	}

	function cashoutTokens(uint256 _amount) public returns(bool res){
		TokenStorage ts = TokenStorage(index.getContract('tokenS'));
		bool result = checkCustomer(msg.sender);
		assert (result);
		assert(ts.addCashOutAmount(msg.sender,_amount));
		assert(transfer(msg.sender,index.getContract('tokenS'),_amount));
		return true;
	}

	function confirmCashOut (address _address,uint256 _amount) onlyUser public returns(bool res){
		TokenStorage ts = TokenStorage(index.getContract('tokenS'));
		assert(checkCustomer(_address));
		assert(ts.subTotalSupply(_amount));
		assert(ts.subCashOutAmount(_address,_amount));
		assert(ts.decreaseBalance(index.getContract('tokenS'),_amount));
		return true;
	}

	function revertCashOut (address _address,uint256 _amount) onlyUser public  returns(bool res){
		TokenStorage ts = TokenStorage(index.getContract('tokenS'));
		assert(checkCustomer(_address));
		assert(ts.subCashOutAmount(_address,_amount));
		assert(ts.decreaseBalance(index.getContract('tokenS'),_amount));
		assert(ts.increaseBalance(_address,_amount));
		return true;
	}	
}
