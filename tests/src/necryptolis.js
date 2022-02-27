import {
  executeScript,
  mintFlow,
  sendTransaction,
  deployContractByName,
} from "flow-js-testing";
import { getNecryptolisAdminAddress } from "./common";

/*
 * Deploys necessary contracts to NecryptolisAdmin.
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const deployNecryptolis = async () => {
  const necryptolisAdmin = await getNecryptolisAdminAddress();
  await mintFlow(necryptolisAdmin, "10.0");

  await deployContractByName({
    to: necryptolisAdmin,
    name: "NonFungibleToken",
  });

  await deployContractByName({
    to: necryptolisAdmin,
    name: "FUSD",
  });

  await deployContractByName({
    to: necryptolisAdmin,
    name: "MetadataViews",
  });

  const addressMap = {
    NonFungibleToken: necryptolisAdmin,
    FUSD: necryptolisAdmin,
    MetadataViews: necryptolisAdmin,
  };

  return deployContractByName({
    to: necryptolisAdmin,
    name: "Necryptolis",
    addressMap,
  });
};

/*
 * Setups Necryptolis collection on account and exposes public capability.
 * @param {string} account - account address
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const setupNecryptolisOnAccount = async (account) => {
  const name = "user/setup_account";
  const signers = [account];

  await sendTransaction({ name, signers });
  // we also do this method in order to populate the admin fusd vault receiver in plotSalesInfo
  return changePlotSalesInfo(0.01, 1, 1, 600, 600, 200, 200);
};

export const setupPlotSalesInfo = async (account) => {
  const name = "admin/change_plot_sales_info";
  const signers = [account];

  return sendTransaction({ name, signers });
};

export const mintCemeteryPlot = async (
  left,
  top,
  width,
  height,
  recipientAddress
) => {
  const necryptolisAdmin = await getNecryptolisAdminAddress();

  const name = "admin/mint_cemetery_plot";
  const args = [left, top, width, height, recipientAddress];
  const signers = [necryptolisAdmin];

  return sendTransaction({ name, args, signers });
};

export const addGravestone = async (
  plotId,
  graveTitle,
  fromDate = "",
  toDate = "",
  metadata = {}
) => {
  const necryptolisAdmin = await getNecryptolisAdminAddress();

  const name = "user/add_gravestone";
  const args = [plotId, graveTitle, fromDate, toDate, metadata];
  const signers = [necryptolisAdmin];

  return sendTransaction({ name, args, signers });
};

export const setToDate = async (plotId, toDate) => {
  const necryptolisAdmin = await getNecryptolisAdminAddress();

  const name = "user/set_to_date";
  const args = [plotId, toDate];
  const signers = [necryptolisAdmin];

  return sendTransaction({ name, args, signers });
};

export const lightCandle = async (user, plotOwnerAddress, plotId) => {
  const name = "user/light_a_candle";
  const args = [plotOwnerAddress, plotId];
  const signers = [user];

  return sendTransaction({ name, args, signers });
};

export const trimGrave = async (user, plotOwnerAddress, plotId) => {
  const name = "user/trim_grave";
  const args = [plotOwnerAddress, plotId];
  const signers = [user];

  return sendTransaction({ name, args, signers });
};

export const buryKittyItem = async (user, plotId, kittyItemId) => {
  const name = "user/bury_kitty_item";

  const args = [plotId, kittyItemId];
  const signers = [user];

  return sendTransaction({ name, args, signers });
};

export const changePlotSalesInfo = async (
  squarePixelPrice,
  candlePrice,
  trimPrice,
  maxPlotHeight,
  maxPlotWidth,
  minPlotHeight,
  minPlotWidth
) => {
  const name = "admin/change_plot_sales_info";

  const args = [
    squarePixelPrice,
    candlePrice,
    trimPrice,
    maxPlotHeight,
    maxPlotWidth,
    minPlotHeight,
    minPlotWidth,
  ];

  const necryptolisAdmin = await getNecryptolisAdminAddress();
  const signers = [necryptolisAdmin];

  return sendTransaction({ name, args, signers });
};

export const changeImagesBaseUrl = async (newName) => {
  const name = "admin/change_images_base_url";

  const args = [newName];

  const necryptolisAdmin = await getNecryptolisAdminAddress();
  const signers = [necryptolisAdmin];

  return sendTransaction({ name, args, signers });
};

// SCRIPTS

export const getCemeteryPlots = async () => {
  const name = "get_plot_datas";

  return executeScript({ name });
};

export const getPlotSalesInfo = async () => {
  const name = "get_plot_sales_info";

  return executeScript({ name });
};

export const getImagesBaseURL = async () => {
  const name = "get_images_base_url";

  return executeScript({ name });
};

export const getCandles = async (ownerAddress, plotId) => {
  const name = "get_candles";

  const args = [ownerAddress, plotId];
  const res = await executeScript({ name, args });

  return executeScript({ name, args });
};

export const getTrimmedOnTimestamp = async (ownerAddress, plotId) => {
  const name = "get_trimmed_on_timestamp";

  const args = [ownerAddress, plotId];
  const res = await executeScript({ name, args });

  return executeScript({ name, args });
};

export const getPlotMetadata = async (ownerAddress, plotId) => {
  const name = "get_plot_metadata";

  const args = [ownerAddress, plotId];
  const res = await executeScript({ name, args });

  return executeScript({ name, args });
};
