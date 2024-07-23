import { fabric } from "fabric";
import { CANVAS_CONFIG, STAGE_DISABLED_HEIGHT } from "./config";
import { createTextLabel, generateGridImage, getRequiredTotalValueText, resizeCanvas, isStageCompleted } from './utility';
import { Stage, CustomRectOptions, Cell } from "../interfaces";
import stage2LockedImage from '../../assets/stage2_locked.jpg';
import stage3LockedImage from '../../assets/stage3_locked.jpg';
import { setSelectedSquare, store } from "../store";
import { fromGweiToMatic } from "../utils";
import { displaySquareContent, updateSidebarForSelectedSquare } from "../sidebar/pixelCard";

const getGridWidth = (stages: Stage[]) => stages[0]?.cells[0]?.length || 0;
const getTotalHeight = (stages: Stage[]) => {
  const contentHeight = stages.reduce((acc, stage) => acc + stage.cells.length, 0);
  const hasDisabledStage = stages.some(stage => !stage.isEnabled);
  return contentHeight + (hasDisabledStage ? STAGE_DISABLED_HEIGHT : 0);
};

const setCanvasDimensions = (canvas: fabric.Canvas, gridWidth: number, totalHeight: number) => {
  canvas.setWidth(gridWidth * CANVAS_CONFIG.CELL_SIZE);
  canvas.setHeight(totalHeight * CANVAS_CONFIG.CELL_SIZE);
};


const createCanvas = (stages: Stage[]): fabric.Canvas => {
  const gridWidth = getGridWidth(stages);
  const totalHeight = getTotalHeight(stages);
  
  const canvas = store.canvas;
  setCanvasDimensions(canvas, gridWidth, totalHeight);
  canvas.backgroundColor = CANVAS_CONFIG.BACKGROUND_COLOR;
  canvas.renderAll();

  const handleResize = () => {
    resizeCanvas(store.canvas, getGridWidth(stages), getTotalHeight(stages));
  }
  
  window.removeEventListener('resize', handleResize);  
  window.addEventListener('resize', handleResize);

  resizeCanvas(canvas, gridWidth, totalHeight);
  return canvas;
};


const setupCanvasContent = (canvas: fabric.Canvas, allCells: Cell[][], yOffset: number, stage: number): fabric.Canvas => {
  const gridHeight = allCells.length;
  const gridWidth = allCells[0].length;

  const gridImageUrl = generateGridImage(gridWidth, gridHeight);
  canvas.setBackgroundColor(gridImageUrl, () => canvas.renderAll());
  canvas.backgroundColor = "#000";

  const squares: fabric.Rect[] = [];
  for (let y = 0; y < gridHeight; y++) {
    for (let x = 0; x < gridWidth; x++) {
      let fillColor = "#000";
      let cell = allCells[y][x];
      let currentValue = Number(fromGweiToMatic(cell.baseValue));
      if (cell.layers.length > 0) {
        fillColor = cell.layers[cell.layers.length - 1].color;
      }
      const square = new fabric.Rect({
        squareLayers: cell.layers,
        width: CANVAS_CONFIG.CELL_SIZE,
        height: CANVAS_CONFIG.CELL_SIZE,
        stroke: CANVAS_CONFIG.GRID_COLOR,
        fill: fillColor,
        gridX: x,
        gridY: y,
        stage: stage,
        yOffset: yOffset,
        top: (CANVAS_CONFIG.CELL_SIZE * y) + (yOffset * CANVAS_CONFIG.CELL_SIZE),
        left: (CANVAS_CONFIG.CELL_SIZE * x),
        lockMovementX: true,
        lockMovementY: true,
        hasControls: false,
        hoverCursor: 'pointer',
        originalFill: fillColor,
        squareValue: currentValue,
      } as CustomRectOptions);

      square.on('mousedown', function (e) {
        if (!e.target) return;
        const clickedSquare = e.target as fabric.Rect & CustomRectOptions;
        if (store.selectedSquare && store.selectedSquare !== clickedSquare) {
          store.selectedSquare.set('strokeWidth', 1);
          store.selectedSquare.set('fill', store.selectedSquare.originalFill);
        }
        e.target.set('strokeWidth', 4);
        setSelectedSquare(clickedSquare);

        if(!store.selectedSquare.squareValue) return;
        updateSidebarForSelectedSquare(canvas);
      });
      squares.push(square);
    }
  }
  canvas.add(...squares); 
  return canvas;
}

const setupCanvas = (stages: Stage[], totalValues: any[]): fabric.Canvas => {
  displaySquareContent(false);

  const canvas = createCanvas(stages);
  let yOffset = 0;
  for (const [index, stage] of stages.entries()) {
    if (stage.isEnabled) {
      setupCanvasContent(canvas, stage.cells, yOffset, index);
      yOffset += stage.cells.length;
    } else {
      setupDisabledStageContent(stages, canvas, index, totalValues, yOffset);
      break;
    }
  }
  return canvas;
}


const setupDisabledStageContent = (stages: Stage[], canvas: fabric.Canvas, stageIndex: number, totalValues: any[], yOffset: number): void => {
  const imageUrl = stageIndex === 1 ? stage2LockedImage : stage3LockedImage;
  const gridWidth = getGridWidth(stages);

  fabric.Image.fromURL(imageUrl, img => {
      const scaleFactor = (STAGE_DISABLED_HEIGHT * CANVAS_CONFIG.CELL_SIZE) / img.height;

      img.set({
          left: 0,
          top: yOffset * CANVAS_CONFIG.CELL_SIZE,
          selectable: false,
          scaleX: scaleFactor,
          scaleY: scaleFactor
      });

      const overlayRect = new fabric.Rect({
          left: -1,
          top: img.top,
          width: img.width * scaleFactor,
          height: img.height * scaleFactor,
          fill: 'rgba(0, 0, 0, 0.5)',
          selectable: false
      });

      canvas.add(img, overlayRect);

      const middleY = img.top + (img.height * scaleFactor) / 2;
      const labelLeftPosition = gridWidth * CANVAS_CONFIG.CELL_SIZE * 0.5

      const stageLabel = createTextLabel(`STAGE ${stageIndex + 1}`, {
        left: labelLeftPosition,
        top: middleY - 140,
        fontSize: 60,
        fill: 'white'
      }, 'stageLabel');

      const notEnabledLabel = createTextLabel('Locked', {
        left: labelLeftPosition,
        top: middleY + 60,
        fontSize: 60,
        fill: 'red'
      }, 'lockedLabel');

      const stage1Value = Number(fromGweiToMatic(totalValues[0]));
      const stage2Value = Number(fromGweiToMatic(totalValues[1]));
      const requiredTotalValueText = getRequiredTotalValueText(stageIndex, stage1Value, stage2Value);
      if (isStageCompleted(stageIndex, stage1Value, stage2Value)) {
          notEnabledLabel.text = 'Waiting for owner unlock';
          notEnabledLabel.fill = 'green';
      }

      const requiredValueLabel = createTextLabel(requiredTotalValueText, {
        left: labelLeftPosition,
        top: middleY - 50,
        fontSize: 30,
        fill: 'yellow'
      }, 'requiredLabel');

      canvas.add(stageLabel, notEnabledLabel, requiredValueLabel);
  });
}

export { setupCanvas }