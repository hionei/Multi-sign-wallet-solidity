import { DeployFunction } from "hardhat-deploy/types";
import { Ship } from "../utils";
import { MockUSDT__factory } from "../types";

const func: DeployFunction = async (hre) => {
  const { deploy } = await Ship.init(hre);

  if (hre.network.tags.test) {
    await deploy(MockUSDT__factory);
  }
};

export default func;
func.tags = ["mocks"];
