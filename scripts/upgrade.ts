import { run, ethers } from "hardhat";
import {
  convertFacetAndSelectorsToString,
  DeployUpgradeTaskArgs,
  FacetsAndAddSelectors,
} from "./utils";
// import { CoreFacet__factory } from "../typechain";
// import { CoreFacetInterface } from "../typechain/CoreFacet";

export async function upgrade(diamondAddress: string) {
  const diamondUpgrader = "0x296903b6049161bebEc75F6f391a930bdDBDbbFc";

  const facets: FacetsAndAddSelectors[] = [
    {
      facetName: "CoreFacet",
      addSelectors: [
        "function register() external",
        "function claimStamina() external",
        "function claimGold(uint256[2] calldata _coords) external",
        "function deployUnits(uint256[2] calldata _coords, uint256 _amount) external",
        "function attack(uint256[2] calldata _from, uint256[2] calldata _to, uint256 _amount) external",
      ],
      removeSelectors: [
        "function register() external",
        "function claimStamina() external",
        "function deployUnits(uint256[2] calldata _coords, uint256 _amount) external",
        "function attack(uint256[2] calldata _from, uint256[2] calldata _to, uint256 _amount) external",
      ],
    },
    {
      facetName: "SpecialsFacet",
      addSelectors: [
        "function longRange(uint256[2] calldata _from, uint256[2] calldata _to, uint256 _amount) external",
      ],
      removeSelectors: [
        "function longRange(uint256[2] calldata _from, uint256[2] calldata _to, uint256 _amount) external",
      ],
    },
  ];

  const joined = convertFacetAndSelectorsToString(facets);

  // let iface: AlchemicaFacetInterface = new ethers.utils.Interface(
  //   AlchemicaFacet__factory.abi
  // ) as AlchemicaFacetInterface;

  // const calldata = iface.encodeFunctionData(
  //   //@ts-ignore
  //   "setVars",
  //   [
  //     alchemicaTotals(),
  //     boostMultipliers,
  //     greatPortalCapacity,
  //     installationDiamond
  //       ? installationDiamond
  //       : "0x7Cc7B6964d8C49d072422B2e7FbF55C2Ca6FefA5",
  //     "0x0000000000000000000000000000000000000000",
  //     "0x0000000000000000000000000000000000000000",
  //     [alchemica.fud, alchemica.fomo, alchemica.alpha, alchemica.kek],
  //     alchemica.glmr,
  //     "0x",
  //     "0x7Cc7B6964d8C49d072422B2e7FbF55C2Ca6FefA5",
  //     "0x7Cc7B6964d8C49d072422B2e7FbF55C2Ca6FefA5",
  //   ]
  // );

  const args: DeployUpgradeTaskArgs = {
    diamondUpgrader: diamondUpgrader,
    diamondAddress: diamondAddress,
    facetsAndAddSelectors: joined,
    initAddress: diamondAddress,
    initCalldata: undefined,
    useLedger: false,
    useMultisig: false,
  };

  await run("deployUpgrade", args);
}

if (require.main === module) {
  upgrade("0xC9B5067f7a07c12A1C2b7749B8B66CE83b8ce4E1")
    .then(() => process.exit(0))
    // .then(() => console.log('upgrade completed') /* process.exit(0) */)
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}
