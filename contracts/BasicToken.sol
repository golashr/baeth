pragma solidity ^0.4.23;

import "./ERC20Basic.sol";
import "./SafeMath.sol";
import "./Pauseable.sol";


/**
* @title Basic token
* @dev Basic version of StandardToken, with no allowances.
*/
contract BasicToken is ERC20Basic{

	using SafeMath for uint256;

	mapping(address => uint256) public balances;
	uint256 public totalSupply = 0;

	constructor ()public{
		balances[msg.sender] = totalSupply;
	}

	/**
	* @dev Gets the balance of the specified address.
	* @return An uint256 representing the amount owned by the passed address.
	*/
	function balanceOf() external view returns (uint256 balance) {
		return balances[msg.sender];
	}

	function getTotalSupply () external view returns(uint256 res) {
		return totalSupply;
	}

}
