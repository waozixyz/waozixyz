import { setupCanvas } from './canvas/setup';
import { getStagesFromContracts } from './integrations';
import { setupSidebar } from './sidebar/setup';
import { showNotification } from './notification';
import { showWalletModal } from './walletModal';

document.addEventListener("DOMContentLoaded", async () => {
  let stages, totalValues

  setupSidebar();

  try {
    ({ stages, totalValues } = await getStagesFromContracts());
  } catch (error) {
    if (error.message === 'Failed to get a provider.') {
      showWalletModal();
    } else {
      showNotification("Error fetching data from provider. Please retry again later.");
    }
  }

  if (stages && stages.length > 0) {
    setupCanvas(stages, totalValues);
  }
});
