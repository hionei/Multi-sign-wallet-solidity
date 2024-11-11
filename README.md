# Bridge Contract Functional Documentation

## Overview

The Bridge contract facilitates bridging assets between different networks. It allows users to deposit tokens into the contract, which are then managed by designated keepers for cross-network transactions. This document provides an overview of the contract's functionalities, roles, and usage.

## Contract Details

- **Contract Name:** Bridge
- **Solidity Version:** ^0.8.20
- **License:** Unlicense
- **Dependencies:**
  - OpenZeppelin's AccessControl
  - OpenZeppelin's ReentrancyGuard
  - OpenZeppelin's SafeERC20
  - OpenZeppelin's Address
  - Custom `Sig` library from "./libraries/Structs.sol"

## Roles

The contract defines two roles:

1. **Admin (ADMIN_ROLE):** Can manage keepers and withdraw tokens from the contract.
2. **Keeper (KEEPER_ROLE):** Manages transactions and can withdraw tokens on behalf of users.

## Functions

### Constructor

- **Description:** Initializes the bridge contract with the admin role and sets the chain ID.
- **Parameters:**
  - `_admin`: Admin address for the bridge.
- **Access:** Public

### deposit

- **Description:** Allows users to deposit tokens into the bridge for cross-network transactions.
- **Parameters:**
  - `_key`: Transaction key.
  - `_token`: Token address to deposit.
  - `_amount`: Amount of tokens to deposit.
  - `_sig`: Signature of the designated keeper.
- **Access:** External

### withdraw

- **Description:** Allows keepers to withdraw tokens from the bridge and send them to users.
- **Parameters:**
  - `_key`: Transaction key.
  - `_to`: Address of the user receiving tokens.
  - `_token`: Token address to withdraw.
  - `_amount`: Amount of tokens to withdraw.
- **Access:** External, Non-reentrant, OnlyKeeper

### addPool

- **Description:** Allows the admin to add tokens to the contract's pool.
- **Parameters:**
  - `_token`: Token address to add to the pool.
  - `_amount`: Amount of tokens to add.
- **Access:** External, OnlyAdmin

### withdrawPool

- **Description:** Allows the admin to withdraw tokens from the contract's pool.
- **Parameters:**
  - `_token`: Token address to withdraw from the pool.
  - `_to`: Address to receive the withdrawn tokens.
  - `_amount`: Amount of tokens to withdraw.
- **Access:** External, OnlyAdmin

### Fallback and Receive Functions

- **Fallback:** Reverts all ETH deposits and other calls.
- **Receive:** Reverts all ETH deposits and other calls.

## Events

The contract emits the following events:

- `Deposit(bytes32 indexed key, address indexed token, uint256 amount)`: Emits when a deposit occurs.
- `Withdraw(bytes32 indexed key, address indexed token, uint256 amount)`: Emits when a withdrawal occurs.

## Errors

The contract defines the following custom errors:

- `InvalidParams()`: Indicates invalid parameters in a function call.
- `InvalidAmount()`: Indicates an invalid token amount in a function call.

## Usage

1. **Admin Setup:**

   - Deploy the contract with an admin address.

2. **Deposit Tokens:**

   - Users call the `deposit` function with the required parameters and a valid keeper signature.

3. **Withdraw Tokens:**

   - Keepers call the `withdraw` function to send tokens to users.

4. **Manage Token Pool:**
   - Admins can add tokens to the contract's pool using `addPool`.
   - Admins can withdraw tokens from the pool using `withdrawPool`.

## Security Considerations

- Ensure that only authorized users have access to admin and keeper roles.
- Validate signatures and parameters before processing transactions.
- Regularly review and audit contract code for vulnerabilities.

## Setting up local development

### Pre-requisites

- [Node.js](https://nodejs.org/en/) version 18.0+ and [yarn](https://yarnpkg.com/) for Javascript environment.

1. Clone this repository

```bash
git clone ...
```

2. Install dependencies

```bash
yarn
```

3. Set environment variables on the .env file according to .env.example

```bash
cp .env.example .env
vim .env
```

4. Compile Solidity programs

```bash
yarn compile
```

### Development

- To run hardhat tests

```bash
yarn test
```

- To run scripts on Sepolia test

```bash
yarn script:sepolia ./scripts/....
```

- To run deploy contracts on Sepolia testnet (uses Hardhat deploy)

```bash
yarn deploy:sepolia --tags bridge
```

- To verify contracts on etherscan

```bash
yarn verify:sepolia Bridge
```

... see more useful commands in package.json file

## Main Dependencies

Contracts are developed using well-known open-source software for utility libraries and developement tools. You can read more about each of them.

[OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts)

[Hardhat](https://github.com/nomiclabs/hardhat)

[hardhat-deploy](https://github.com/wighawag/hardhat-deploy)

[ethers.js](https://github.com/ethers-io/ethers.js/)

[TypeChain](https://github.com/dethcrypto/TypeChain)
