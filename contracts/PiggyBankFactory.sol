// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import './PiggyBank.sol';

contract PiggyBankFactory{
    struct PiggyDetails {
        address piggyAddress;
        string purpose;
    }

    uint256 public piggiesCount;
    address public devAddress;
    mapping(address => PiggyDetails[]) userPiggies;

    error noPiggyForUser();
    error noActivePiggy();
    error piggyCreationFailed();

    event PiggyCreated(address indexed _owner, address indexed _piggyAddress, string _purpose);

    constructor(){
        devAddress = msg.sender;
    }
    
    function createPiggy(string memory purpose, uint8 durationInMonth) external returns(address piggyAddress){

        bytes memory _bytecode = getByteCode(durationInMonth, purpose);
        uint256 _newPiggiesCount = piggiesCount + 1;
    
        assembly {
            piggyAddress := create2(0, add(_bytecode, 32), mload(_bytecode), _newPiggiesCount)
        }

        if(piggyAddress == address(0)) revert piggyCreationFailed();
        PiggyDetails memory _newPiggyDetails = PiggyDetails(
            piggyAddress,
            purpose
        );
        piggiesCount = _newPiggiesCount;

        userPiggies[msg.sender].push(_newPiggyDetails);
        emit PiggyCreated(msg.sender, piggyAddress, purpose);
    }

    function getByteCode(uint8 durationInMonth, string memory purpose) private view returns(bytes memory){

        bytes memory _bytecode = abi.encodePacked(type(PiggyBank).creationCode, abi.encode(msg.sender, durationInMonth, purpose, devAddress));
        return _bytecode;
    }

    function retrieveAllUserPiggies(address _user) external view returns(PiggyDetails[] memory) {
        if(userPiggies[_user].length == 0) revert noPiggyForUser();

        return userPiggies[_user];
    }

    function retriveUserActivePiggies(address _user) external view returns(PiggyDetails[] memory) {
        if(userPiggies[_user].length == 0) revert noPiggyForUser();

        PiggyDetails[] memory _allPiggies = userPiggies[_user];
        uint256 activeCount = 0;
        for (uint32 i = 0 ; i < _allPiggies.length; i++){
            if(!PiggyBank(_allPiggies[i].piggyAddress).isWithdrawn()){
                activeCount++;
            }
        }

        if (activeCount == 0) revert noActivePiggy();

        PiggyDetails[] memory activePiggies = new PiggyDetails[](activeCount);
        uint256 index = 0;
        for (uint32 i = 0 ; i < _allPiggies.length; i++){
            if(!PiggyBank(_allPiggies[i].piggyAddress).isWithdrawn()){
                activePiggies[index] = _allPiggies[i];
                index++;
            }
        }
        return activePiggies;
    }
}