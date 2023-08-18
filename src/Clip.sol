// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ETHToken} from "./ETHToken.sol";
import {USDCToken} from "./USDCToken.sol";
import {Vault} from "./Vault.sol";

contract Clip {
    string public name = "Clip Token Farm";
    address public owner;
    USDCToken public usdcToken;
    ETHToken public ethToken;
    Vault public vault;

    uint public s_lastTimeStamp;
    uint private i_interval = 604800; // 1 week
    uint private weekly_rewards = 1000 ether;

    event Clip__WeeklyRewardsReleased();

    constructor(USDCToken _usdcToken, ETHToken _ethToken) {
        usdcToken = _usdcToken;
        ethToken = _ethToken;
        owner = msg.sender;
        s_lastTimeStamp = block.timestamp;
        vault = new Vault(_ethToken, _usdcToken);
    }

    modifier onlyClipOwner() {
        require(msg.sender == owner, "Only Clip owner can call this function.");
        _;
    }

    // Releases rewards to Vault
    // Can be configured using Chainlink Keepers - time based trigger
    function releaseRewards() public onlyClipOwner {
        require(
            (block.timestamp - s_lastTimeStamp) > i_interval,
            "Time has not passed for releasing rewards!"
        );

        usdcToken.transfer(address(vault), weekly_rewards);

        emit Clip__WeeklyRewardsReleased();
    }

    function getVault() public view returns (Vault) {
        return vault;
    }

    function getClipETHBalance() public view returns (uint) {
        return ethToken.balanceOf(address(this));
    }

    function getClipUSDCBalance() public view returns (uint) {
        return usdcToken.balanceOf(address(this));
    }

    function getEthToken() public view returns (ETHToken) {
        return ethToken;
    }

    function getUsdcToken() public view returns (USDCToken) {
        return usdcToken;
    }

    function getClipOwner() public view returns (address) {
        return owner;
    }

    function getInterval() public view returns (uint) {
        return i_interval;
    }
}
