// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./PiggyBank.sol";

contract PiggyBankFactory {
    address public developer;
    address[] public allBanks;
    address public immutable piggyBankImplementation;
    
    event BankCreated(address indexed owner, address bankAddress);
    
    constructor() {
        developer = msg.sender;
        piggyBankImplementation = address(new PiggyBank());
    }
    
    function createBank(string memory _purpose, uint256 _duration, address[] memory _tokens) external returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, _purpose, block.timestamp));
        address clone = Clones.cloneDeterministic(piggyBankImplementation, salt);
        PiggyBank(payable(clone)).initialize(developer, _purpose, _duration, _tokens);
        allBanks.push(clone);
        emit BankCreated(msg.sender, clone);
        return clone;
    }
    
    function getAllBanks() external view returns (address[] memory) {
        return allBanks;
    }
}
