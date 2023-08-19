// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {USDCToken} from "../src/USDCToken.sol";
import {Clip} from "../src/Clip.sol";
import {Vault} from "../src/Vault.sol";

contract TestClip is Test {
    Clip public clip;
    address public user1;
    address public user2;

    event Clip__WeeklyRewardsReleased();

    function setUp() public {
        clip = new Clip();
        user1 = makeAddr("user1");
    }

    function testReleaseRewards() public {
        // Create a vault
        Vault vault = new Vault(clip.usdcToken());

        vm.prank(clip.owner());
        vm.expectRevert("Time has not passed for releasing rewards!");
        clip.releaseRewards(vault);

        vm.warp(block.timestamp + clip.i_interval() + 1);
        vm.roll(block.number + 1);
        vm.expectEmit(false, false, false, false, address(clip));
        emit Clip__WeeklyRewardsReleased();
        clip.releaseRewards(vault);

        // Test for the second time pass of release rewards within interval time
        vm.expectRevert("Time has not passed for releasing rewards!");
        clip.releaseRewards(vault);

        assertEq(
            clip.usdcToken().balanceOf(address(vault)),
            clip.WEEKLY_REWARDS()
        );
    }
}
