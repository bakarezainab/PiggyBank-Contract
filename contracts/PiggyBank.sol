// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

error PiggyBank__AlreadyInitialized();
error PiggyBank__NotOwner();
error PiggyBank__AlreadyWithdrawn();
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
    bool private initialized;

    mapping(address => uint256) public balances;
    mapping(address => bool) public allowedTokens;

    event Deposited(address indexed user, address indexed token, uint256 amount);
    event Withdrawn(address indexed user, address indexed token, uint256 amount);
    event EmergencyWithdraw(address indexed user, address indexed token, uint256 amount, uint256 penalty);

    

    modifier onlyOwner() {  
        if (msg.sender != owner) revert PiggyBank__NotOwner();
        _;              
    }

    modifier isWithdrawn() {
        if (withdrawn) revert PiggyBank__AlreadyWithdrawn();
        _;
    }

    constructor() {}

    function initialize(address _developer, string memory _purpose, uint256 _duration, address[] memory _tokens) external {
        if (initialized) revert PiggyBank__AlreadyInitialized();
        initialized = true;
        owner = msg.sender;
        developer = _developer;
        savingPurpose = _purpose;
        savingDuration = _duration;
        startTime = block.timestamp;
        for (uint i = 0; i < _tokens.length; i++) {
            allowedTokens[_tokens[i]] = true;
        }
    }

    function deposit(address token, uint256 amount) external isWithdrawn {
        if (!allowedTokens[token]) revert PiggyBank__TokenNotAllowed();
        if (!IERC20(token).transferFrom(msg.sender, address(this), amount)) revert PiggyBank__TransferFailed();
        balances[token] += amount;
        emit Deposited(msg.sender, token, amount);
    }

    function withdraw(address token) external onlyOwner isWithdrawn {
        if (block.timestamp < startTime + savingDuration) revert PiggyBank__SavingDurationNotMet();
        uint256 amount = balances[token];
        if (amount == 0) revert PiggyBank__NoBalance();
        balances[token] = 0;
        withdrawn = true;
        if (!IERC20(token).transfer(owner, amount)) revert PiggyBank__TransferFailed();
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

