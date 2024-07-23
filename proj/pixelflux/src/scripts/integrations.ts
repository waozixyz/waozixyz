import { Contract, Log } from 'ethers';
import { Stage } from './interfaces';
import contractConfig from '../config/contracts.json';
import { getProvider, contractABIs, getWebsocketProvider } from './blockchainProvider';
import { updateCanvasCell, recreateCanvasForContractEnabled } from './canvas/utility';


const getConnectedPolygonAccounts = async(): Promise<string[]> => {
  if (typeof window.ethereum !== 'undefined' && window.ethereum.isConnected()) {
    return await window.ethereum.request({ method: 'eth_accounts' });
  }
  return [];
}

type StagesResult = {
  stages: Stage[];
  totalValues: number[];
};


const getStagesFromContracts = async(): Promise<StagesResult> => {
  const provider = await getProvider();
  
  if (!provider) {
    throw new Error('Failed to get a provider.');
  }

  const wssProvider = getWebsocketProvider();


  const stages = [];
  const totalValues = [];

  const loading = document.getElementById('loading')
  const progressBar = document.getElementById('progress-bar')
  const progressFill = progressBar.querySelector('.progress-fill') as HTMLElement;
  const loadingText = document.getElementById('loading-text');

  loading.style.display = "block"

  const contractAddresses = contractConfig.polygon.Pixelflux;

  for (const [index, address] of contractAddresses.entries()) {  
    const jsonContract = new Contract(address, contractABIs[index], provider);
    const wssContract = new Contract(address, contractABIs[index], wssProvider);
    wssContract.on('LayerPurchased', async(buyer, x, y, numLayers, color) => {
      const updatedTotalValue = await jsonContract.calculateTotalValue();
      totalValues[index] = updatedTotalValue;
      updateCanvasCell(buyer, Number(x), Number(y), Number(numLayers), color, index, totalValues)
    });

    if (index !== 0) {
      try {
        wssContract.on('ContractEnabled', () => {
          recreateCanvasForContractEnabled()
        })
      } catch (error) {
        console.log('contract on failed:', error)
      }
    }
    
    
    const isEnabled = await jsonContract.isContractEnabled();
    
    const stageData = {
      isEnabled: isEnabled,
      cells: isEnabled ? await jsonContract.getAllCellStates() : []
    };

    const totalValue = await jsonContract.calculateTotalValue();

    totalValues.push(totalValue);

    const progressPercentage = ((index + 1) / contractAddresses.length) * 100;
    progressFill.style.width = `${progressPercentage}%`;
    loadingText.textContent = `Loading stage ${index + 1} of ${contractAddresses.length}...`;


    stages.push(stageData);
  }

  loading.style.display = "none"
  
  return {
    stages: stages,
    totalValues: totalValues
  };

}

export { getStagesFromContracts, getConnectedPolygonAccounts }