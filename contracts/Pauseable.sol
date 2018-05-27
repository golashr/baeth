pragma solidity ^0.4.23;


import "./Ownable.sol";


/**
* @title Pausable
* @dev Base contract which allows children to implement an emergency stop mechanism.
*/
contract Pauseable is Ownable{

	event SetPaused(address addess,bool paused);

	// starts unpaused
	bool public paused = false;

	/* @dev modifier to allow actions only when the contract IS paused */
	modifier whenNotPaused() {
		require(!paused);
		_;
	}

	/* @dev modifier to allow actions only when the contract IS NOT paused */
	modifier whenPaused() {
		require(paused);
		_;
	}

	/* @dev check if the data size is exactly 68 to prevent underflow errors */
	modifier isSafe() { 
		require ((msg.data).length == 68); 
		_; 
	}
	

	function pause() public onlyOwner whenNotPaused returns (bool) {
		paused = true;
		emit SetPaused(msg.sender,paused);
		return true;
	}

	function unpause() public onlyOwner whenPaused returns (bool) {
		paused = false;
		emit SetPaused(msg.sender,paused);
		return true;
	}
}