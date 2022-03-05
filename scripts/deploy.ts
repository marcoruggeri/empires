//@ts-ignore
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

const gasPrice = 31000000000;

export async function deployDiamond() {
  const accounts: Signer[] = await ethers.getSigners();
  const deployer = accounts[0];
  const deployerAddress = await deployer.getAddress();
  console.log("Deployer:", deployerAddress);

  // deploy DiamondCutFacet
  const DiamondCutFacet = await ethers.getContractFactory("DiamondCutFacet");
  const diamondCutFacet = await DiamondCutFacet.deploy({ gasPrice });
  await diamondCutFacet.deployed();
  console.log("DiamondCutFacet deployed:", diamondCutFacet.address);

  // deploy Diamond
  const Diamond = (await ethers.getContractFactory(
    "Diamond"
  )) as Diamond__factory;
  const diamond = await Diamond.deploy(
    deployerAddress,
    diamondCutFacet.address,
    { gasPrice }
  );
  await diamond.deployed();
  console.log("Diamond deployed:", diamond.address);

  // deploy DiamondInit
  const DiamondInit = (await ethers.getContractFactory(
    "DiamondInit"
  )) as DiamondInit__factory;
  const diamondInit = await DiamondInit.deploy({ gasPrice });
  await diamondInit.deployed();
  console.log("DiamondInit deployed:", diamondInit.address);

  // deploy facets
  console.log("");
  console.log("Deploying facets");
  const FacetNames = [
    "DiamondLoupeFacet",
    "OwnershipFacet",
    "CoreFacet",
    "SpecialsFacet",
  ];
  const cut = [];
  for (const FacetName of FacetNames) {
    const Facet = await ethers.getContractFactory(FacetName);
    const facet = await Facet.deploy({ gasPrice });
    await facet.deployed();
    console.log(`${FacetName} deployed: ${facet.address}`);
    cut.push({
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet),
    });
  }

  const diamondCut = (await ethers.getContractAt(
    "IDiamondCut",
    diamond.address
  )) as DiamondCutFacet;

  // call to init function
  const functionCall = diamondInit.interface.encodeFunctionData("init");
  const tx = await diamondCut.diamondCut(
    cut,
    diamondInit.address,
    functionCall,
    { gasPrice }
  );
  console.log("Diamond cut tx: ", tx.hash);
  const receipt = await tx.wait();
  if (!receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`);
  }
  console.log("Completed diamond cut");

  const ownershipFacet = (await ethers.getContractAt(
    "OwnershipFacet",
    diamond.address
  )) as OwnershipFacet;
  const diamondOwner = await ownershipFacet.owner();
  console.log("Diamond owner is:", diamondOwner);

  if (diamondOwner !== deployerAddress) {
    throw new Error(
      `Diamond owner ${diamondOwner} is not deployer address ${deployerAddress}!`
    );
  }

  const Stamina = await ethers.getContractFactory("Stamina");
  const stamina = (await Stamina.deploy(diamond.address, {
    gasPrice,
  })) as Stamina;
  const Gold = await ethers.getContractFactory("Gold");
  const gold = (await Gold.deploy(
    "0x0000000000000000000000000000000000000000",
    "0x0000000000000000000000000000000000000000",
    { gasPrice }
  )) as Gold;
  const Specials = await ethers.getContractFactory("Specials");
  const specials = (await Specials.deploy(diamond.address, gold.address, {
    gasPrice,
  })) as Specials;

  console.log(`Stamina deployed: ${stamina.address}`);
  console.log(`Gold deployed: ${gold.address}`);
  console.log(`Specials deployed: ${specials.address}`);

  await gold.setAddresses(diamond.address, specials.address, { gasPrice });

  const coreFacet = (await ethers.getContractAt(
    "CoreFacet",
    diamond.address
  )) as CoreFacet;

  const rows = 32;
  const cols = 32;

  let map: any = Array.from({ length: rows }, () =>
    Array.from({ length: cols }, () => null)
  );
  for (let i = 0; i < 32; i++) {
    for (let j = 0; j < 32; j++) {
      let r = Math.floor(Math.random() * 4);
      let gold: any = 0;
      if (r === 0) {
        gold = (Math.floor(Math.random() * 74) + 25).toString();
      }
      let tile = {
        account: "0x0000000000000000000000000000000000000000",
        units: 0,
        gold: gold === 0 ? 0 : ethers.utils.parseUnits(gold),
      };
      map[i][j] = tile;
    }
  }

  await coreFacet.initializeMap(map, { gasPrice });

  await coreFacet.setAddresses(
    stamina.address,
    gold.address,
    specials.address,
    { gasPrice }
  );

  await specials.addSpecial(0, ethers.utils.parseUnits("50"), { gasPrice });

  return diamond.address;
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
