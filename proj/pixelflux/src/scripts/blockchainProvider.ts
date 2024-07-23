import { BrowserProvider, JsonRpcProvider, WebSocketProvider } from 'ethers';

import Pixelflux1JSON from '../../build/contracts/Pixelflux1.json';
import Pixelflux2JSON from '../../build/contracts/Pixelflux2.json';
import Pixelflux3JSON from '../../build/contracts/Pixelflux3.json';

require('dotenv').config();

const getBrowserProvider = (): BrowserProvider | null => {
  if (!window.ethereum) {
    console.error('MetaMask or a similar wallet provider is required.');
    return null;
  }
  return new BrowserProvider(window.ethereum);
}

const getInfuraProvider = (): JsonRpcProvider | null => {
  const infuraUrl = `https://polygon-mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`;
  if (!process.env.INFURA_API_KEY) {
    console.error('Infura API key is required.');
    return null;
  }
  return new JsonRpcProvider(infuraUrl);
}

const getAnkrProvider = (): JsonRpcProvider | null => {
  const ankrUrl = `https://rpc.ankr.com/polygon/${process.env.ANKR_API_KEY}`;
  if (!process.env.ANKR_API_KEY) {
    console.error('Ankr API key is required.');
    return null;
  }
  return new JsonRpcProvider(ankrUrl);
};

const getWebsocketProvider = (): WebSocketProvider | null => {
  const quikUrl = `wss://serene-dimensional-brook.matic.quiknode.pro/${process.env.QUIKNODE_API_KEY}/`;
  if (!process.env.QUIKNODE_API_KEY) {
    console.error('Quiknode API key is required.');
    return null;
  }
  console.log('Creating WebSocketProvider with URL:', quikUrl);
  return new WebSocketProvider(quikUrl);
}
const getProvider = async (): Promise<BrowserProvider | JsonRpcProvider | null> => {
  let provider: BrowserProvider | JsonRpcProvider | null = getInfuraProvider();
  if (provider) {
    try {
      await provider.getNetwork();
      return provider;
    } catch (error) {
      // Log error only if it's not a 403 Forbidden error
      if (!error.message.includes('403')) {
        console.error('InfuraProvider not supported:', error);
      }
    }
  }

  provider = getAnkrProvider();
  if (provider) {
    try {
      await provider.getNetwork();
      return provider;
    } catch (error) {
      console.error('AnkrProvider not supported:', error);
    }
  }

  provider = getBrowserProvider();
  if (provider) {
    try {
      await provider.getNetwork();
      return provider;
    } catch (error) {
      console.error('BrowserProvider not supported:', error);
    }
  }

  return null;
};


const contractABIs = [Pixelflux1JSON.abi, Pixelflux2JSON.abi, Pixelflux3JSON.abi];


export {contractABIs, getProvider, getBrowserProvider, getAnkrProvider, getWebsocketProvider }