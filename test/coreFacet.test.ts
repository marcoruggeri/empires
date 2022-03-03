import { expect } from "chai";
import { ethers, network } from "hardhat";
import { Signer } from "@ethersproject/abstract-signer";
import { deployDiamond } from "../scripts/deploy";
import { CoreFacet } from "../typechain";
import { impersonate } from "../scripts/utils";

let coreFacet: CoreFacet;
let diamondAddress;
let accounts: Signer[];
let alice: Signer;
let aliceAddress: string;
let bob: Signer;
let bobAddress: string;

let startCoords: number[] = [];

describe("CoreFacet", function () {
  before(async function () {
    diamondAddress = await deployDiamond();

    coreFacet = (await ethers.getContractAt(
      "CoreFacet",
      diamondAddress
    )) as CoreFacet;

    accounts = await ethers.getSigners();
    alice = accounts[1];
    aliceAddress = await alice.getAddress();
    bob = accounts[2];
    bobAddress = await bob.getAddress();
  });
  it("Test register", async function () {
    coreFacet = await impersonate(aliceAddress, coreFacet, ethers, network);
    await coreFacet.register();
    await expect(coreFacet.register()).to.be.revertedWith(
      "CoreFacet: already registered"
    );
  });
  it("Test check coords", async function () {
    let map: any = await coreFacet.getMap();
    startCoords = [];
    for (let i = 0; i < map.length; i++) {
      for (let j = 0; j < map[i].length; j++) {
        if (map[i][j].account == aliceAddress) {
          startCoords.push(i);
          startCoords.push(j);
        }
      }
    }

    console.log(startCoords);

    await expect(
      coreFacet.attack(
        [startCoords[0], startCoords[1]],
        [startCoords[0] + 2, startCoords[1]],
        100
      )
    ).to.be.revertedWith("CoreFacet: Invalid x");
    await expect(
      coreFacet.attack(
        [startCoords[0], startCoords[1]],
        [startCoords[0], startCoords[1] + 2],
        100
      )
    ).to.be.revertedWith("CoreFacet: Invalid y");
    await expect(
      coreFacet.attack(
        [startCoords[0], startCoords[1]],
        [startCoords[0], startCoords[1]],
        100
      )
    ).to.be.revertedWith("CoreFacet: equal from to coords");
  });
  it("Test attack to empty", async function () {
    const troopStartPre = await coreFacet.getTile([
      startCoords[0],
      startCoords[1],
    ]);
    await coreFacet.attack(
      [startCoords[0], startCoords[1]],
      [startCoords[0] + 1, startCoords[1]],
      100
    );
    const troopStartPost = await coreFacet.getTile([
      startCoords[0],
      startCoords[1],
    ]);
    const tileAttacked = await coreFacet.getTile([
      startCoords[0] + 1,
      startCoords[1],
    ]);
    expect(parseInt(ethers.utils.formatUnits(troopStartPre.troops))).to.equal(
      parseInt(
        ethers.utils.formatUnits(troopStartPost.troops) +
          parseInt(ethers.utils.formatUnits(tileAttacked.troops))
      )
    );
    expect(tileAttacked.account).to.equal(aliceAddress);
  });
});
