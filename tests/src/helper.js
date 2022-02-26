import {
  deployContractByName,
  mintFlow,
  sendTransaction,
} from "flow-js-testing";
import { getNecryptolisAdminAddress } from "./common";

export const deployKittyItems = async (address) => {
  await mintFlow(address, "10.0");
  const admin = await getNecryptolisAdminAddress();

  const addressMap = { NonFungibleToken: admin };
  return deployContractByName({
    to: address,
    name: "KittyItems",
    addressMap,
  });
};

export const setupKittyItemsOnAccount = async (account) => {
  const name = "kittyItems/setup_account";
  const signers = [account];

  return sendTransaction({ name, signers });
};

/*
 * Mints KittyItem of a specific **itemType** and sends it to **recipient**.
 * @param {UInt64} itemType - type of NFT to mint
 * @param {string} recipient - recipient account address
 * @throws Will throw an error if execution will be halted
 * @returns {Promise<*>}
 * */
export const mintKittyItem = async (
  kittyAdmin,
  recipient,
  itemType,
  itemRarity
) => {
  const name = "kittyItems/mint_kitty_item";
  const args = [recipient, itemType, itemRarity];
  const signers = [kittyAdmin];

  return sendTransaction({ name, args, signers });
};
