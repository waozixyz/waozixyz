import { Contract } from 'ethers';
import { getBrowserProvider, contractABIs } from '../blockchainProvider';
import { store } from '../store';
import contractConfig from '../../config/contracts.json';
import { showNotification } from '../notification';
import { fromMaticToWei } from '../utils';
import BigNumber from 'bignumber.js';

const BASE_GAS = 500000;
const GAS_PER_EXISTING_LAYER = 20000;
const GAS_PER_NEW_LAYER = 15000;
const BUFFER_MULTIPLIER = 1.20;


const calculateTotalValueToSend = (numLayersToAdd: number) => {
  const currentLayersCount = store.selectedSquare.squareLayers.length;
  const baseValueInWei = new BigNumber(fromMaticToWei(store.selectedSquare.squareValue));
  
  const sumOfSeries = new BigNumber(numLayersToAdd)
    .multipliedBy(2 * currentLayersCount + numLayersToAdd - 1)
    .dividedBy(2);

  const refundAmount = baseValueInWei
    .multipliedBy(numLayersToAdd * (numLayersToAdd - 1))
    .dividedBy(2);


  return baseValueInWei.multipliedBy(sumOfSeries).minus(refundAmount);
};

const estimateGas = (numLayersToAdd: number) => {
  const currentLayersCount = store.selectedSquare.squareLayers.length;

  return Math.ceil((
      BASE_GAS + 
      (GAS_PER_EXISTING_LAYER * currentLayersCount) + 
      (GAS_PER_NEW_LAYER * numLayersToAdd)
  ) * BUFFER_MULTIPLIER);
}


const buyLayers = async(provider: any, userAddress: string, contractAddress: string, x: number, y: number, numLayersToAdd: number, color: string, stage: number) => {
  try {
    const signer = await provider.getSigner(userAddress);
    const contract = new Contract(contractAddress, contractABIs[stage], signer);
    const totalValueToSend = calculateTotalValueToSend(numLayersToAdd);

    let gasEstimation
    try {
      gasEstimation = await contract.buyMultipleLayers.estimateGas(x, y, numLayersToAdd, color, { value: totalValueToSend.toString() });
    } catch (error) {
      console.log('could not estimate gas', error)
    }
    if (!gasEstimation) {
      gasEstimation = estimateGas(numLayersToAdd);
    }

    if (numLayersToAdd === 1) {
      await contract.buyLayer(x, y, color, { value: totalValueToSend.toString(), gasLimit: gasEstimation, gas: gasEstimation });
    } else {
      await contract.buyMultipleLayers(x, y, numLayersToAdd, color, { value: totalValueToSend.toString(), gasLimit: gasEstimation, gas: gasEstimation });
    }
  } catch (error) {
    if (error.info && error.info.error && error.info.error.code === 4001) {
      console.log("User cancelled the transaction.");
    } else {
      console.error("Contract interaction error:", error);
    }
  }
}

const handlePurchaseClick = async() => {
  const provider = getBrowserProvider();
  let userAddress = '';
  if (typeof window.ethereum !== 'undefined') {
    const accounts = await window.ethereum.request({ method: 'eth_accounts' });
    if (accounts.length > 0) {
      userAddress = accounts[0];
    }
  }

  if (!userAddress) {
    showNotification("No user address found. Please connect to a wallet.");
    return;
}
  
  const contractAddress = contractConfig.polygon.Pixelflux[store.selectedSquare.stage];  
  const layerSlider = document.getElementById('layer-slider') as HTMLInputElement;
  const numLayersToAdd = parseInt(layerSlider.value);
  const color = (typeof store.selectedSquare.fill === 'string') ? store.selectedSquare.fill : '';
  const x = store.selectedSquare.gridX;
  const y = store.selectedSquare.gridY;
  const stage = store.selectedSquare.stage;
  
  buyLayers(provider, userAddress, contractAddress, x, y, numLayersToAdd, color, stage);
}


export { handlePurchaseClick, calculateTotalValueToSend }