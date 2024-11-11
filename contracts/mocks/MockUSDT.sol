// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDT is ERC20 {
  constructor() ERC20("Tether USD", "USDT") {}

  function mint(uint256 amount) external {
    _mint(msg.sender, amount);
  }
}
