import { fabric } from "fabric";
import { CustomRectOptions } from "./interfaces";

export interface Store {
    selectedSquare: fabric.Rect & CustomRectOptions | null ;
    colorPicker: string[];
    canvas: fabric.Canvas;
}

export const store: Store = {
    selectedSquare: null,
    colorPicker: ["#FFD700", "#8B4513"],
    canvas: new fabric.Canvas("c", { selection: false })
};

export function setSelectedSquare(square: fabric.Rect & CustomRectOptions | null ) {
    store.selectedSquare = square;
}

