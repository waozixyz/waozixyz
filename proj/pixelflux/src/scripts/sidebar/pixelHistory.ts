import { store } from "../store";
import { roundToTwoSignificantFigures } from "../utils";

const ITEMS_PER_PAGE = 5;

function displayHistoryForPage(pageNumber: number, pixelData: any) {
  const startIndex = (pageNumber - 1) * ITEMS_PER_PAGE;
  const endIndex = startIndex + ITEMS_PER_PAGE;

  const itemsToDisplay = pixelData.slice(startIndex, endIndex);

  const historyElement = document.getElementById('history')!;
  historyElement.innerHTML = '';

  itemsToDisplay.forEach((data: any) => {
      const liElement = document.createElement('li');

      const colorCircle = document.createElement('div');
      colorCircle.classList.add('color-circle');
      colorCircle.style.backgroundColor = data.color;
      liElement.appendChild(colorCircle);

      const purchaseInfo = document.createElement('div');
      purchaseInfo.classList.add('purchase-info');

      const formattedAddress = `${data.contractAddress.slice(0, 4)}...${data.contractAddress.slice(-4)}`;

      purchaseInfo.innerHTML = `Value: ${data.value} <br/> ${formattedAddress}`;
      liElement.appendChild(purchaseInfo);

      historyElement.appendChild(liElement);
  });

  const prevButton = document.getElementById('prev-button') as HTMLInputElement;
  const nextButton = document.getElementById('next-button') as HTMLInputElement;

  if (prevButton && nextButton) {
    prevButton.disabled = pageNumber <= 1;
    nextButton.disabled = pageNumber >= Math.ceil(pixelData.length / ITEMS_PER_PAGE);
  }
}

export function updateHistory(currentPage: number) {
  const pixelData = [...store.selectedSquare.squareLayers].reverse().map((layer, index) => ({
      color: layer.color ? layer.color : "#000",
      value: roundToTwoSignificantFigures(store.selectedSquare.squareValue * (store.selectedSquare.squareLayers.length - index)),
      contractAddress: layer.owner
  }));
  displayHistoryForPage(currentPage, pixelData);

  const prevButton = document.getElementById('prev-button');
  const nextButton = document.getElementById('next-button');

  if (prevButton && nextButton) {
    prevButton.addEventListener('click', () => {
      currentPage--;
      displayHistoryForPage(currentPage, pixelData);
    });

    nextButton.addEventListener('click', () => {
      currentPage++;
      displayHistoryForPage(currentPage, pixelData);
    });
  }
}
