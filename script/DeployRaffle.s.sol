//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interaction.s.sol";

contract DeployRaffle is Script {
    function run() public {
        deployRaffle();
    }

    /// @dev Deploys the Raffle contract
    function deployRaffle() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        // local -> deploy mocks get local config
        // Sepolia -> use the real contract address from the helper config
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getActiveNetworkConfig();
        if (networkConfig.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (networkConfig.subscriptionId, networkConfig.vrfCoordinator) =
                createSubscription.createSubscription(networkConfig.vrfCoordinator, networkConfig.deployerKey);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                networkConfig.vrfCoordinator,
                networkConfig.subscriptionId,
                networkConfig.link,
                networkConfig.deployerKey
            );
        }

        vm.startBroadcast(networkConfig.deployerKey);
        Raffle raffle = new Raffle(
            networkConfig.entranceFee,
            networkConfig.interval,
            networkConfig.vrfCoordinator,
            networkConfig.gasLane,
            networkConfig.subscriptionId,
            networkConfig.callbackGasLimit
        );
        vm.stopBroadcast();
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            networkConfig.subscriptionId, networkConfig.vrfCoordinator, address(raffle), networkConfig.deployerKey
        );
        return (raffle, helperConfig);
    }
}
