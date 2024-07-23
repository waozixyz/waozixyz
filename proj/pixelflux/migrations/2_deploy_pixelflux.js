const Pixelflux1 = artifacts.require("Pixelflux1");
const Pixelflux2 = artifacts.require("Pixelflux2");
const Pixelflux3 = artifacts.require("Pixelflux3");
const TIMEOUT = 120

Pixelflux1.synchronization_timeout = TIMEOUT;
Pixelflux1.synchronization_timeout = TIMEOUT;
Pixelflux1.synchronization_timeout = TIMEOUT;

module.exports = async function(deployer) {
  await deployer.deploy(Pixelflux1);
  const pixelFlux1Instance = await Pixelflux1.deployed();

  await deployer.deploy(Pixelflux2, pixelFlux1Instance.address);
  const pixelFlux2Instance = await Pixelflux2.deployed();

  await deployer.deploy(Pixelflux3, pixelFlux1Instance.address, pixelFlux2Instance.address);
};
