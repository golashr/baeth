pragma solidity ^0.4.23;


import "./BasicToken.sol";
import "./SafeMath.sol";
import "./Index.sol";



/**
 * @title TokenDao
 * @dev The TokenDao is ownable, burnable main crypto token of BAETHe system.
 * and maintains the complete ledger as well
 */
contract TokenStorage is BasicToken{

  using SafeMath for uint256;

  uint8 private decimals = 15;                  //How many decimals to show.
  Index private index;

  struct pending{
    uint256 cashout;
    uint256 recover;
  }

  mapping (address => pending) pendingPayments;  

  event receivedfunds(address indexed _address, address indexed _escrow);
  event repayLoan(address indexed _address, uint256 _principal, uint256 _penalty);

  function getDecimals() public view returns (uint8) { 
    return decimals;
  }

  constructor (address _indexAddress) public{
    require(_indexAddress != 0x0);
    index = Index(_indexAddress);
  }  
  
  modifier onlySpecified(string _contractName) { 
    require (index.checkContract(msg.sender,_contractName)); 
    _; 
  }

  function emitTransfer (address _from,address _to,uint256 _value) public onlySpecified('token') returns(bool res) {
      emit Transfer(_from,_to,_value);
      return true;
  }
  
  function emitReceivedFunds (address _address,address _escrow) public onlySpecified('token') returns(bool res){
    emit receivedfunds(_address,_escrow);
    return true;
  }
  

  //====================================================================================================================
  //====================================================================================================================

  // getters and setters


  // =================================== BALANCE =======================================//

  function setBalance (address _address,uint256 _amount) public onlySpecified('token') returns(bool res) {
    balances[_address] = _amount;
    return true;
  }

  function getBalance (address _address) public onlySpecified('token') view returns(uint256 res){
    return balances[_address];
  }

  function increaseBalance (address _address,uint256 _amount)public onlySpecified('token') returns(bool res){
    uint256 b = balances[_address];
    balances[_address] = b.add(_amount);
    return true;
  }

  function decreaseBalance (address _address,uint256 _amount)public onlySpecified('token') returns(bool res){
    uint256 b = balances[_address];
    balances[_address] = b.sub(_amount);
    return true;
  }

  // ======================================== TOTAL SUPPLY ========================================//

  function addTotalSupply (uint256 _amount)  public returns(bool res){
    uint256 b = totalSupply;
    totalSupply =  b.add(_amount);
    return true;
  }

  function subTotalSupply (uint256 _amount) onlySpecified('token') public returns(bool res){
    uint256 b = totalSupply;
    totalSupply = b.sub(_amount);
    return true;      
  }

  // ======================================== CASHOUT ======================================== //   

  function addCashOutAmount (address _address,uint256 _amount)public onlySpecified('token') returns(bool res){
    uint256 c = pendingPayments[_address].cashout;
    pendingPayments[_address].cashout = c.add(_amount);      
    return true;        
  }

  function subCashOutAmount (address _address,uint256 _amount)public onlySpecified('token') returns(bool res){
    uint256 c = pendingPayments[_address].cashout;
    pendingPayments[_address].cashout = c.sub(_amount);      
    return true;        
  }

  function setCashOutAmount (address _address,uint256 _amount)public onlySpecified('token') returns(bool res){
    pendingPayments[_address].cashout = _amount;      
    return true;        
  }

  function getCashOutAmount (address _address)public view onlySpecified('token') returns(uint256 res){
    return pendingPayments[_address].cashout;        
  }

  // ======================================== RECOVER ======================================== //

  function addRecoverAmount (address _address,uint256 _amount)public onlySpecified('token') returns(bool res){
    uint256 c = pendingPayments[_address].recover;
    pendingPayments[_address].recover = c.add(_amount);      
    return true;
  }
  
  function subRecoverAmount (address _address,uint256 _amount)public onlySpecified('token') returns(bool res){
    uint256 c = pendingPayments[_address].recover;
    pendingPayments[_address].recover = c.sub(_amount);      
    return true;
  }

  function setRecoverAmount (address _address,uint256 _amount)public onlySpecified('token') returns(bool res){
    pendingPayments[_address].recover = _amount;      
    return true;
  }

  function getRecoverAmount (address _address)public view onlySpecified('token') returns(uint256 res){
    return pendingPayments[_address].recover;
  }

}