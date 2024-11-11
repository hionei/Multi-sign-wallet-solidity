// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBEP20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
}

contract MultiSigWallet {
  address[] public owners;
  mapping(address => bool) public isOwner;
  uint public required;

  struct Transaction {
    address token; // BEP-20 token contract address (address(0) for BNB)
    address to; // Recipient address
    uint256 value; // Amount to transfer
    bool executed; // Status of execution
    uint256 numApprovals; // Number of approvals received
  }

  mapping(uint => mapping(address => bool)) public approvals;
  Transaction[] public transactions;

  modifier onlyOwner() {
    require(isOwner[msg.sender], "Not an owner");
    _;
  }

  modifier txExists(uint _txId) {
    require(_txId < transactions.length, "Transaction does not exist");
    _;
  }

  modifier notExecuted(uint _txId) {
    require(!transactions[_txId].executed, "Transaction already executed");
    _;
  }

  modifier notApproved(uint _txId) {
    require(!approvals[_txId][msg.sender], "Transaction already approved");
    _;
  }

  constructor(address[] memory _owners, uint _required) {
    require(_owners.length > 0, "Owners required");
    require(_required > 0 && _required <= _owners.length, "Invalid number of required approvals");

    for (uint i = 0; i < _owners.length; i++) {
      address owner = _owners[i];
      require(owner != address(0), "Invalid owner");
      require(!isOwner[owner], "Owner not unique");

      isOwner[owner] = true;
      owners.push(owner);
    }

    required = _required;
  }

  receive() external payable {} // Allows the contract to receive BNB

  function submitTransaction(address _token, address _to, uint256 _value) public onlyOwner {
    transactions.push(
      Transaction({token: _token, to: _to, value: _value, executed: false, numApprovals: 0})
    );
  }

  function approveTransaction(
    uint _txId
  ) public onlyOwner txExists(_txId) notExecuted(_txId) notApproved(_txId) {
    approvals[_txId][msg.sender] = true;
    transactions[_txId].numApprovals += 1;
  }

  function executeTransaction(uint _txId) public onlyOwner txExists(_txId) notExecuted(_txId) {
    Transaction storage transaction = transactions[_txId];
    require(transaction.numApprovals >= required, "Cannot execute transaction");

    transaction.executed = true;

    if (transaction.token == address(0)) {
      // Transfer BNB
      (bool success, ) = transaction.to.call{value: transaction.value}("");
      require(success, "BNB transfer failed");
    } else {
      // Transfer BEP-20 token
      IBEP20 token = IBEP20(transaction.token);
      require(token.transfer(transaction.to, transaction.value), "Token transfer failed");
    }
  }

  function getTransaction(
    uint _txId
  )
    public
    view
    returns (address token, address to, uint256 value, bool executed, uint256 numApprovals)
  {
    Transaction storage transaction = transactions[_txId];
    return (
      transaction.token,
      transaction.to,
      transaction.value,
      transaction.executed,
      transaction.numApprovals
    );
  }

  function getOwners() public view returns (address[] memory) {
    return owners;
  }

  function getTransactionCount() public view returns (uint) {
    return transactions.length;
  }

  function getApprovals(uint _txId) public view returns (uint256) {
    return transactions[_txId].numApprovals;
  }
}
