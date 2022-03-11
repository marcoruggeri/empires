import { Signer } from "@ethersproject/abstract-signer";
import { ethers } from "hardhat";
import {
  DiamondCutFacet,
  DiamondInit__factory,
  Diamond__factory,
  OwnershipFacet,
  Stamina,
  Gold,
  Specials,
  CoreFacet,
  VRFFacet,
  IERC20,
} from "../typechain";

import { RequestConfig } from "../types";

const { getSelectors, FacetCutAction } = require("./libraries/diamond");

const gasPrice = 35000000000;

const diamondAddress = "0xD0535f73DBC8b3d2f4C4a78De48921688c49F54C";

export async function setupVRF() {
  const accounts: Signer[] = await ethers.getSigners();
  const deployer = accounts[0];
  const deployerAddress = await deployer.getAddress();
  console.log("Deployer:", deployerAddress);

  const vrfFacet = (await ethers.getContractAt(
    "VRFFacet",
    diamondAddress
  )) as VRFFacet;

  const requestConfig: RequestConfig = {
    subId: 0,
    callbackGasLimit: 200000,
    requestConfirmations: 10,
    numWords: 6,
    keyHash:
      "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f",
  };

  const vrfCoordinatorAddress = "0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed";
  const linkAddress = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB";

  const linkERC20 = (await ethers.getContractAt(
    "contracts/interfaces/IERC20.sol:IERC20",
    linkAddress
  )) as IERC20;

  await linkERC20.transfer(diamondAddress, ethers.utils.parseUnits("0.1"));

  console.log("transfered Link to diamond");

  await vrfFacet.setConfig(requestConfig);
  console.log("config set up");
  await vrfFacet.setVrfAddresses(vrfCoordinatorAddress, linkAddress);
  console.log("address setp");

  await vrfFacet.subscribe();
  console.log("subscribed");

  await vrfFacet.topUpSubscription(ethers.utils.parseUnits("0.1"));
  console.log("toppedup");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  setupVRF()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}
