// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "../lib/forge-std/src/Script.sol";
import {ETHToken} from "../src/ETHToken.sol";
import {USDCToken} from "../src/USDCToken.sol";
import {Clip} from "../src/Clip.sol";

contract DeployClip is Script {
    ETHToken public ethToken;
    USDCToken public usdcToken;
    Clip public clip;
    uint public totalSupply = 10000;

    function run() public returns (Clip) {
        vm.startBroadcast();
        ethToken = new ETHToken(totalSupply);
        usdcToken = new USDCToken(totalSupply);
        clip = new Clip(usdcToken, ethToken);
        vm.stopBroadcast();

        return clip;
    }
}
