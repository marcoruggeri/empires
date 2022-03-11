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

const diamondAddress = "0xC38EAb8303331b999388dbFda99750DE562a9448";

export async function setupVRF() {
  const accounts: Signer[] = await ethers.getSigners();
  const deployer = accounts[0];
  const deployerAddress = await deployer.getAddress();
  console.log("Deployer:", deployerAddress);

  const vrfFacet = (await ethers.getContractAt(
    "VRFFacet",
    diamondAddress
  )) as VRFFacet;

  const vrfCoordinatorAddress = "0x8C7382F9D8f56b33781fE506E897a4F1e2d17255";
  const linkAddress = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB";
  const keyHash =
    "0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4";
  const fee = 100000000000000;

  await vrfFacet.register({ gasLimit: 300000, gasPrice });

  // const linkERC20 = (await ethers.getContractAt(
  //   "contracts/interfaces/IERC20.sol:IERC20",
  //   linkAddress
  // )) as IERC20;

  // await linkERC20.transfer(diamondAddress, ethers.utils.parseUnits("0.1"));

  // console.log("transfered Link to diamond");

  // await vrfFacet.setVrf(linkAddress, keyHash, fee);
  // console.log("address setp");
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
