import { solidityPackedKeccak256 } from "ethers";

const main = async () => {
  // keccak256(abi.encode(uint256(keccak256("InvestingVault.storage")) - 1)) & ~bytes32(uint256(0xff))
  const encodedUint = solidityPackedKeccak256(["string"], ["InvestingVault.storage"]);
  const storageLocation = solidityPackedKeccak256(["uint256"], [BigInt(encodedUint) - 1n]);
  console.log(storageLocation);
};

main();
