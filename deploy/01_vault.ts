import { DeployFunction } from "hardhat-deploy/types";
import { Ship } from "../utils";
import { InvestingVault__factory, MockUSDT__factory } from "../types";
import { Addressable, parseEther } from "ethers";

const func: DeployFunction = async (hre) => {
  const { deploy, connect, accounts } = await Ship.init(hre);

  let usdt: string | Addressable = "0x55d398326f99059fF775485246999027B3197955";

  if (hre.network.tags.test) {
    usdt = (await connect(MockUSDT__factory)).target;
  }

  await deploy(InvestingVault__factory, {
    proxy: {
      proxyContract: "OpenZeppelinTransparentProxy",
      execute: {
        methodName: "initialize",
        args: [usdt, accounts.deployer.address, parseEther("100"), parseEther("1")],
      },
    },
  });
};

export default func;
func.tags = ["vault"];
func.dependencies = ["mocks"];
