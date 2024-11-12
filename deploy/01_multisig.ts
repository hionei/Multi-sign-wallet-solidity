import { DeployFunction } from "hardhat-deploy/types";
import { Ship } from "../utils";
import { MultiSigWallet__factory, MockUSDT__factory } from "../types";
import { Addressable, parseEther } from "ethers";

const func: DeployFunction = async (hre) => {
  const { deploy } = await Ship.init(hre);

  await deploy(MultiSigWallet__factory, {
    args: [
      [
        "0x68Ad565e8954b8B835aDbfbF0c3b8FD5E6a90a18",
        "0x8fCaEa1E9aF7B59A4f46C69cdEA3afDA83595276",
        "0xF48B08529B787607aE53a3d2b6A129c456A4C263",
      ],
      2,
    ],
  });
};

export default func;
func.tags = ["multisig"];
func.dependencies = ["mocks"];
