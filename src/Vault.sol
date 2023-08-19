// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Clip} from "./Clip.sol";
import {USDCToken} from "./USDCToken.sol";

contract Vault {
    Clip private immutable clip;
    USDCToken private immutable usdcToken;
    address private immutable owner;

    address[] private stakers;
    uint public totalStackingBalance;
    mapping(address => uint) public stakingBalance;
    mapping(address => uint) public rewardAmount;
    mapping(address => bool) private hasStaked;

    uint public s_lastTimeStamp;
    uint private stakersCountPerWeek;
    uint constant MAX_STAKERS_PER_WEEK = 20;
    uint constant MAX_STAKE_AMOUNT = 20 ether;

    event UnstakedAndRewardsTransferred(
        address indexed staker,
        uint indexed ethBalance,
        uint indexed rewardAmount
    );

    // event Logging(address addr);

    // modifier onlyClipOrVaultOwner() {
    //     emit Logging(msg.sender);
    //     emit Logging(owner);
    //     emit Logging(address(Clip(msg.sender).owner()));

    //     require(
    //         msg.sender == owner || msg.sender == clip.owner(),
    //         "Not authorized"
    //     );
    //     _;
    // }

    constructor(Clip _clip, USDCToken _usdcToken) {
        clip = _clip;
        usdcToken = _usdcToken;
        s_lastTimeStamp = block.timestamp;
        stakersCountPerWeek = 0;
        owner = msg.sender;
    }

    function depositEth() external payable {
        if (msg.value < 0) {
            revert("Amount cannot be 0"); // 18
        }
        if (msg.value > MAX_STAKE_AMOUNT) {
            revert("Amount shouldn't exceed 20ETH");
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
    function claimRewards() external payable {
        // Fetch staking balance
        uint balance = stakingBalance[msg.sender];
        uint rewardAmountOfSender = rewardAmount[msg.sender];

        if (balance <= 0) {
            revert("No Staking balance available.");
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

    function distributeRewards() external {
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

    function setLastTimeStampOfRewards(uint _timestamp) external {
        s_lastTimeStamp = _timestamp;
    }
}
