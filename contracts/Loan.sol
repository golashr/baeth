pragma solidity ^0.4.23;

import "./Index.sol";
import "./Registry.sol";
import "./Token.sol";
import "./LoanStorage.sol";
import "./SafeMath.sol";
import "./LogicOp.sol";

contract Loan {

	using SafeMath for uint256;
	using LogicOp for bool;

	Index private index;

	constructor (address _indexAddress) public{
		require(_indexAddress != 0x0);
		index = Index(_indexAddress);
	}

	modifier onlyUser() {		
		require (Registry(index.getContract('registry')).ifUser(msg.sender)); 
		_; 
	}

	modifier onlyCustomer() {		
		require (Registry(index.getContract('registry')).ifCustomer(msg.sender)); 
		_; 
	}

	modifier onlySpecified(string _name) { 
		require(index.checkContract(msg.sender,_name)); 
		_; 
	}

	/**
	* @dev grant a loan for a specified address 
	* @param _address The address where the loan is to be added
	* @param _fields , _fields[0] - loan amount , _fields[1] - disbursed loan amount, _fields[2] - duration , _fields[3] - eligibility
	*/
	function grantLoan (address _address,uint256[4] _fields, uint256 _loanId) public onlyUser returns(bool res){
		LoanStorage l = LoanStorage(index.getContract('loanS'));
		uint256 temp;
		assert(l.getLoanAmount(_address,_loanId)==temp);
		Registry r = Registry(index.getContract('registry'));
		Token t = Token(index.getContract('token'));
		bool result = r.ifCustomer(_address);
		result = result.and(_fields[0]>=_fields[1]);
		result = result.and(l.setEligibility(_address,_fields[3]));
		result = result.and(l.newLoan(_address, _fields, _loanId));
		assert(result.and(t.grantLoan(_address,_fields[1])));
		return true;	
	}

	/**
	* @dev repay a loan for a specified address and loan ID 
	* @param _address The address of customer repaying the loan
	* @param _fields , _fields[0] - amount, _fields[1] - penalty, _fields[2] - eligibility, _fields[3] - loanId
	*/
	function repayLoan (address _address, uint256[4] _fields) internal returns(bool res) {
		LoanStorage l = LoanStorage(index.getContract('loanS'));
		uint256 temp;
		assert(l.getLoanAmount(_address,_fields[3])!=temp);
		bool result = l.getRemainingDebt(_address,_fields[3])>=_fields[0];
		result = result.and (l.getPenalty(_address,_fields[3])>=_fields[1]);
		result = result.and(l.setEligibility(_address, _fields[2]));
		assert (result.and(l.repayLoan(_address, _fields)));
		return true;
	}


	/**
	* @dev repay a loan through bank for a specified address and loan ID , can only be called by user 
	* @param _address The address of customer repaying the loan
	* @param _fields , _fields[0] - amount, _fields[1] - penalty, _fields[2] - eligibility, _fields[3] - loanId
	*/
	function repayLoanByBank (address _address, uint256[4] _fields) public onlyUser returns(bool res) {
		Registry r = Registry(index.getContract('registry'));
		require (r.ifCustomer(_address));
		assert (repayLoan(_address,_fields));
		LoanStorage l = LoanStorage(index.getContract('loanS'));
		l.emitRepay(_address,_fields[3],0,_fields[0],_fields[1]);
		return true;
	}

	/**
	* @dev repay a loan through tokens for a specified address and loan ID , can only be called by token contract
	* @param _address The address of customer repaying the loan
	* @param _fields , _fields[0] - amount, _fields[1] - penalty, _fields[2] - eligibility, _fields[3] - loanId
	*/
	function repayLoanByTokens (address _address, uint256[4] _fields) public onlySpecified('token') returns(bool res) {
		Registry r = Registry(index.getContract('registry'));
		require (r.ifCustomer(_address));
		assert (repayLoan(_address,_fields));
		LoanStorage l = LoanStorage(index.getContract('loanS'));
		l.emitRepay(_address,_fields[3],1,_fields[0],_fields[1]);
		return true;
	}

	function updateEligibility (address _address,uint256 _amount) public onlyUser returns(bool res){
		assert(LoanStorage(index.getContract('loanS')).setEligibility(_address,_amount));
		return true;
	}

	/**
	* @dev update penalty for a specified address and loan ID, can only be called by CASHe user
	* @param _address The address of customer 
	* @param _penalty penalty to be added 
	* @param _loanId loan Id to which penlaty has to be added  
	*/
	function addPenalty (address _address,uint256 _penalty,uint256 _loanId) public onlyUser returns(bool res){
		LoanStorage l = LoanStorage(index.getContract('loanS'));
		uint256 temp;
		assert(l.getLoanAmount(_address,_loanId)!=temp);
		bool r = l.addPenalty(_address,_penalty,_loanId);
		assert (r.and(l.addTotalPenalty(_address,_penalty)));
		return true;
	}

	function waivePenalty (address _address,uint256 _loanId) public onlyUser returns(bool res){
		LoanStorage l = LoanStorage(index.getContract('loanS'));
		uint256 temp;
		assert(l.getLoanAmount(_address,_loanId)!=temp);
		bool r = l.subTotalPenalty(_address,(l.getPenalty(_address,_loanId)));
		assert (r.and(l.setWaiveFlag(_address,true,_loanId)));
		return true;
	}	

	function getPenalty (address _address, uint256 _loanId) public view onlyUser returns(uint256 res){
		return LoanStorage(index.getContract('loanS')).getPenalty(_address,_loanId);
	}

	function addFrozenAmount (address _address,uint256 _amount)public onlyUser returns(bool res){
		assert(LoanStorage(index.getContract('loanS')).addFrozenAmount(_address,_amount));
		return true;
	}

	function subFrozenAmount (address _address,uint256 _amount)public onlyUser returns(bool res){
		assert(LoanStorage(index.getContract('loanS')).subFrozenAmount(_address,_amount));
		return true;
	}
	
	function getFrozenAmount (address _address)public view returns(uint256 res){
		return LoanStorage(index.getContract('loanS')).getFrozenAmount(_address);
	}

	function setOverdueFlag (address _address,uint256 _loanId)public onlyUser returns(bool res){
		assert(LoanStorage(index.getContract('loanS')).setLoanStatus(_address,_loanId,2));
		return true;
	}

	function setClosedFlag (address _address,uint256 _loanId)public onlyUser returns(bool res){
		assert(LoanStorage(index.getContract('loanS')).setLoanStatus(_address,_loanId,3));
		return true;
	}
	
	function setOverdueAndFreeze (address _address,uint256 _loanId,uint256 _amount)public onlyUser returns(bool res){
		assert(LoanStorage(index.getContract('loanS')).setLoanStatus(_address,_loanId,2));
		assert(LoanStorage(index.getContract('loanS')).addFrozenAmount(_address,_amount));
		return true;
	}

	function isLoanOverDue (address _address,uint256 _loanId) public view returns(bool res){
		assert(LoanStorage(index.getContract('loanS')).checkLoanStatus(_address,_loanId,2));
		return true;
	} 

	function isLoanClosed (address _address,uint256 _loanId) public view returns(bool res){
		assert(LoanStorage(index.getContract('loanS')).checkLoanStatus(_address,_loanId,3));
		return true;
	}

	function getLoanDetails (address _address, uint256 _loanId) public onlyUser view returns(uint256[5]) {
		Registry r = Registry(index.getContract('registry'));
		require (r.ifCustomer(_address));
		uint256[5] memory temp;
		LoanStorage l = LoanStorage(index.getContract('loanS'));
		temp[0] = l.getLoanAmount(_address,_loanId);
		temp[1] = l.getDisbursedLoanAmount(_address,_loanId);
		temp[2] = l.getRemainingDebt(_address,_loanId);
		temp[3] = l.getPenalty(_address,_loanId);
		temp[4] = l.getDuration(_address,_loanId);
		return temp;
	}

	function getLoanProfile (address _address) public onlyUser view returns(uint256[4]) {
		Registry r = Registry(index.getContract('registry'));
		require (r.ifCustomer(_address));
		uint256[4] memory temp;
		LoanStorage l = LoanStorage(index.getContract('loanS'));
		temp[0] = l.getEligibility(_address);
		temp[1] = l.getTotalRemainingDebt(_address);
		temp[2] = l.getTotalPenalty(_address);
		temp[3] = l.getTotalLoans(_address);
		return temp;
	}
}