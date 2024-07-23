import { fabric } from "fabric";

interface CustomRectOptions extends fabric.IRectOptions {
  originalFill?: string;
  squareValue?: number;
  squareLayers?: Layer[]; 
  gridX: number;
  gridY: number;
  yOffset: number;
  stage: number;
}

interface Layer {
  owner: string;
  color: string;
}

interface Cell {
  baseValue: bigint; 
  layers: Layer[];
}

interface Stage {
  isEnabled: boolean;
  cells: Cell[][];
}

interface TextLabelWithId extends fabric.Text {
  id?: string;
}


export type { CustomRectOptions, Layer, Cell, Stage, TextLabelWithId }