// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

abstract contract BaseContract {
    address public owner;
    
    struct Layer {
        address payable owner;
        string color;
    }

    struct Cell {
        uint256 baseValue;
        Layer[] layers;
    }

    mapping(uint => mapping(uint => Cell)) public grid;
    mapping(address => uint256) payoutMap;
    event LayerPurchased(address indexed buyer, uint x, uint y, uint256 numLayers, string color);

    constructor() {
        owner = msg.sender;
    }

    function isContractEnabled() public virtual view returns(bool);
    function getInitialValue(uint x, uint y) internal virtual view returns (uint256, string memory);
    function getGridWidth() internal virtual pure returns (uint256);
    function getGridHeight() internal virtual pure returns (uint256);

    modifier contractEnabled() {
        require(isContractEnabled(), "Contract is not enabled");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyLayerOwner(uint x, uint y, uint256 layerIndex) {
        require(grid[y][x].layers[layerIndex].owner == msg.sender, "Not the owner of this layer");
        _;
    }

    function setLayerColor(uint x, uint y, uint256 layerIndex, string memory newColor) public contractEnabled() validCoordinates(x, y) onlyLayerOwner(x, y, layerIndex) {
        grid[y][x].layers[layerIndex].color = newColor;
    }

    function initializeCell(uint x, uint y) internal {
        if (grid[y][x].baseValue == 0 && grid[y][x].layers.length == 0) {
            (uint256 value, string memory color) = getInitialValue(x, y);
            grid[y][x].baseValue = value * 10**6;
            grid[y][x].layers.push(Layer({
                owner: payable(owner),
                color: color
            }));
        }
    }

    modifier validCoordinates(uint x, uint y) {
        require(x < getGridWidth(), "Invalid x coordinate");
        require(y < getGridHeight(), "Invalid y coordinate");
        _;
    }

    function buyLayer(uint x, uint y, string memory color) public payable contractEnabled() validCoordinates(x, y) {
        buyMultipleLayers(x, y, 1, color);
    }
    function buyMultipleLayers(uint x, uint y, uint256 numLayersToAdd, string memory color) public payable contractEnabled() validCoordinates(x, y) {
        require(numLayersToAdd <= 10, "Cannot buy more than 10 layers at once");

        initializeCell(x, y);

        uint256 baseValueForCellInWei = grid[y][x].baseValue * 10**9;
        uint256 currentLayersCount = grid[y][x].layers.length;
        uint256 sumOfSeries = numLayersToAdd * (2 * currentLayersCount + numLayersToAdd - 1) / 2;

        uint256 refundAmount = baseValueForCellInWei * (numLayersToAdd * (numLayersToAdd - 1) / 2);

        uint256 totalCost = (baseValueForCellInWei * sumOfSeries) - refundAmount;

        require(msg.value == totalCost, "Incorrect POL sent");

        for (uint256 j = 0; j < currentLayersCount; j++) {
            address layerOwner = grid[y][x].layers[j].owner;
            payoutMap[layerOwner] += baseValueForCellInWei * numLayersToAdd;
        }

        payoutOwners(x, y);

        for (uint256 i = 0; i < numLayersToAdd; i++) {
            grid[y][x].layers.push(Layer({
                owner: payable(msg.sender),
                color: color
            }));
        }

        emit LayerPurchased(msg.sender, x, y, numLayersToAdd, color);
    }


    function payoutOwners(uint x, uint y) internal {
        for (uint256 i = 0; i < grid[y][x].layers.length; i++) {
            address layerOwner = grid[y][x].layers[i].owner;
            if (payoutMap[layerOwner] > 0) {
                payable(layerOwner).transfer(payoutMap[layerOwner]);
                payoutMap[layerOwner] = 0;
            }
        }
    }
    
    function calculateTotalValue() public view returns (uint256) {
        uint256 totalValue = 0;
        uint256 width = getGridWidth();
        uint256 height = getGridHeight();

        for (uint y = 0; y < height; y++) {
            for (uint x = 0; x < width; x++) {
                Cell memory cell = grid[y][x];
                uint256 cellValue = cell.baseValue * cell.layers.length;
                totalValue += cellValue;
            }
        }

        return totalValue;
    }


    function getCellState(uint x, uint y) public view contractEnabled() validCoordinates(x, y) returns (uint256, string memory, uint256) {
        Cell memory cell = grid[y][x];
        
        if(cell.layers.length == 0) {
            (uint256 initialValue, string memory initialColor) = getInitialValue(x, y);
            return (initialValue * 10**6, initialColor, 0);
        }
        
        return (cell.baseValue, cell.layers[cell.layers.length - 1].color, cell.layers.length);
    }

    function getAllCellStates() public view contractEnabled() returns (Cell[][] memory) {
        uint256 width = getGridWidth();
        uint256 height = getGridHeight();
        Cell[][] memory allCells = new Cell[][](height);

        for (uint y = 0; y < height; y++) {
            Cell[] memory row = new Cell[](width);
            for (uint x = 0; x < width; x++) {
                (uint256 value, string memory color, uint256 layersCount) = getCellState(x, y);

                row[x].baseValue = value;

                if (layersCount == 0) {
                    row[x].layers = new Layer[](1);
                    row[x].layers[0] = Layer({
                        owner: payable(owner),
                        color: color
                    });
                } else {
                    row[x].layers = grid[y][x].layers;
                }
            }
            allCells[y] = row;
        }

        return allCells;
    }

    function getTopLayerOfCell(uint x, uint y) public view contractEnabled() validCoordinates(x, y) returns (address payable, string memory) {
        Cell memory cell = grid[y][x];

        if (cell.layers.length == 0) {
            (, string memory initialColor) = getInitialValue(x, y);
            return (payable(owner), initialColor);
        }

        Layer memory topLayer = cell.layers[cell.layers.length - 1];
        return (topLayer.owner, topLayer.color);
    }
    
    function getAllTopLayers() public view contractEnabled() returns (address payable[][] memory, string[][] memory) {
        uint256 width = getGridWidth();
        uint256 height = getGridHeight();

        address payable[][] memory ownersMatrix = new address payable[][](height);
        string[][] memory colorsMatrix = new string[][](height);

        for (uint y = 0; y < height; y++) {
            address payable[] memory ownersRow = new address payable[](width);
            string[] memory colorsRow = new string[](width);

            for (uint x = 0; x < width; x++) {
                (ownersRow[x], colorsRow[x]) = getTopLayerOfCell(x, y);
            }

            ownersMatrix[y] = ownersRow;
            colorsMatrix[y] = colorsRow;
        }

        return (ownersMatrix, colorsMatrix);
    }

    function withdrawFunds() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No funds to withdraw");
        payable(owner).transfer(contractBalance);
    }
}
