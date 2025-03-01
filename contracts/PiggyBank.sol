// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Erc20.sol";

error PiggyBank__TokenNotAllowed();
error PiggyBank__TransferFailed();
error PiggyBank__SavingDurationNotMet();

contract PiggyBank {
    address public owner;
    string public savingPurpose;
    uint256 public savingDuration;
    uint256 public startTime;
    address public developer;
    bool public withdrawn;

    mapping(address => uint256) public balances;
    mapping(address => bool) public allowedTokens;

    address public constant USDT = 0x...; // Replace with actual USDT address
    address public constant USDC = 0x...; // Replace with actual USDC address
    address public constant DAI = 0x...; // Replace with actual DAI address

    event Deposited(address indexed user, address indexed token, uint256 amount);
    event Withdrawn(address indexed user, address indexed token, uint256 amount);
    event EmergencyWithdraw(address indexed user, address indexed token, uint256 amount, uint256 penalty);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier isWithdrawn() {
        require(!withdrawn, "Already withdrawn");
        _;
    }

    constructor(address _developer, string memory _purpose, uint256 _duration) {
        owner = msg.sender;
        developer = _developer;
        savingPurpose = _purpose;
        savingDuration = _duration;
        startTime = block.timestamp;
        allowedTokens[USDT] = true;
        allowedTokens[USDC] = true;
        allowedTokens[DAI] = true;
    }

    function deposit(address token, uint256 amount) external isWithdrawn {
        if(!allowedTokens[token]) revert PiggyBank__TokenNotAllowed();
        if(!IERC20(token).transferFrom(msg.sender, address(this), amount)) revert PiggyBank__TransferFailed();
        balances[token] += amount;
        emit Deposited(msg.sender, token, amount);
    }

    function withdraw(address token) external onlyOwner isWithdrawn {
        require(block.timestamp >= startTime + savingDuration, "Saving duration not met");
        if(block.timestamp <= startTime + savingDuration) revert PiggyBank__SavingDurationNotMet();
        uint256 amount = balances[token];
        require(amount > 0, "No balance");
        balances[token] = 0;
        withdrawn = true;
        require(IERC20(token).transfer(owner, amount), "Transfer failed");
        emit Withdrawn(owner, token, amount);
    }

    function emergencyWithdraw(address token) external onlyOwner isWithdrawn {
        uint256 amount = balances[token];
        require(amount > 0, "No balance");
        uint256 penalty = (amount * 15) / 100;
        uint256 remaining = amount - penalty;
        balances[token] = 0;
        withdrawn = true;
        require(IERC20(token).transfer(developer, penalty), "Penalty transfer failed");
        require(IERC20(token).transfer(owner, remaining), "Transfer failed");
        emit EmergencyWithdraw(owner, token, remaining, penalty);
    }
}

