// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./BaseContract.sol";
import "./DataStorage2.sol";

contract Pixelflux2 is BaseContract, DataStorage2 {
    bool public isEnabled = false;
    BaseContract public baseContract;

    event ContractEnabled();

    function isContractEnabled() public override view returns(bool) {
        return isEnabled;
    }

    constructor(address _baseContractAddress) {
        baseContract = BaseContract(_baseContractAddress);
    }

    function enableContract() public onlyOwner {
        uint256 totalValue = baseContract.calculateTotalValue();
        require(totalValue >= 3200 * 10**9, "Not enough total value in Stage 1");
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
