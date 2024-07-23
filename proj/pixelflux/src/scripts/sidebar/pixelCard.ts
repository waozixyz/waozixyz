import { store } from "../store";
import { convertToFullHex, roundToTwoSignificantFigures } from '../utils'
import { updateHistory } from "./pixelHistory"
import { setupColorOptions, handleLayerSliderUpdate } from "./pixelBuy"

let currentPage = 1;

const displaySquareContent = (show: boolean) => {
  const element = document.querySelector('.square-content') as HTMLElement;
  if (element) {
    element.style.display = show ? 'flex' : 'none';
  }
}
const updateColorDisplay = () => {
  const pixelCard = document.querySelector('.pixel-card') as HTMLElement;
  const pixelDisplayContainer = pixelCard.querySelector('.pixel-display-container') as HTMLElement;
  const pixelCurrent = pixelCard.querySelector('.pixel-current') as HTMLElement;
  const pixelPreview = pixelCard.querySelector('.pixel-preview') as HTMLElement;
  const pixelPropertiesElement = pixelCard.querySelector('.pixel-properties') as HTMLElement;
  const layerSlider = document.getElementById('layer-slider') as HTMLInputElement;
  const arrowSpan = pixelCard.querySelector('.pixel-display-container > span') as HTMLElement;

  const currentLayerNumber = store.selectedSquare.squareLayers.length;

  if (pixelPreview && typeof store.selectedSquare.fill === 'string') {
    pixelPreview.style.backgroundColor = store.selectedSquare.fill ? store.selectedSquare.fill : "#000";
  }

  if (pixelCurrent && typeof store.selectedSquare.originalFill === 'string') {
    pixelCurrent.style.backgroundColor = store.selectedSquare.originalFill ? store.selectedSquare.originalFill : "#000";
  }

  const currentValue = roundToTwoSignificantFigures(store.selectedSquare.squareValue * currentLayerNumber);

  let layerValue = parseInt(layerSlider.value);
  if (layerValue > 0 || store.selectedSquare.fill !== store.selectedSquare.originalFill) {
    if (layerValue === 0) {
      const layerSlider = document.getElementById('layer-slider') as HTMLInputElement;
      layerSlider.value = "1";
      handleLayerSliderUpdate();
      layerValue = 1;
    }
    pixelDisplayContainer.style.display = "flex";
    pixelPreview.style.display = "block";
    arrowSpan.style.display = "inline-block";

    const newLayerNumber = currentLayerNumber + layerValue;
    const newValue = roundToTwoSignificantFigures(store.selectedSquare.squareValue * (currentLayerNumber + layerValue));

    pixelPropertiesElement.innerHTML = `
      <p>L ${currentLayerNumber - 1} ->  <span class="new-value">L ${newLayerNumber - 1}</span</p>
      <br/>
      <p>${currentValue} Matic</p>
      <p>&#x2B07;</p>
      <p class="new-value">${newValue} Matic</p>
      <br/>
      <p>x: ${store.selectedSquare.gridX}, y: ${store.selectedSquare.gridY + store.selectedSquare.yOffset}</p>
      `;
  } else {
    arrowSpan.style.display = "none";
    pixelDisplayContainer.style.display = "flex";
    pixelPreview.style.display = "none";
    pixelPropertiesElement.innerHTML = `
      <p>L ${currentLayerNumber - 1}</p>
      <p>${currentValue} Matic</p>
      <p>x: ${store.selectedSquare.gridX}, y: ${store.selectedSquare.gridY + store.selectedSquare.yOffset}</p>
      `;
  }


  const colorPickers = document.querySelectorAll('input[type="color"]') as NodeListOf<HTMLInputElement>;
  if (colorPickers && colorPickers.length >= 2) {
    colorPickers[0].value = convertToFullHex(store.colorPicker[0]);
    colorPickers[1].value = convertToFullHex(store.colorPicker[1]);
  }
};
let isCloseButtonEventAdded = false;


const handleModalDisplay = () => {
  const sidebar = document.getElementById('sidebar');
  const closeButton = sidebar.querySelector('#close-modal');

  if (closeButton && !isCloseButtonEventAdded) {
    closeButton.addEventListener('click', () => {
      sidebar.style.display = "none";
    });
    isCloseButtonEventAdded = true;
}

  
  const useModal = (): boolean => window.innerWidth <= 520;

  if (useModal()) {
    if (!sidebar.classList.contains('modal-content')) {
      sidebar.classList.add('modal-content');
    }
  } else {
    if (sidebar.classList.contains('modal-content')) {
      sidebar.classList.remove('modal-content');
    }
  }
};


window.addEventListener('resize', () => {
  const sidebar = document.getElementById('sidebar');

  if (window.innerWidth <= 520 && !sidebar.classList.contains('modal-content')) {
    sidebar.style.display = "none";
  }
  else if (window.innerWidth >= 520 && sidebar.classList.contains('modal-content')) {
    sidebar.style.display = "block";

  }
  handleModalDisplay();
});

const updateSidebarForSelectedSquare = (canvas: fabric.Canvas) => {
  displaySquareContent(true);
  const layerSlider = document.getElementById('layer-slider') as HTMLInputElement;
  layerSlider.value = "0";
  handleLayerSliderUpdate();
  updateColorDisplay();

  currentPage = 1;
  updateHistory(currentPage);
  setupColorOptions(canvas);

  handleModalDisplay();
  const sidebar = document.getElementById('sidebar');
  sidebar.style.display = "block";
}

export { updateSidebarForSelectedSquare, updateColorDisplay, displaySquareContent }