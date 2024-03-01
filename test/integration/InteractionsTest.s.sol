// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {FundMe} from "../../src/FundMe.sol";
import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract InteractionsTest is Test {
    FundMe fundMe;
    uint256 constant NOT_ENOUGH_ETH_SENT = 1e12;
    uint256 constant ENOUGH_ETH_SENT = 5e18;
    uint256 constant STARTING_BALANCE = 20e18;
    uint256 constant SEND_VALUE = 0.01 ether;
    address USER = makeAddr("user");
    address USER2 = makeAddr("user2");
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deploy = new DeployFundMe();
        fundMe = deploy.run();
        vm.deal(USER, STARTING_BALANCE);
        // vm.deal(USER2, STARTING_BALANCE);
    }

    function testUserCanFundAndWithdrawInteractions() public {
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(address(fundMe));

        address funder = fundMe.getFunder(0);
        assertEq(fundMe.getAddressToAmountFunded(funder), SEND_VALUE);

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        assert(address(fundMe).balance == 0);
    }
}
