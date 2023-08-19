// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {USDCToken} from "./USDCToken.sol";

contract Vault {
    USDCToken public usdcToken;

    address[] public stakers;
    uint public totalStackingBalance;
    mapping(address => uint) public stakingBalance;
    mapping(address => uint) public rewardAmount;
    mapping(address => bool) public hasStaked;

    uint public s_lastTimeStamp;
    uint private stakersCountPerWeek;
    uint public constant MAX_STAKERS_PER_WEEK = 20;
    uint public constant MAX_STAKE_AMOUNT = 20 ether;

    event UnstakedAndRewardsTransferred(
        address indexed staker,
        uint indexed ethBalance,
        uint indexed rewardAmount
    );

    constructor(USDCToken _usdcToken) {
        usdcToken = _usdcToken;
        s_lastTimeStamp = block.timestamp;
        stakersCountPerWeek = 0;
    }

    function depositEth() public payable {
        if (msg.value < 0) {
            revert("amount cannot be 0");
        }
        if (msg.value > MAX_STAKE_AMOUNT) {
            revert("Amount should be less than or equal to 20 ether");
        }
        if (stakersCountPerWeek >= MAX_STAKERS_PER_WEEK) {
            revert("Stakers allowed per week exceeds");
        }

        stakingBalance[msg.sender] = stakingBalance[msg.sender] + msg.value;
        totalStackingBalance += msg.value;

        if (!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        hasStaked[msg.sender] = true;
        stakersCountPerWeek += 1;
    }

    // Unstaking Tokens (Withdraw)
    function claimRewards() public payable {
        // Fetch staking balance
        uint balance = stakingBalance[msg.sender];
        uint rewardAmountOfSender = rewardAmount[msg.sender];

        if (balance <= 0) {
            revert("No Staking balance available for the user");
        }

        stakingBalance[msg.sender] = 0;
        rewardAmount[msg.sender] = 0;
        totalStackingBalance -= balance;

        hasStaked[msg.sender] = false;

        payable(msg.sender).transfer(balance);
        usdcToken.transfer(msg.sender, rewardAmountOfSender);
        emit UnstakedAndRewardsTransferred(
            msg.sender,
            balance,
            rewardAmountOfSender
        );
    }

    function distributeRewards() public {
        uint totalRewardsAvailable = usdcToken.balanceOf(address(this));
        uint noOfStakers = stakers.length;

        for (uint i = 0; i < noOfStakers; i += 1) {
            uint amount = stakingBalance[stakers[i]];
            uint weightage = (amount * totalRewardsAvailable) /
                totalStackingBalance;
            rewardAmount[stakers[i]] += weightage;
        }

        // Reset Stakers entry per week
        stakersCountPerWeek = 0;
    }

    function setLastTimeStampOfRewards(uint _timestamp) public {
        s_lastTimeStamp = _timestamp;
    }
}
