// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ETHToken} from "./ETHToken.sol";
import {USDCToken} from "./USDCToken.sol";

contract Vault {
    string public name = "Vault";
    address public owner;
    ETHToken public ethToken;
    USDCToken public usdcToken;

    enum VaultState {
        OPEN,
        CALCULATING
    }

    address[] public stakers;
    uint public totalStackingBalance;
    mapping(address => uint) public stakingBalance;
    mapping(address => uint) public rewardAmount;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;
    uint public immutable stakeInterval = 604800; // 1 week
    uint private s_lastTimeStamp;
    uint private stakersCountPerWeek;
    uint public constant MAX_STAKERS_PER_WEEK = 20;
    uint public constant MAX_STAKE_AMOUNT = 20 ether;
    VaultState public s_vaultState;

    constructor(ETHToken _ethToken, USDCToken _usdcToken) {
        ethToken = _ethToken;
        usdcToken = _usdcToken;
        s_lastTimeStamp = block.timestamp;
        s_vaultState = VaultState.OPEN;
        stakersCountPerWeek = 0;
    }

    function depositEth(uint _amount) public {
        require(s_vaultState == VaultState.OPEN, "Vault is currently closed!!");
        require(_amount > 0, "amount cannot be 0");
        require(
            _amount <= MAX_STAKE_AMOUNT,
            "Amount should be less than or equal to 20 ether"
        );

        if (stakersCountPerWeek == MAX_STAKERS_PER_WEEK) {
            revert("Stakers allowed per week exceeds");
        }

        // Trasnfer ETH tokens to this contract for staking
        ethToken.transferFrom(msg.sender, address(this), _amount);

        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;
        totalStackingBalance += _amount;

        if (!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;
        stakersCountPerWeek += 1;
    }

    // Unstaking Tokens (Withdraw)
    function claimRewards() public {
        // Fetch staking balance
        uint balance = stakingBalance[msg.sender];
        uint rewardAmountOfSender = rewardAmount[msg.sender];

        require(balance > 0, "No Staking balance available for the user");

        ethToken.transfer(msg.sender, balance);
        usdcToken.transfer(msg.sender, rewardAmountOfSender);

        stakingBalance[msg.sender] = 0;
        rewardAmount[msg.sender] = 0;
        totalStackingBalance -= balance;

        isStaking[msg.sender] = false;
    }

    function distributeRewards() public {
        s_vaultState = VaultState.CALCULATING;
        uint totalRewardsAvailable = usdcToken.balanceOf(address(this));
        uint noOfStakers = stakers.length;

        for (uint i = 0; i < noOfStakers; i += 1) {
            uint amount = stakingBalance[stakers[i]];
            uint weightage = (amount * totalRewardsAvailable) /
                totalStackingBalance;
            rewardAmount[stakers[i]] += weightage;
        }
        s_vaultState = VaultState.OPEN;

        // Reset Stakers entry per week
        stakersCountPerWeek = 0;
    }

    function setVaultState(uint vstate) public {
        s_vaultState = VaultState(vstate);
    }

    function getRewardAmountOf(address user) public view returns (uint) {
        return rewardAmount[user];
    }

    function getVaultETHBalance() public view returns (uint) {
        return ethToken.balanceOf(address(this));
    }

    function getEthBalanceOf(address user) public view returns (uint) {
        return ethToken.balanceOf(user);
    }

    function getUsdcBalanceOf(address user) public view returns (uint) {
        return usdcToken.balanceOf(user);
    }

    function getStakingBalanceOf(address user) public view returns (uint) {
        return stakingBalance[user];
    }

    function getEthToken() public view returns (ETHToken) {
        return ethToken;
    }

    function getUsdcToken() public view returns (USDCToken) {
        return usdcToken;
    }

    function getTotalStakingBalance() public view returns (uint) {
        return totalStackingBalance;
    }
}
