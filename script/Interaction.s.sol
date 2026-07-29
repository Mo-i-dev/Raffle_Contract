//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, ConstantVariables} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script, ConstantVariables {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getActiveNetworkConfig().vrfCoordinator;
        uint256 deployerKey = helperConfig.getActiveNetworkConfig().deployerKey;
        (uint256 subId,) = createSubscription(vrfCoordinator,deployerKey);
        return (subId, vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator,uint256 deployerKey) public returns (uint256, address) {
        console.log("Create Subscription on chain Id:", block.chainid);
        vm.startBroadcast(deployerKey);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your subscription Id is:", subId);
        return (subId, vrfCoordinator);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, ConstantVariables {
    uint256 public constant FUND_AMOUNT = 3 ether; // 3 link

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getActiveNetworkConfig().vrfCoordinator;
        uint256 subId = helperConfig.getActiveNetworkConfig().subscriptionId;
        address linkToken = helperConfig.getActiveNetworkConfig().link;
        uint256 deployerKey = helperConfig.getActiveNetworkConfig().deployerKey;
        fundSubscription(vrfCoordinator, subId, linkToken,deployerKey);
    }

    function fundSubscription(address vrfCoordinator, uint256 subId, address linkToken,uint256 deployerKey) public {
        console.log("Funding Subscription: ", subId);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("on ChainId:", block.chainid);
        if (block.chainid == ANVIL_CHAINID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subId, FUND_AMOUNT * 100);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(deployerKey);
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentDeployedContract) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getActiveNetworkConfig().vrfCoordinator;
        uint256 subId = helperConfig.getActiveNetworkConfig().subscriptionId;
        uint256 deployerKey = helperConfig.getActiveNetworkConfig().deployerKey;
        addConsumer(subId, vrfCoordinator, mostRecentDeployedContract,deployerKey);
    }

    function addConsumer(uint256 subId, address vrfCoordinator, address consumer,uint256 deployerKey) public {
        console.log("Adding Consumer contract:", consumer);
        console.log("To vrfCoordinator:", vrfCoordinator);
        console.log("On ChainId:", block.chainid);
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, consumer);
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentDeployedContract = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentDeployedContract);
    }
}
