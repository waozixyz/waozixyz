import { default as defaultColors } from '../../config/colors.json';
import { store } from "../store";
import { convertToFullHex, fromWeiToMatic } from '../utils'
import { updateColorDisplay} from "./pixelCard";
import { calculateTotalValueToSend } from './purchaseLogic';


const handleLayerSliderUpdate = () => {
  const layerSlider = document.getElementById('layer-slider') as HTMLInputElement;
  const sliderValue = document.getElementById('slider-value');
  const purchaseLayerButton = document.getElementById('purchase-button') as HTMLButtonElement;
  sliderValue.textContent = layerSlider.value; 

  purchaseLayerButton.disabled = layerSlider.value === "0";
  purchaseLayerButton.textContent = parseInt(layerSlider.value) <= 1 ? "Buy Layer" : "Buy Layers";

  updateColorDisplay();
  updateTotalValueDisplay();
};

const updateTotalValueDisplay = () => {
  const layerSlider = document.getElementById('layer-slider') as HTMLInputElement;
  const numLayersToAdd = parseInt(layerSlider.value);

  const totalValue = fromWeiToMatic(calculateTotalValueToSend(numLayersToAdd));
  const totalValueElement = document.querySelector('#current-cost') as HTMLElement;
  totalValueElement.innerText = `${totalValue} Matic`;

};

const setupSliderControls = () => {
  const layerSlider = document.getElementById('layer-slider') as HTMLInputElement;
  const sliderValue = document.getElementById('slider-value');
  const decreaseBtn = document.getElementById('decrease-btn');
  const increaseBtn = document.getElementById('increase-btn');
  const maxSliderValue = parseInt(layerSlider.max);
  const minSliderValue = parseInt(layerSlider.min);

  if (decreaseBtn) {
    decreaseBtn.addEventListener('click', function() {
      let currentValue = parseInt(layerSlider.value);
      if (currentValue > minSliderValue) {
        layerSlider.value = (currentValue - 1).toString();
        if(layerSlider.value === "0" && store.selectedSquare.fill !== store.selectedSquare.originalFill) {
          store.selectedSquare.fill = store.selectedSquare.originalFill;
        }
        handleLayerSliderUpdate();
      }
    });
  }

  if (increaseBtn) {
    increaseBtn.addEventListener('click', function() {
      let currentValue = parseInt(layerSlider.value);
      if (currentValue < maxSliderValue) {
        layerSlider.value = (currentValue + 1).toString();
        handleLayerSliderUpdate();
      }
    });
  }

  if (layerSlider && sliderValue) {
    layerSlider.addEventListener('input', function() {
      handleLayerSliderUpdate();
    });
  }
}

const createColorOption = (canvas: fabric.Canvas, color: string, isPicker?: boolean, pickerIndex?: number) => {
  const colorOptionsContainer = document.getElementById('color-options')!;
  
  if (isPicker && typeof pickerIndex !== 'undefined') {
      const element = document.createElement('input');
      element.type = 'color';
      element.value = convertToFullHex(store.colorPicker[pickerIndex]);

      const handleEvent = (event: Event) => {
        if (event.type === 'input' || event.type === 'change') {
            store.colorPicker[pickerIndex] = element.value;
        }
        setColorAndUpdateSidebar(canvas, element.value);
      }
  
      element.addEventListener('click', handleEvent);
      element.addEventListener('change', handleEvent);
      
      colorOptionsContainer.appendChild(element);
  } else if (!isPicker) {
      const element = document.createElement('div');
      element.classList.add('color-option');
      element.style.backgroundColor = color;
      element.addEventListener('click', function () {
          setColorAndUpdateSidebar(canvas, color);
      });
      colorOptionsContainer.appendChild(element);
  }
}

const setColorAndUpdateSidebar = (canvas: fabric.Canvas, color: string) => {
  if (store.selectedSquare !== null) {
      store.selectedSquare.set('fill', color);
      updateColorDisplay();
      canvas.renderAll();
  }
}

const setupColorOptions = (canvas: fabric.Canvas) => {
  const colorOptionsContainer = document.getElementById('color-options')!;
  colorOptionsContainer.innerHTML = '';

  if (store.selectedSquare) {
    createColorOption(canvas, store.selectedSquare.originalFill ? store.selectedSquare.originalFill : "#000");
  }

  defaultColors.forEach(function (color: string) {
      createColorOption(canvas, color);
  });

  createColorOption(canvas, '', true, 0);
  createColorOption(canvas, '', true, 1);
}


export { setupSliderControls, createColorOption, setupColorOptions, handleLayerSliderUpdate };
