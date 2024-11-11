import { DeployFunction } from "hardhat-deploy/types";
import { Ship } from "../utils";
import { MultiSigWallet__factory, MockUSDT__factory } from "../types";
import { Addressable, parseEther } from "ethers";

const func: DeployFunction = async (hre) => {
  const { deploy } = await Ship.init(hre);

  await deploy(MultiSigWallet__factory, {
    args: [["0x1442eF218642014363bbBEB9880a7822999CB18a", "0xEAF9dCC6D89C528ceb4766F709229b17220c606b"], 2],
  });
};

export default func;
func.tags = ["multisig"];
func.dependencies = ["mocks"];
