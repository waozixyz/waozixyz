import { fabric } from "fabric";
import { CustomRectOptions, TextLabelWithId } from "../interfaces";
import { store, setSelectedSquare } from "../store";
import { fromGweiToMatic } from "../utils";
import { updateSidebarForSelectedSquare } from "../sidebar/pixelCard";
import { setupCanvas } from "./setup";
import { CANVAS_CONFIG, STAGE_THRESHOLDS } from "./config";
import { getStagesFromContracts } from "../integrations";

const generateGridImage = (gridWidth: number, gridHeight: number): string => {
  const tempCanvas = document.createElement('canvas');
  tempCanvas.width = gridWidth * CANVAS_CONFIG.CELL_SIZE;
  tempCanvas.height = gridHeight * CANVAS_CONFIG.CELL_SIZE;

  const ctx = tempCanvas.getContext('2d')!; 

  for (let x = 0; x <= gridWidth; x += CANVAS_CONFIG.CELL_SIZE) {
    ctx.moveTo(x, 0);
    ctx.lineTo(x, gridWidth);
  }

  for (let y = 0; y <= gridHeight; y += CANVAS_CONFIG.CELL_SIZE) {
    ctx.moveTo(0, y);
    ctx.lineTo(gridHeight, y);
  }

  ctx.stroke();

  return tempCanvas.toDataURL();
}

const resizeCanvas = (canvas: fabric.Canvas, gridWidth: number, gridHeight: number) => {
  const canvasContainer = document.getElementById('canvas-container');
  if (canvasContainer) {
    const width = canvasContainer.clientWidth;
    const height = canvasContainer.clientHeight;
    
    const scaleX = width / (gridWidth * CANVAS_CONFIG.CELL_SIZE);
    const scaleY = height / (gridHeight * CANVAS_CONFIG.CELL_SIZE);
    const scale = Math.min(scaleX, scaleY);
    
    canvas.setZoom(scale);

    canvas.setWidth(gridWidth * CANVAS_CONFIG.CELL_SIZE * scale);
    canvas.setHeight(gridHeight * CANVAS_CONFIG.CELL_SIZE * scale);
    
    const gridImageUrl = generateGridImage(gridWidth, gridHeight);
    canvas.setBackgroundColor(gridImageUrl, () => canvas.renderAll());
    
    canvas.renderAll();
    canvas.backgroundColor = "#000";
    
    canvas.calcOffset();
  }
}

const updateCanvasCell = (buyer: string, x: number, y: number, numLayers: number, color: string, stageIndex: number, updatedTotalValues: any[]): void => {
  const canvas = store.canvas;
  const square = canvas.getObjects().find((obj: any) => obj.gridX === x && obj.gridY === y && obj.stage === stageIndex) as fabric.Rect & CustomRectOptions;

  if (square) {
    square.set('fill', color);
    square.originalFill = color;
    const updatedLayers = [...square.squareLayers];

    for (let i = 0; i < numLayers; i++) {
      updatedLayers.push({
        owner: buyer,
        color: color
      });
    }
    square.set('squareLayers', updatedLayers);
  
    if (store.selectedSquare && store.selectedSquare.gridX === x && store.selectedSquare.gridY === y && store.selectedSquare.stage === stageIndex) {
      setSelectedSquare(square);
      updateSidebarForSelectedSquare(canvas);
    }

  }
  const stage1Value = Number(fromGweiToMatic(updatedTotalValues[0]));
  const stage2Value = Number(fromGweiToMatic(updatedTotalValues[1]));

  const requiredValueLabel = getTextLabelById(canvas, 'requiredLabel');
  if (requiredValueLabel) {
    requiredValueLabel.text = getRequiredTotalValueText(stageIndex + 1, stage1Value, stage2Value);
  }

  if (isStageCompleted(stageIndex + 1, stage1Value, stage2Value)) {
    const notEnabledLabel = getTextLabelById(canvas, 'lockedLabel');
    if (notEnabledLabel) {
      notEnabledLabel.text = 'Waiting for owner unlock';
      notEnabledLabel.fill = 'green';
    }
  }
  canvas.renderAll();
}

const recreateCanvasForContractEnabled = async (): Promise<void> => {
  const canvas = store.canvas;
  canvas.clear()
  const { stages, totalValues } = await getStagesFromContracts();
  setupCanvas(stages, totalValues);
}

const isStageCompleted = (stageIndex: number, stage1Value: number, stage2Value: number) => {
  if (stageIndex === 1) {
    return stage1Value >= STAGE_THRESHOLDS.STAGE2_ACTIVATION;
  } else if (stageIndex === 2) {
    return stage1Value >= STAGE_THRESHOLDS.STAGE3_STAGE1_ACTIVATION && stage2Value >= STAGE_THRESHOLDS.STAGE3_STAGE2_ACTIVATION;
  }
  return false;
}


const getRequiredTotalValueText = (stageIndex: number, stage1Value: number, stage2Value: number): string => {
  if (stageIndex === 1) {
    return isStageCompleted(stageIndex, stage1Value, stage2Value) ?
      "Requirement Completed" : 
      `Stage 1 Total Value: ${stage1Value}/${STAGE_THRESHOLDS.STAGE2_ACTIVATION} Matic`;
  } else if (stageIndex === 2) {
    const stage1Text = isStageCompleted(1, stage1Value, 0) ? 
      "Requirement 1 Completed" : 
      `Stage 1 Total Value: ${stage1Value}/${STAGE_THRESHOLDS.STAGE3_STAGE1_ACTIVATION} Matic`;

    const stage2Text = isStageCompleted(2, stage1Value, stage2Value) ?
      "Requirement 2 Completed" : 
      `Stage 2 Total Value: ${stage2Value}/${STAGE_THRESHOLDS.STAGE3_STAGE2_ACTIVATION} Matic`;

    return `${stage1Text}\n${stage2Text}`;
  }

  return "";
}

const createTextLabel = (text: string, options: fabric.ITextOptions, id?: string): fabric.Text => {
  const defaultOptions = {
      fontFamily: 'kirbyss',
      originX: 'center',
      selectable: false
  };

  const textLabel: TextLabelWithId = new fabric.Text(text, { ...defaultOptions, ...options }) as TextLabelWithId;
  if (id) {
      textLabel.id = id;
  }
  return textLabel;
}


// 3. Provide a function to get a text label by its ID
const getTextLabelById = (canvas: fabric.Canvas, id: string): TextLabelWithId | undefined => {
  return canvas.getObjects().find((obj: any) => obj.type === 'text' && obj.id === id) as TextLabelWithId;
}

export { updateCanvasCell, resizeCanvas, createTextLabel, getRequiredTotalValueText, generateGridImage, recreateCanvasForContractEnabled, isStageCompleted }