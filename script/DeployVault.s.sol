// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "../lib/forge-std/src/Script.sol";
import {ETHToken} from "../src/ETHToken.sol";
import {USDCToken} from "../src/USDCToken.sol";
import {Vault} from "../src/Vault.sol";

contract DeployVault is Script {
    Vault public vault;
    ETHToken public ethToken;
    USDCToken public usdcToken;
    uint public totalSupply = 10000;

    function run() public returns (Vault) {
        vm.startBroadcast();
        ethToken = new ETHToken(totalSupply);
        usdcToken = new USDCToken(totalSupply);
        vault = new Vault(ethToken, usdcToken);
        vm.stopBroadcast();

        return vault;
    }
}
