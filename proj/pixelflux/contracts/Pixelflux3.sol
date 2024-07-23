// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./BaseContract.sol";
import "./DataStorage3.sol";

contract Pixelflux3 is BaseContract, DataStorage3 {
    bool public isEnabled = false;
    BaseContract public baseContract1;
    BaseContract public baseContract2;

    event ContractEnabled();

    function isContractEnabled() public override view returns(bool) {
        return isEnabled;
    }

    constructor(address _baseContractAddress1, address _baseContractAddress2) {
        baseContract1 = BaseContract(_baseContractAddress1);
        baseContract2 = BaseContract(_baseContractAddress2);
    }

    function enableContract() public onlyOwner {
        uint256 totalValue1 = baseContract1.calculateTotalValue();
        uint256 totalValue2 = baseContract2.calculateTotalValue();
        require(totalValue1 >= 9000 * 10**9, "Not enough total value in Stage 1");
        require(totalValue2 >= 25000 * 10**9, "Not enough total value in Stage 2");
        isEnabled = true;
        
        emit ContractEnabled();
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
