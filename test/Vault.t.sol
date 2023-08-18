// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {DeployVault} from "../script/DeployVault.s.sol";
import {ETHToken} from "../src/ETHToken.sol";
import {USDCToken} from "../src/USDCToken.sol";
import {Vault} from "../src/Vault.sol";

contract TestVault is Test {
    Vault public vault;
    address public user1;
    address public user2;
    uint public constant INITIAL_USER_BALANCE = 50 ether;
    ETHToken public ethToken;
    USDCToken public usdcToken;

    function setUp() public {
        DeployVault deployer = new DeployVault();
        vault = deployer.run();

        user1 = makeAddr("USER1");
        user2 = makeAddr("USER2");

        usdcToken = vault.getUsdcToken();
        ethToken = vault.getEthToken();
        ethToken.mint(user1, 50 ether);
        ethToken.mint(user2, 50 ether);

        usdcToken.mint(user1, 3000 ether);
    }

    function testStakeTokens() public {
        vm.startPrank(user1);
        assertEq(vault.getEthBalanceOf(user1), 50 ether);

        ethToken.approve(address(vault), 20 ether);

        vm.expectRevert("Amount should be less than or equal to 20 ether");
        vault.depositEth(30 ether);

        vault.depositEth(20 ether);

        assertEq(vault.getVaultETHBalance(), 20 ether);
        assertEq(vault.getStakingBalanceOf(user1), 20 ether);
        assertEq(vault.getEthBalanceOf(user1), 30 ether);
        vm.stopPrank();
    }

    function testunstakeTokens() public {
        vm.startPrank(user1);

        ethToken.approve(address(vault), 20 ether);
        vault.depositEth(20 ether);

        assertEq(vault.getStakingBalanceOf(user1), 20 ether);

        vault.claimRewards();
        assertEq(vault.getVaultETHBalance(), 0 ether);
        assertEq(vault.getStakingBalanceOf(user1), 0 ether);
        assertEq(ethToken.balanceOf(user1), 50 ether);
        vm.stopPrank();
    }

    function testDistributeRewards() public {
        // Assuming that USDC is transferred from Clip to Vault
        vm.startPrank(user1);
        usdcToken.transfer(address(vault), 1000 ether);
        vm.stopPrank();

        // User 1 deposits ETH
        vm.startPrank(user1);
        ethToken.approve(address(vault), 20 ether);
        vault.depositEth(20 ether);
        vm.stopPrank();

        // User 2 deposits ETH
        vm.startPrank(user2);
        ethToken.approve(address(vault), 20 ether);
        vault.depositEth(20 ether);
        vm.stopPrank();

        // User 3 deposits ETH
        address user3 = makeAddr("user3");
        ethToken.mint(user3, 50 ether);
        vm.startPrank(user3);
        ethToken.approve(address(vault), 20 ether);
        vault.depositEth(20 ether);
        vm.stopPrank();

        // User 4 deposits ETH
        address user4 = makeAddr("user4");
        ethToken.mint(user4, 50 ether);
        vm.startPrank(user4);
        ethToken.approve(address(vault), 20 ether);
        vault.depositEth(20 ether);
        vm.stopPrank();

        vm.startPrank(address(vault));
        vault.distributeRewards();

        assertEq(vault.getRewardAmountOf(user1), 250 ether);
        vm.stopPrank();

        // User 3 withdraws
        vm.startPrank(user3);

        // Check balances before unstake
        assertEq(vault.getEthBalanceOf(user3), 30 ether);
        assertEq(vault.getUsdcBalanceOf(user3), 0);

        vault.claimRewards();

        // check balances after unstake
        assertEq(vault.getEthBalanceOf(user3), 50 ether);
        assertEq(vault.getUsdcBalanceOf(user3), 250 ether);
        assertEq(vault.getRewardAmountOf(user3), 0);
        assertEq(vault.getStakingBalanceOf(user3), 0);
        assertEq(vault.getTotalStakingBalance(), 60 ether);

        // Test
        // assertEq(vault.getUsdcBalanceOf(address(vault)), 1000 ether);
    }

    function addMoreStakers(uint noOfStakers) public {
        for (uint256 i = 1; i <= noOfStakers; i++) {
            address player = address(uint160(i));
            ethToken.mint(player, 5 ether);
            vm.startPrank(player);
            ethToken.approve(address(vault), 5 ether);
            vault.depositEth(5 ether);
            vm.stopPrank();
        }
    }

    function testStakersAllowedPerWeek() public {
        addMoreStakers(20);
        assertEq(vault.getTotalStakingBalance(), 100 ether);

        // User 1 deposits ETH
        vm.startPrank(user1);
        ethToken.approve(address(vault), 20 ether);
        vm.expectRevert("Stakers allowed per week exceeds");
        vault.depositEth(20 ether);
        vm.stopPrank();

        // Testing total staking balance after exceeding limit
        assertEq(vault.getTotalStakingBalance(), 100 ether);

        // Assuming that USDC is transferred from Clip to Vault
        vm.startPrank(user1);
        usdcToken.transfer(address(vault), 1000 ether);
        vm.stopPrank();

        // stakersCountPerWeek is resetted when Rewards are distributed every week
        vault.distributeRewards();
        addMoreStakers(10);
        assertEq(vault.getTotalStakingBalance(), 150 ether); // Existing staking balance plus current ETH deposit of 50 ether.

        // deposithEth when the vault is in Calculating state
        vm.startPrank(user1);
        ethToken.approve(address(vault), 20 ether);
        vault.setVaultState(1);
        vm.expectRevert("Vault is currently closed!!");
        vault.depositEth(20 ether);
        vm.stopPrank();
    }
}
