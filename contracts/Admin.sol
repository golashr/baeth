pragma solidity ^0.4.23;

import "./Index.sol";
import "./Registry.sol";
import "./Ownable.sol";

contract Admin is Ownable{

	Index index;
	constructor (address _indexAddress) public{
		index = Index(_indexAddress);
	}

	function updateAdmin (address _address,uint256 _id)public onlyOwner{
		Registry r = Registry(index.getContract('registry'));
		assert(index.transferOwnership(_address));
		assert (r.registerUser(_address,_id));
		assert(r.pauseUser(address(this)));
		selfdestruct(address(this));
	}
}
