import { expect } from "chai";
import { ethers, network } from "hardhat";
import { Signer } from "@ethersproject/abstract-signer";
import { deployDiamond} from "../scripts/deploy";
import { CoreFacet, SpecialsFacet } from "../typechain";
import { impersonate } from "../scripts/utils";

let coreFacet: CoreFacet;
let specialsFacet: SpecialsFacet;
let special: any;
let specialContract: any;
let stamina: any;
let staminaContract: any;
let gold: any;
let goldContract: any;
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

    specialsFacet = (await ethers.getContractAt(
      "SpecialsFacet",
      diamondAddress
    )) as SpecialsFacet;

    stamina = await ethers.getContractFactory("Stamina");
    staminaContract = await stamina.attach("0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6");

    gold = await ethers.getContractFactory("Gold");
    goldContract = await gold.attach("0x8A791620dd6260079BF849Dc5567aDC3F2FdC318");

    special = await ethers.getContractFactory("Specials");
    specialContract = await special.attach("0x610178dA211FEF7D417bC0e6FeD39F05609AD788");

    accounts = await ethers.getSigners();
    alice = accounts[1];
    aliceAddress = await alice.getAddress();
    bob = accounts[2];
    bobAddress = await bob.getAddress();

    const rows = 32;
    const cols = 32;
  
    let mapGold: any = Array.from({ length: rows }, () =>
      Array.from({ length: cols }, () => null)
    );
    for (let i = 0; i < 32; i++) {
      for (let j = 0; j < 32; j++) {
        mapGold[i][j] = 0;
      }
    }
  
    let mapUnits: any = Array.from({ length: rows }, () =>
      Array.from({ length: cols }, () => null)
    );
    for (let i = 0; i < 32; i++) {
      for (let j = 0; j < 32; j++) {
        mapUnits[i][j] = 0;
      }
    }

    mapGold[10][11] = ethers.utils.parseEther("100");
    mapUnits[10][11] = 27;
    mapUnits[11][10] = 120;
    mapUnits[9][10] = 0;

    await coreFacet.initializeGold(mapGold);
    await coreFacet.initializeUnits(mapUnits);

  });
  it("Test register", async function () {
    coreFacet = await impersonate(aliceAddress, coreFacet, ethers, network);
    specialsFacet = await impersonate(aliceAddress, coreFacet, ethers, network);
    await coreFacet.testRegister([10, 10]);
    await expect(coreFacet.register()).to.be.revertedWith(
      "CoreFacet: already registered"
    );
  });
  it("Test claim stamina", async function () {
    await expect(coreFacet.claimStamina()).to.be.revertedWith(
      "CoreFacet: stm 24hr limit"
    );
    const preStaminaBalance = await staminaContract.balanceOf(aliceAddress);
    await network.provider.send("evm_increaseTime", [86400]);
    await network.provider.send("evm_mine");
    
    await coreFacet.claimStamina();
    const postStaminaBalance = await staminaContract.balanceOf(aliceAddress);

    expect(parseInt(ethers.utils.formatUnits(postStaminaBalance))).to.be.
      equal(parseInt(ethers.utils.formatUnits(preStaminaBalance)) * 2);
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
  it("Test attack empty", async function () {
    const troopStartPre = await coreFacet.getTile([
      startCoords[0],
      startCoords[1],
    ]);
    await coreFacet.attack(
      [startCoords[0], startCoords[1]],
      [startCoords[0] - 1, startCoords[1]],
      100
    );
    const troopStartPost = await coreFacet.getTile([
      startCoords[0],
      startCoords[1],
    ]);
    const tileAttacked = await coreFacet.getTile([
      startCoords[0] - 1,
      startCoords[1],
    ]);
    expect(tileAttacked.account === aliceAddress);
    expect(parseInt(ethers.utils.formatUnits(tileAttacked.units, 0))).to.be.equal(100);
  });
  it("Test attack tile with units inside", async function () {
    const troopStartPre = await coreFacet.getTile([10, 10]);
    await coreFacet.attack(
      [10, 10],
      [10, 11],
      50
    );
    const troopStartPost = await coreFacet.getTile([10,10]);
    const tileAttacked = await coreFacet.getTile([10,11]);
    expect(tileAttacked.account === aliceAddress);
    expect(parseInt(ethers.utils.formatUnits(troopStartPre.units, 0))).to.be.greaterThan(
      (
        parseInt(ethers.utils.formatUnits(troopStartPost.units, 0)) +
        parseInt(ethers.utils.formatUnits(tileAttacked.units, 0))
      )
    );
    expect(parseInt(ethers.utils.formatUnits(tileAttacked.units, 0))).to.be.lessThan(50);
    });
    it("Test attack far tile", async function () {
      await expect(coreFacet.attack(
        [9, 10],
        [30, 13],
        50
      )).to.be.reverted;
    });
    it("Test deploy units", async function() {
      const prevUnitsOnTile = await coreFacet.getTile([10, 11]);

      await coreFacet.deployUnits([10, 11], 100);

      const tileUnitsAfterDeploy = await coreFacet.getTile([10, 11]);

      expect(parseInt(ethers.utils.formatUnits(tileUnitsAfterDeploy.units, 0))).to.be.
        equal(parseInt(ethers.utils.formatUnits(prevUnitsOnTile.units, 0)) + 100);

    });
    it("Test claim gold", async function () {
      const goldInTailAtStart = await coreFacet.getTile([10, 11]);

      await coreFacet.claimGold([10,11]);

      const goldInTailAfterclaim = await coreFacet.getTile([10, 11]);

      expect(parseInt(ethers.utils.formatUnits(goldInTailAtStart.gold))).to.be.
        greaterThan(parseInt(ethers.utils.formatUnits(goldInTailAfterclaim.gold)));

      const goldBalance = await goldContract.balanceOf(aliceAddress);

      expect(parseInt(ethers.utils.formatUnits(goldBalance))).to.be.equal(50);
      await expect(coreFacet.claimGold([10,11])).to.be.revertedWith("CoreFacet: gld 24hr limit");
    });

    it("Test claim gold after 24 hours", async function() {
      await network.provider.send("evm_increaseTime", [86400]);
      await network.provider.send("evm_mine");
      await coreFacet.claimGold([10,11]);
      const goldBalance = await goldContract.balanceOf(aliceAddress);
      expect(parseInt(ethers.utils.formatUnits(goldBalance))).to.be.equal(100);
    });

    it("Test buy special attack nft", async function() {
      const amount = 1;
      const nftID = 0;
      const nftPrice = 50;
      const prevGoldBalance = await goldContract.balanceOf(aliceAddress);
      await specialContract.connect(alice).mint(nftID, amount);
      const specialAttackNFT = await specialContract.balanceOf(aliceAddress, nftID);
      const afterGoldBalance = await goldContract.balanceOf(aliceAddress);
      expect(parseInt(ethers.utils.formatUnits(specialAttackNFT, 0))).to.be.equal(amount);
      expect(parseInt(ethers.utils.formatUnits(afterGoldBalance))).to.be.
        equal(parseInt(ethers.utils.formatUnits(prevGoldBalance)) - nftPrice);
    });

/*     it("Test special attack", async function() {
      console.log(await coreFacet.getTile([10, 10]));
      console.log(await coreFacet.getTile([19, 25]));
      await specialsFacet.connect(alice).longRange(
        [10, 10],
        [19, 25],
        40
      )
      console.log(await coreFacet.getTile([19, 25]))
    }); */
});
