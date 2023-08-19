// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {USDCToken} from "./USDCToken.sol";
import {Vault} from "./Vault.sol";

contract Clip {
    address public owner;
    USDCToken public usdcToken;

    uint public constant i_interval = 604800; // 1 week
    uint public constant WEEKLY_REWARDS = 1000 ether;
    uint public constant TREASURY_AMOUNT = 5000 ether;

    event Clip__WeeklyRewardsReleased();

    constructor() {
        usdcToken = new USDCToken(TREASURY_AMOUNT);
        owner = msg.sender;
    }

    modifier onlyClipOwner() {
        if (msg.sender != owner) {
            revert("Accessed by Clip owner only.");
        }
        _;
    }

    // Releases rewards to Vault
    function releaseRewards(Vault _vault) external onlyClipOwner {
        if (block.timestamp - _vault.s_lastTimeStamp() < i_interval) {
            revert("Rewards release time not reached");
        }

        _vault.setLastTimeStampOfRewards(block.timestamp);

        usdcToken.transfer(address(_vault), WEEKLY_REWARDS);
        _vault.distributeRewards();
        emit Clip__WeeklyRewardsReleased();
    }
}
