pragma solidity ^0.4.23;

import "./Index.sol";
import "./Pauseable.sol";
import "./SafeMath.sol";
import "./LogicOp.sol";

/**
* @title Ledger
* The Ledger contract stores the data for all the loan dispersed maintains only the data structure
* of the loan details
*/
contract LoanStorage{ 

	using SafeMath for uint256;
	using LogicOp for bool;	

	enum LoanStatus {
		ACTIVE,
		OVERDUE, 
		CLOSED
	}												//todo define all statuses

	struct Loan {
		uint256 loanAmount;							//loan amount granted , includes interest, other charges etc
		uint256 disbursedLoanAmount;				//loan amount customer got , excluding charges 
		uint256 remainingDebt;						//amount the customer owes to the bank , excludes penalty
		uint256 penalty;							//penalty amount the customer owes to the bank
		uint256 duration;							//days
		uint256 startDate;
		bool penaltyFlag;
		LoanStatus loanStatus;
	}	

	struct LoanProfile {
		uint256 eligibility;
		uint256 totalRemainingDebt;
		uint256 totalPenalty;						
		mapping (uint256 => Loan) allLoans;
		uint256 totalLoans;	
		uint256 frozenAmount;
	}

	Index private index;	
	mapping (address => LoanProfile) private userLoanProfile;
	
	constructor (address _indexAddress) public {
		require(_indexAddress != 0x0);
		index = Index(_indexAddress);
	}

	event newLoanAdded(address indexed _address,uint256 _loanId,uint256 _loanAmount);
	event loanRepay(address indexed _address,uint256 _loanId,uint256 indexed _how, uint256 _pricipal, uint256 _penalty);
	event updatedEligibility(address indexed _address,uint256 _value);

	function emitRepay (address _address,uint256 _loanId,uint256 _how, uint256 _pricipal, uint256 _penalty) public onlySpecified('loan') returns(bool res) {
      	emit loanRepay(_address,_loanId,_how,_pricipal,_penalty);
      	return true;
  	}
	
	modifier onlySpecified(string _contractName) { 
		require (index.checkContract(msg.sender,_contractName)); 
		_; 
	}	

	//====================================================================================================================
	//====================================================================================================================

	// getters and setters

	// LOAN STATUS 

	function setLoanStatus (address _address,uint256 _loanId,uint8 flag)public returns(bool res) {
		if(flag == 1)
		    userLoanProfile[_address].allLoans[_loanId].loanStatus = LoanStatus.ACTIVE;
		else if(flag == 2)
			userLoanProfile[_address].allLoans[_loanId].loanStatus = LoanStatus.OVERDUE;
		else if(flag == 3)
			userLoanProfile[_address].allLoans[_loanId].loanStatus = LoanStatus.CLOSED;
		else
			assert (false);
		return true;
			
	}
	
	function checkLoanStatus (address _address,uint256 _loanId,uint8 flag)public view returns(bool res) {
		if(flag == 1)
		    return userLoanProfile[_address].allLoans[_loanId].loanStatus == LoanStatus.ACTIVE;
		else if(flag == 2)
			return userLoanProfile[_address].allLoans[_loanId].loanStatus == LoanStatus.OVERDUE;
		else if(flag == 3)
			return userLoanProfile[_address].allLoans[_loanId].loanStatus == LoanStatus.CLOSED;
		else
			assert (false);
		return true;
	}

	//=====================================ELIGIBILITY=====================================================//

	function setEligibility (address _address,uint256 _amount) onlySpecified('loan') public returns(bool res) {
		userLoanProfile[_address].eligibility = _amount;
		emit updatedEligibility(_address, _amount);
		return true;
	}

	function addEligibility (address _address,uint256 _amount) onlySpecified("loan") public returns(bool res) {
	    uint256 e = userLoanProfile[_address].eligibility;
		userLoanProfile[_address].eligibility = e.add(_amount);
		emit updatedEligibility(_address, e.add(_amount));
		return true;
	}

	function subEligibility (address _address,uint256 _amount) onlySpecified("loan") public returns(bool res) {
	    uint256 e = userLoanProfile[_address].eligibility;
		userLoanProfile[_address].eligibility = e.sub(_amount);
		emit updatedEligibility(_address, e.sub(_amount));
		return true;
	}		
	
	function getEligibility (address _address) onlySpecified('loan') public view returns(uint256 res) {
		return userLoanProfile[_address].eligibility;
	}

	//=============================================TOTAL DEBT==================================================//

	function addTotalRemainingDebt (address _address,uint256 _amount) onlySpecified("loan") public returns(bool res) {
	    uint256 u = userLoanProfile[_address].totalRemainingDebt;
		userLoanProfile[_address].totalRemainingDebt = u.add(_amount);
		return true;
	}

	function subTotalRemainingDebt (address _address,uint256 _amount) onlySpecified("loan") public returns(bool res) {
		uint256 u = userLoanProfile[_address].totalRemainingDebt;
		userLoanProfile[_address].totalRemainingDebt = u.sub(_amount);
		return true;
	}	

	function setTotalRemainingDebt (address _address,uint256 _amount) onlySpecified('loan') public returns(bool res) {
		userLoanProfile[_address].totalRemainingDebt = _amount;
		return true;
	}	

	function getTotalRemainingDebt (address _address) onlySpecified('loan') public view returns(uint256 res) {
		return userLoanProfile[_address].totalRemainingDebt;
	}

	//=============================================TOTAL PENALTY=============================================

	function addTotalPenalty (address _address,uint256 _amount) onlySpecified("loan") public returns(bool res) {
	    uint256 u = userLoanProfile[_address].totalPenalty;
		userLoanProfile[_address].totalPenalty = u.add(_amount);
		return true;
	}
	
	function subTotalPenalty (address _address,uint256 _amount) onlySpecified("loan") public returns(bool res) {
		uint256 u = userLoanProfile[_address].totalPenalty;
		userLoanProfile[_address].totalPenalty = u.sub(_amount);
		return true;
	}
	

	function setTotalPenalty (address _address,uint256 _amount) onlySpecified('loan') public returns(bool res) {
		userLoanProfile[_address].totalPenalty = _amount;
		return true;
	}	

	function getTotalPenalty (address _address) onlySpecified('loan') public view returns(uint256 res) {
		return userLoanProfile[_address].totalPenalty;
	}


	//============================================= PENALTY =============================================

	function addPenalty (address _userAddress,uint256 _amount,uint256 loanId) onlySpecified('loan') public returns(bool res) {
		uint256 u = userLoanProfile[_userAddress].allLoans[loanId].penalty;
		userLoanProfile[_userAddress].allLoans[loanId].penalty = u.add(_amount);
		return true;	
	}

	function subPenalty (address _userAddress,uint256 _amount,uint256 loanId) onlySpecified('loan') public returns(bool res){
		uint256 u = userLoanProfile[_userAddress].allLoans[loanId].penalty;
		userLoanProfile[_userAddress].allLoans[loanId].penalty = u.sub(_amount);	
		return true;
	}

	function setPenalty (address _userAddress,uint256 _amount,uint256 loanId) onlySpecified('loan') public returns(bool res) {
		userLoanProfile[_userAddress].allLoans[loanId].penalty = _amount;
		return true;
	}

	function getPenalty (address _userAddress,uint256 loanId) public onlySpecified('loan') view returns(uint256 res){
		return userLoanProfile[_userAddress].allLoans[loanId].penalty;
	}

	//=============================================REMAINING DEBT=============================================

	function addRemainingDebt (address _userAddress,uint256 _amount,uint256 loanId) onlySpecified('loan') public returns(bool res) {
		uint256 u = userLoanProfile[_userAddress].allLoans[loanId].remainingDebt;
		userLoanProfile[_userAddress].allLoans[loanId].remainingDebt = u.add(_amount);
		return true;	
	}

	function subRemainingDebt (address _userAddress,uint256 _amount,uint256 loanId) onlySpecified('loan') public returns(bool res){
		uint256 u = userLoanProfile[_userAddress].allLoans[loanId].remainingDebt;
		userLoanProfile[_userAddress].allLoans[loanId].remainingDebt = u.sub(_amount);	
		return true;
	}

	function setRemainingDebt (address _userAddress,uint256 _amount,uint256 loanId) onlySpecified('loan') public returns(bool res) {
		userLoanProfile[_userAddress].allLoans[loanId].remainingDebt = _amount;
		return true;
	}

	function getRemainingDebt (address _userAddress,uint256 loanId)public onlySpecified('loan') view returns(uint256 res){
		return userLoanProfile[_userAddress].allLoans[loanId].remainingDebt;
	}

	// =============================================LOAN AMOUNT	=============================================

	function getLoanAmount (address _userAddress,uint256 loanId)public onlySpecified('loan') view returns(uint256 res) {
		return userLoanProfile[_userAddress].allLoans[loanId].loanAmount;
	}

	function addLoanAmount (address _userAddress,uint256 _amount,uint256 loanId)public onlySpecified('loan') returns(bool res) {
		uint256 u = userLoanProfile[_userAddress].allLoans[loanId].loanAmount;
		userLoanProfile[_userAddress].allLoans[loanId].loanAmount = u.add(_amount);	
		return true;
	}
	
	function subLoanAmount (address _userAddress,uint256 _amount,uint256 loanId)public onlySpecified('loan') returns(bool res) {
		uint256 u = userLoanProfile[_userAddress].allLoans[loanId].loanAmount;
		userLoanProfile[_userAddress].allLoans[loanId].loanAmount = u.sub(_amount);	
		return true;
	}

	function setLoanAmount (address _userAddress,uint256 _amount,uint256 loanId)public onlySpecified('loan') returns(bool res){
		userLoanProfile[_userAddress].allLoans[loanId].loanAmount = _amount;
		return true;
	}

	// ============================================= DISBURSED LOAN AMOUNT =============================================

	function getDisbursedLoanAmount (address _userAddress,uint256 loanId) public onlySpecified('loan') view returns(uint256 res) {
		return userLoanProfile[_userAddress].allLoans[loanId].disbursedLoanAmount;
	}

	function addDisbursedLoanAmount (address _userAddress,uint256 _amount,uint256 loanId) public onlySpecified('loan') returns(bool res) {
		uint256 u = userLoanProfile[_userAddress].allLoans[loanId].disbursedLoanAmount;
		userLoanProfile[_userAddress].allLoans[loanId].disbursedLoanAmount = u.add(_amount);	
		return true;
	}
	
	function subDisbursedLoanAmount (address _userAddress,uint256 _amount,uint256 loanId) public onlySpecified('loan') returns(bool res) {
		uint256 u = userLoanProfile[_userAddress].allLoans[loanId].disbursedLoanAmount;
		userLoanProfile[_userAddress].allLoans[loanId].disbursedLoanAmount = u.sub(_amount);	
		return true;
	}

	function setDisbursedLoanAmount (address _userAddress,uint256 _amount,uint256 loanId) public onlySpecified('loan') returns(bool res){
		userLoanProfile[_userAddress].allLoans[loanId].disbursedLoanAmount = _amount;
		return true;
	}

	// ============================================= GET LOANS =============================================

	function getTotalLoans (address _address) onlySpecified('loan') public view returns(uint256 res) {
		return userLoanProfile[_address].totalLoans;
	}

	function getDuration (address _address,uint256 loanId) onlySpecified('loan')public view returns(uint256 res) {
		return userLoanProfile[_address].allLoans[loanId].duration;
	}

	// ============================================= START DATE =============================================

	function setStartDate (address _userAddress, uint256 loanId) public onlySpecified('loan') returns(bool res){
		userLoanProfile[_userAddress].allLoans[loanId].startDate = now;
		return true;
	}

	function getStartDate (address _userAddress, uint256 loanId) public onlySpecified('loan') view returns(uint256 res) {
		return userLoanProfile[_userAddress].allLoans[loanId].startDate;
	}

	// ============================================= WAIVE FLAG ============================================= 

	function setWaiveFlag(address _address,bool _flag,uint256 _loanId) public onlySpecified('loan') returns(bool res){
		userLoanProfile[_address].allLoans[_loanId].penaltyFlag = _flag;
		return true;
	}

	function getWaiveFlag (address _address,uint256 _loanId) public onlySpecified('loan') view returns(bool res){
		return userLoanProfile[_address].allLoans[_loanId].penaltyFlag;
	}
	
	// ============================================= FREEZE AMOUNT =============================================

	function addFrozenAmount (address _address,uint256 _amount)public onlySpecified('loan') returns(bool res){
		uint256 f = userLoanProfile[_address].frozenAmount;
		userLoanProfile[_address].frozenAmount = f.add(_amount);
		return true;
	}

	function subFrozenAmount (address _address,uint256 _amount)public onlySpecified('loan') returns(bool res){
		uint256 f = userLoanProfile[_address].frozenAmount;
		userLoanProfile[_address].frozenAmount = f.sub(_amount);
		return true;
	}
	
	function getFrozenAmount (address _address)public view onlySpecified('loan') returns(uint256 res){
		return userLoanProfile[_address].frozenAmount;
	}

	function setFrozenAmount (address _address,uint256 _amount)public onlySpecified('loan') returns(bool res){
		userLoanProfile[_address].frozenAmount = _amount;
		return true;
	}

	//============================================= LOAN AND REPAY============================================= 


	function newLoan (address _address,uint256[4] _fields, uint256 _loanId) onlySpecified('loan') public returns(bool res) {
		uint256 total = userLoanProfile[_address].totalLoans;
		uint256 totalDebt = userLoanProfile[_address].totalRemainingDebt;
		userLoanProfile[_address].allLoans[_loanId] = Loan(
			_fields[0],
			_fields[1],
			_fields[0],
			0,
			_fields[2],
			now,
			false,
			LoanStatus.ACTIVE
		);
		userLoanProfile[_address].totalLoans = total.add(1);
		userLoanProfile[_address].totalRemainingDebt = totalDebt.add(_fields[1]);
		emit newLoanAdded(_address,_loanId,_fields[0]);
		return true;
	}

	function repayLoan (address _address,uint256[4] _fields) public onlySpecified('loan') returns(bool res) {
		bool result = subRemainingDebt(_address, _fields[0], _fields[3]);
		result = result.and(subPenalty(_address, _fields[1], _fields[3]));
		result = result.and(subTotalRemainingDebt(_address, _fields[0]));
		result = result.and(subTotalPenalty(_address, _fields[1]));
		return result;
	}

}