const Pixelflux = artifacts.require("Pixelflux");

contract("Pixelflux", ([deployer, account1, account2]) => {
    let instance;
    const initialColor = "#000";
    const initialValue = 0.003;
    const newColor = "#fff";

    before(async () => {
        instance = await Pixelflux.new();
    });

    it("should deploy the contract and initialize the grid", async () => {
        assert(instance);
        const owner = await instance.owner();
        assert.equal(owner, deployer);

        const cellState = await instance.getCellState(0, 0);
        assert.equal(cellState[0], initialValue);
        assert.equal(cellState[1], initialColor);
        assert.equal(cellState[2].toNumber(), 1);
    });

    it("should allow buying a layer", async () => {
        const valueToSend = web3.utils.toWei("1.1", "matic"); // baseValue + 0.1 for the next layer
        await instance.buyLayer(0, 0, initialColor, { from: account1, value: valueToSend });
        
        const cellState = await instance.getCellState(0, 0);
        assert.equal(cellState[2].toNumber(), 2); // Two layers
    });

    it("should allow setting layer color", async () => {
        await instance.setLayerColor(0, 0, 1, newColor, { from: account1 });
        const cellState = await instance.getCellState(0, 0);
        assert.equal(cellState[1], newColor);
    });

    it("should revert if non-owner tries to set layer color", async () => {
        try {
            await instance.setLayerColor(0, 0, 1, initialColor, { from: account2 });
            assert.fail("Expected revert not received");
        } catch (error) {
            const revertReceived = error.message.search('revert') >= 0;
            assert(revertReceived, `Expected "revert", got ${error} instead`);
        }
    });

    it("should allow buying multiple layers", async () => {
        const valueToSend = web3.utils.toWei("1.3", "matic"); // 1 + 0.1 + 0.2 (for 2 additional layers)
        await instance.buyMultipleLayers(0, 0, 2, initialColor, { from: account1, value: valueToSend });
        
        const cellState = await instance.getCellState(0, 0);
        assert.equal(cellState[2].toNumber(), 4); // Four layers
    });

    it("should distribute funds correctly when buying layers", async () => {
        const startBalance = await web3.eth.getBalance(deployer);
        const valueToSend = web3.utils.toWei("1.5", "matic"); // 1 + 0.1 + 0.2 + 0.3 (for 3 additional layers)
        await instance.buyMultipleLayers(0, 0, 3, initialColor, { from: account2, value: valueToSend });

        const endBalance = await web3.eth.getBalance(deployer);
        const difference = web3.utils.fromWei(new web3.utils.BN(endBalance).sub(new web3.utils.BN(startBalance)), "matic");
        assert.equal(difference, "1.5"); // deployer should receive 1.5 matic
    });
});
