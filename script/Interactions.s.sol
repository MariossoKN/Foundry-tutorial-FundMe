// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundFundMe is Script {
    uint256 constant SEND_VALUE = 0.01 ether;

    // to use this function: forge script script/Interactions.s.sol:FundFundMe --rpc-url ... (Interactions.s.sol:FundFundMe - grabs the fundFundMe contract)

    function fundFundMe(address _mostRecenteployment) public {
        vm.startBroadcast();
        FundMe(_mostRecenteployment).fund{value: SEND_VALUE}();
        vm.stopBroadcast();
        console.log("Contract funded with %s ETH", SEND_VALUE);
    }

    function run() external {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        fundFundMe(mostRecentDeployment);
    }
}

contract WithdrawFundMe is Script {
    function withdrawFundMe(address _mostRecenteployment) public {
        uint256 contractBalance = address(FundMe(_mostRecenteployment)).balance;
        vm.startBroadcast();
        FundMe(_mostRecenteployment).cheaperWithdraw();
        vm.stopBroadcast();
        console.log("%s ETH withdrawn from contract", contractBalance);
    }

    function run() external {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        vm.startBroadcast();
        withdrawFundMe(mostRecentDeployment);
        vm.stopBroadcast();
    }
}
