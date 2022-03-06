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
        // "function register() external",
        // "function claimStamina() external",
        "function claimGold(uint256[2] calldata _coords) external",
        // "function deployUnits(uint256[2] calldata _coords, uint256 _amount) external",
        // "function attack(uint256[2] calldata _from, uint256[2] calldata _to, uint256 _amount) external",
      ],
      removeSelectors: [
        // "function register() external",
        // "function claimStamina() external",
        // "function deployUnits(uint256[2] calldata _coords, uint256 _amount) external",
        // "function attack(uint256[2] calldata _from, uint256[2] calldata _to, uint256 _amount) external",
        "function claimGold(uint256[2] calldata _coords) external",
      ],
    },
    // {
    //   facetName: "SpecialsFacet",
    //   addSelectors: [
    //     "function longRange(uint256[2] calldata _from, uint256[2] calldata _to, uint256 _amount) external",
    //   ],
    //   removeSelectors: [
    //     "function longRange(uint256[2] calldata _from, uint256[2] calldata _to, uint256 _amount) external",
    //   ],
    // },
  ];

  const joined = convertFacetAndSelectorsToString(facets);

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
  upgrade("0xc7F33460243Db61ad8BB0625F56964c3dEE788f2")
    .then(() => process.exit(0))
    // .then(() => console.log('upgrade completed') /* process.exit(0) */)
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}
