// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract USDCToken is ERC20 {
    constructor(uint initialSupply) ERC20("USDC Token", "USDC") {
        _mint(msg.sender, initialSupply);
    }
}
