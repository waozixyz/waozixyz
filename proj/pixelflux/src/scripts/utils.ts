import BigNumber from 'bignumber.js';

const fromGweiToMatic = (value: bigint): string => {
  if (!value) return
  const gweiValue = new BigNumber(value.toString());
  const maticValue = gweiValue.dividedBy(new BigNumber(10).pow(9));
  return maticValue.toString();
};

const fromWeiToMatic = (value: BigNumber): string => {
  const maticValue = value.dividedBy(new BigNumber(10).pow(18));
  return maticValue.toString();
};

const fromMaticToWei = (value: number): string => {
  const maticValue = new BigNumber(value);
  const weiValue = maticValue.multipliedBy(new BigNumber(10).pow(18));
  return weiValue.toString();
};

const convertToFullHex = (hex: string): string  => {
  if (hex.length === 4) { 
    const r = hex[1];
    const g = hex[2];
    const b = hex[3];
    return `#${r}${r}${g}${g}${b}${b}`;
  }
  return hex;
}

const roundToTwoSignificantFigures = (num: number): number => {
  if (num === 0) {
      return 0;
  }

  const magnitude = Math.floor(Math.log10(Math.abs(num)));
  const scale = Math.pow(10, magnitude - 1);
  return parseFloat((Math.round(num / scale) * scale).toPrecision(2));
}

export { fromGweiToMatic, fromWeiToMatic, fromMaticToWei, convertToFullHex, roundToTwoSignificantFigures}