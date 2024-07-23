// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./BaseContract.sol";
import "./DataStorage1.sol";

contract Pixelflux1 is BaseContract, DataStorage1 {
    function isContractEnabled() public override view returns(bool) {
        return true;
    }
    
    function getInitialValue(uint x, uint y) internal override view returns (uint256, string memory) {
        require(x < gridWidth, "Invalid x-coordinate");
        require(y < gridHeight, "Invalid y-coordinate");
        return (initialValues[y][x], colorValues[y][x]);
    }

    function getGridWidth() internal override pure returns (uint256) {
        return gridWidth;
    }

    function getGridHeight() internal override pure returns (uint256) {
        return gridHeight;
    }
}
