// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {FundMe} from "../../src/FundMe.sol";
import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    uint256 constant NOT_ENOUGH_ETH_SENT = 1e12;
    uint256 constant ENOUGH_ETH_SENT = 5e18;
    uint256 constant STARTING_BALANCE = 20e18;
    address USER = makeAddr("user");
    address USER2 = makeAddr("user2");
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // fundMe = new FundMe(priceFeed);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
        vm.deal(USER2, STARTING_BALANCE);
    }

    function testMinUSD() public {
        uint256 minUsd = fundMe.MINIMUM_USD();
        console.log(minUsd);
        assertEq(minUsd, 5e18);
    }

    function testOwnerIsMsgSender() public {
        address owner = fundMe.getOwner();
        assertEq(owner, msg.sender);
    }

    function testIfVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    // fundMe function tests //

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: (ENOUGH_ETH_SENT)}();
        _;
    }

    function testFundFailsIfNotEnoughEthSent1() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundFailsIfNotEnoughEthSent2() public {
        vm.expectRevert();
        fundMe.fund{value: (NOT_ENOUGH_ETH_SENT)}();
    }

    function testFundUpdatesMapping() public {
        vm.prank(USER);
        fundMe.fund{value: (ENOUGH_ETH_SENT)}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, ENOUGH_ETH_SENT);

        vm.prank(USER2);
        fundMe.fund{value: (ENOUGH_ETH_SENT)}();
        uint256 amountFunded2 = fundMe.getAddressToAmountFunded(USER2);
        assertEq(amountFunded2, ENOUGH_ETH_SENT);
    }

    function testFundUpdatesArray() public {
        vm.prank(USER);
        fundMe.fund{value: (ENOUGH_ETH_SENT)}();
        assertEq(fundMe.getFunder(0), USER);

        vm.prank(USER2);
        fundMe.fund{value: (ENOUGH_ETH_SENT)}();
        assertEq(fundMe.getFunder(1), USER2);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.cheaperWithdraw();
    }

    function testWithdrawWithSingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        // Assert
        uint256 endingownerBalance = fundMe.getOwner().balance;
        uint256 endingContractBalance = address(fundMe).balance;
        assertEq(endingContractBalance, 0);
        assertEq(
            startingOwnerBalance + startingContractBalance,
            endingownerBalance
        );
    }

    function testWithdrawWithMultipleFunders1() public {
        vm.prank(USER);
        fundMe.fund{value: (ENOUGH_ETH_SENT)}();
        vm.prank(USER2);
        fundMe.fund{value: (ENOUGH_ETH_SENT)}();
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingContractBalance = address(fundMe).balance;
        assertEq(endingContractBalance, 0);
        assertEq(
            startingOwnerBalance + startingContractBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawWithMultipleFunders2() public {
        for (uint160 i = 1; i < 10; i++) {
            hoax(address(i), STARTING_BALANCE);
            fundMe.fund{value: (ENOUGH_ETH_SENT)}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;

        // default gas price on Anvil is 0
        // to set the gas price we can use the vm.txGasPrice()
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingContractBalance = address(fundMe).balance;
        assertEq(endingContractBalance, 0);
        assertEq(
            startingOwnerBalance + startingContractBalance,
            endingOwnerBalance
        );
    }
}
