// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {Vault} from "../src/Vault.sol";
import {Clip} from "../src/Clip.sol";
import {USDCToken} from "../src/USDCToken.sol";

contract TestVault is Test {
    Vault public vault;
    Clip public clip;
    USDCToken public usdcToken;
    address public user1;
    address public user2;

    uint public constant INITIAL_USER_BALANCE = 50 ether;

    event UnstakedAndRewardsTransferred(
        address indexed staker,
        uint indexed ethBalance,
        uint indexed rewardAmount
    );

    function setUp() public {
        clip = new Clip();
        usdcToken = clip.usdcToken();
        vault = new Vault(clip, usdcToken);

        user1 = makeAddr("USER1");
        user2 = makeAddr("USER2");
        vm.deal(user1, INITIAL_USER_BALANCE);
        vm.deal(user2, INITIAL_USER_BALANCE);
    }

    function testStakeTokens() public {
        vm.startPrank(user1);

        // Check if reverts for amount greater than the limit
        vm.expectRevert("Amount shouldn't exceed 20ETH");
        vault.depositEth{value: 30 ether}();

        vault.depositEth{value: 20 ether}();

        assertEq(address(vault).balance, 20 ether);
        assertEq(vault.stakingBalance(user1), 20 ether);
        vm.stopPrank();
    }

    function testunstakeTokensAndRewards() public {
        vm.startPrank(user1);
        vault.depositEth{value: 20 ether}();
        assertEq(address(user1).balance, 30 ether);
        assertEq(address(vault).balance, 20 ether);
        assertEq(vault.stakingBalance(user1), 20 ether);
        assertEq(vault.rewardAmount(user1), 0 ether);
        vm.stopPrank();

        // Release rewards from Clip
        vm.startPrank(clip.owner());
        vm.warp(block.timestamp + clip.i_interval() + 1);
        vm.roll(block.number + 1);
        clip.releaseRewards(vault);
        vm.stopPrank();

        // Check if Vault received the rewards
        assertEq(usdcToken.balanceOf(address(vault)), 1000 ether);
        assertEq(vault.rewardAmount(user1), 1000 ether);

        // User1 unstake and claims the rewards
        vm.startPrank(user1);
        vault.claimRewards();
        vm.stopPrank();

        assertEq(address(vault).balance, 0 ether);
        assertEq(vault.stakingBalance(user1), 0);
        assertEq(vault.totalStackingBalance(), 0);
        assertEq(usdcToken.balanceOf(user1), 1000 ether);
    }

    function testDistributeRewards() public {
        // User 1 deposits ETH
        vm.startPrank(user1);
        vault.depositEth{value: 20 ether}();
        vm.stopPrank();

        // User 2 deposits ETH
        vm.startPrank(user2);
        vault.depositEth{value: 20 ether}();
        vm.stopPrank();

        // User 3 deposits ETH
        address user3 = makeAddr("user3");
        vm.deal(user3, 50 ether);
        vm.startPrank(user3);
        vault.depositEth{value: 20 ether}();
        vm.stopPrank();

        // User 4 deposits ETH
        address user4 = makeAddr("user4");
        vm.deal(user4, 50 ether);
        vm.startPrank(user4);
        vault.depositEth{value: 20 ether}();
        vm.stopPrank();

        // Rewards released from Clip to Vault and distributed
        vm.startPrank(clip.owner());
        vm.warp(block.timestamp + clip.i_interval() + 1);
        vm.roll(block.number + 1);
        clip.releaseRewards(vault);
        vm.stopPrank();

        assertEq(vault.rewardAmount(user1), 250 ether);

        // User 3 withdraws
        vm.startPrank(user3);

        // Check balances before unstake
        assertEq(user3.balance, 30 ether);
        assertEq(usdcToken.balanceOf(user3), 0);

        vm.expectEmit(true, true, true, false, address(vault));
        emit UnstakedAndRewardsTransferred(user3, 20 ether, 250 ether);
        vault.claimRewards();

        // check balances after unstake
        assertEq(user3.balance, 50 ether);
        assertEq(usdcToken.balanceOf(user3), 250 ether);
        assertEq(vault.rewardAmount(user3), 0);
        assertEq(vault.stakingBalance(user3), 0);
        assertEq(vault.totalStackingBalance(), 60 ether);
    }

    function addMoreStakers(uint noOfStakers) public {
        for (uint256 i = 1; i <= noOfStakers; i++) {
            address player = address(uint160(i));
            hoax(player, 50 ether);
            vault.depositEth{value: 5 ether}();
        }
    }

    function testStakersAllowedPerWeek() public {
        addMoreStakers(20);
        assertEq(vault.totalStackingBalance(), 100 ether);

        // User 1 deposits ETH
        vm.startPrank(user1);
        vm.expectRevert("Stakers allowed per week exceeds");
        vault.depositEth{value: 20 ether}();
        vm.stopPrank();

        // Testing total staking balance after exceeding limit
        assertEq(vault.totalStackingBalance(), 100 ether);

        // Rewards released from Clip to Vault
        vm.startPrank(clip.owner());
        vm.warp(block.timestamp + clip.i_interval() + 1);
        vm.roll(block.number + 1);
        clip.releaseRewards(vault);
        vm.stopPrank();

        // stakersCountPerWeek is resetted when Rewards are distributed every week
        addMoreStakers(10);
        assertEq(vault.totalStackingBalance(), 150 ether); // Existing staking balance plus current ETH deposit of 50 ether.
    }
}
