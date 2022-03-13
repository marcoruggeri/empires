// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const NFT = await ethers.getContractFactory("Specials");
  const nft = await NFT.deploy(
    "0xa19F3bB514C7A2b1f7E7441AA2Bfe62166e7Df37",
    "0x0f98D2a70E0e5936C779736bD37D5d0717EF6b50"
  );

  await nft.deployed();

  console.log("nft deployed to:", nft.address);
  await nft.setUri(
    "ipfs://bafybeiaq4odk44sbaru7xrxc4yq5n4uih23ekkqwqfrx5xxtdpurs7cahu"
  );

  await nft.addSpecial(0, ethers.utils.parseUnits("50"));
  await nft.addSpecial(1, ethers.utils.parseUnits("500"));
  await nft.addSpecial(2, ethers.utils.parseUnits("20"));
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
