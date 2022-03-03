import { Network } from "hardhat/types";

export async function impersonate(
  address: string,
  contract: any,
  ethers: any,
  network: Network
) {
  await network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [address],
  });
  let signer = await ethers.getSigner(address);
  contract = contract.connect(signer);
  return contract;
}
