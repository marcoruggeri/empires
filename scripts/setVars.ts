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
} from "../typechain";

const { getSelectors, FacetCutAction } = require("./libraries/diamond");

const gasPrice = 35000000000;

const diamondAddress = "0xa19F3bB514C7A2b1f7E7441AA2Bfe62166e7Df37";
const specialsAddress = "0x7AB9aC30e19811f71ABa109308ef46073951C9A2";

export async function deployDiamond() {
  const accounts: Signer[] = await ethers.getSigners();
  const deployer = accounts[0];
  const deployerAddress = await deployer.getAddress();
  console.log("Deployer:", deployerAddress);

  const specials = (await ethers.getContractAt(
    "Specials",
    specialsAddress
  )) as Specials;

  const tx = await specials.addSpecial(1, ethers.utils.parseEther("500"), {
    gasPrice,
  });
  await tx.wait();
  const tx2 = await specials.addSpecial(2, ethers.utils.parseEther("20"), {
    gasPrice,
  });
  await tx2.wait();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployDiamond()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}
