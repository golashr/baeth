pragma solidity ^0.4.23;

library LogicOp {

	function and(bool a, bool b) internal pure returns (bool) {
		return a && b;
	}

	function or(bool a, bool b) internal pure returns (bool) {
		return a || b;
	}
}