// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {DeployClip} from "../script/DeployClip.s.sol";
import {ETHToken} from "../src/ETHToken.sol";
import {USDCToken} from "../src/USDCToken.sol";
import {Clip} from "../src/Clip.sol";

contract TestClip is Test {
    Clip public clip;
    address public user1;
    address public user2;
    uint public constant INITIAL_USER_BALANCE = 50 ether;

    event Clip__WeeklyRewardsReleased();

    function setUp() public {
        DeployClip deployer = new DeployClip();
        clip = deployer.run();

        user1 = makeAddr("USER1");
        user2 = makeAddr("USER2");

        vm.deal(user1, INITIAL_USER_BALANCE);
        vm.deal(user2, INITIAL_USER_BALANCE);

        clip.getEthToken().mint(user1, 50 ether);
        clip.getEthToken().mint(user2, 50 ether);
    }

    function testReleaseRewardsToVault() public {
        vm.startPrank(clip.getClipOwner());

        // Sending USDC to Clip for releasing rewards
        clip.getUsdcToken().transfer(address(clip), 5000 ether);

        vm.warp(block.timestamp + clip.getInterval() + 1);
        vm.roll(block.number + 1);
        assertEq(clip.getClipUSDCBalance(), 5000 ether);
        assertEq(
            clip.getUsdcToken().balanceOf(clip.getClipOwner()),
            5000 ether
        );

        // Testing if USDC is transferred to Vault
        vm.expectEmit(false, false, false, false, address(clip));
        emit Clip__WeeklyRewardsReleased();
        clip.releaseRewards();
        assertEq(
            clip.getUsdcToken().balanceOf(address(clip.getVault())),
            1000 ether
        );
    }
}
