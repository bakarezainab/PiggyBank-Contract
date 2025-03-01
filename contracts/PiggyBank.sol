// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import './Erc20.sol';


    error notOwner();
    error Withdrawn();
    error InvalidToken();
    error InvalidAmount();
    error DepositFailed();
    error WithdrawalTimeNotMet();
    error LockPeriodOver();

contract PiggyBank{
    address public owner;
    address private devAddress;    
    uint256 public usdtBalance;
    uint256 public daiBalance;
    uint256 public usdcBalance;
    uint256 public withdrawalTime;
    uint8 public lockPeriodInMonths;
    string public purpose;
    bool public isWithdrawn;
    uint32 private constant ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60;
    uint8 public constant PENALTY_FEE_IN_PERCENTAGE = 15;
    

    enum Token{
        DAI,
        USDC,
        USDT
    }
    mapping(Token => address) tokenAddresses;

    

    event Deposit(address indexed _owner, uint256 _amount, Token _token);
    event Withdraw(address indexed _owner, uint256 _amount, Token _token);

    constructor(address _owner, uint8 _lockPeriodInMonths, string memory _purpose, address _devAddress){
        devAddress = _devAddress;
        owner = _owner;
        lockPeriodInMonths = _lockPeriodInMonths;
        purpose = _purpose;
        withdrawalTime = block.timestamp + (lockPeriodInMonths * ONE_MONTH_IN_SECS);   
        
        tokenAddresses[Token.USDT] = 0x5b96F73A38c71F13370Dc90cB3f907CE67118b2c;
        tokenAddresses[Token.USDC] = 0x36Df5ed4f477D8e54954187a9830b39898aaa099;
        tokenAddresses[Token.DAI] = 0xC68b181519dcC8e4Bb11c6C4829Ba46E1F897CF7;
    }

    modifier onlyOwner {
        if(msg.sender != owner) revert notOwner();
        _;
    }

    modifier checkWithdraw(){
        if(isWithdrawn) revert Withdrawn();
        _;
    }

    function deposit(uint256 _amount, Token _token) external onlyOwner checkWithdraw{
        if(tokenAddresses[_token] == address(0)) revert InvalidToken();
        if(_amount < 0) revert InvalidAmount();


        Erc20 token = Erc20(tokenAddresses[_token]);
        bool success = token.transferFrom(msg.sender, address(this), _amount);
        if(!success) revert DepositFailed();

        if(_token == Token.DAI){
            daiBalance += _amount;
        }else if(_token == Token.USDC){
            usdcBalance += _amount;
        }else if(_token == Token.USDT){
            usdtBalance += _amount;
        }
        emit Deposit(owner, _amount, _token);
    }
    

    function withdraw() external onlyOwner checkWithdraw{
        if(block.timestamp < withdrawalTime) revert WithdrawalTimeNotMet();
        isWithdrawn = true;
        Erc20 dai = Erc20(tokenAddresses[Token.DAI]);
        Erc20 usdc = Erc20(tokenAddresses[Token.USDC]);
        Erc20 usdt = Erc20(tokenAddresses[Token.USDT]);
        if(daiBalance > 0){
            dai.transfer(owner, daiBalance);
            emit Withdraw(owner, daiBalance, Token.DAI);
        }
        if(usdcBalance > 0){
            usdc.transfer(owner, usdcBalance);
            emit Withdraw(owner, usdcBalance, Token.USDC);
        }
        if(usdtBalance > 0){
            usdt.transfer(owner, usdtBalance);
            emit Withdraw(owner, usdtBalance, Token.USDT);
        }

    }

    function emergencyWithraw() external onlyOwner checkWithdraw{
        if(block.timestamp > withdrawalTime) revert LockPeriodOver();
        isWithdrawn = true;
        Erc20 dai = Erc20(tokenAddresses[Token.DAI]);
        Erc20 usdc = Erc20(tokenAddresses[Token.USDC]);
        Erc20 usdt = Erc20(tokenAddresses[Token.USDT]);
        if(daiBalance > 0){
            dai.transfer(owner, daiBalance - calculatePenalty(daiBalance));
            dai.transfer(devAddress, calculatePenalty(daiBalance));
            emit Withdraw(owner, daiBalance - calculatePenalty(daiBalance), Token.DAI);
        }
        if(usdcBalance > 0){
            usdc.transfer(owner, usdcBalance - calculatePenalty(usdcBalance));
            usdc.transfer(devAddress, calculatePenalty(usdcBalance));
            emit Withdraw(owner, usdcBalance - calculatePenalty(usdcBalance), Token.USDC);
        }
        if(usdtBalance > 0){
            usdt.transfer(owner, usdtBalance - calculatePenalty(usdtBalance));
            usdt.transfer(devAddress, calculatePenalty(usdtBalance));
            emit Withdraw(owner, usdtBalance - calculatePenalty(usdtBalance), Token.USDT);
        }
    }
    function calculatePenalty(uint256 _amount) internal pure returns(uint256){
        return (_amount * PENALTY_FEE_IN_PERCENTAGE) / 100;
    }
    
    function checkDaiBalance() external view onlyOwner returns(uint256){
        return daiBalance;
    }   

    function checkUsdcBalance() external view onlyOwner returns(uint256){
        return usdcBalance;
    }

    function checkUsdtBalance() external view onlyOwner returns(uint256){
        return usdtBalance;
    }

    function checkWithdrawalTime() external view onlyOwner returns(uint256){
        return withdrawalTime;
    }

    
}