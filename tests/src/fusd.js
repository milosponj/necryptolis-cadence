import {
  deployContractByName,
  executeScript,
  sendTransaction,
} from "flow-js-testing";
import { getNecryptolisAdminAddress, toUFix64 } from "./common";

export const deployFusd = async () => {
  const admin = await getNecryptolisAdminAddress();

  return deployContractByName({ to: admin, name: "FUSD" });
};

export const setupFUSDOnAccount = async (account) => {
  const name = "fusd/setup_account";
  const signers = [account];

  return sendTransaction({ name, signers });
};

export const mintFUSD = async (recipient, amount) => {
  const admin = await getNecryptolisAdminAddress();

  const name = "fusd/mint_fusd";
  const args = [recipient, toUFix64(amount)];
  const signers = [admin];

  return sendTransaction({ name, args, signers });
};

export const getFUSDBalance = async (address) => {
  const name = "get_fusd_balance";
  const args = [address];

  return executeScript({ args, name });
};
