// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../../script/Interaction.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {ConstantVariables} from "script/HelperConfig.s.sol";

contract InteractionsTest is Test, ConstantVariables {
    Raffle public raffle;
    HelperConfig public helperConfig;

    function setUp() external {
        helperConfig = new HelperConfig();
    }

    function testDeployRaffleScript() public {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployRaffle();

        assertTrue(address(raffle) != address(0));

        assertEq(uint256(raffle.getRaffleState()), 0);
    }

    function testCreateFundAndAddConsumerWork() public {
        HelperConfig.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();

        if (block.chainid != ANVIL_CHAINID) {
            return;
        }

        CreateSubscription createSub = new CreateSubscription();

        (uint256 subId,) = createSub.createSubscription(config.vrfCoordinator, config.deployerKey);

        assertTrue(subId != 0);

        FundSubscription fundSub = new FundSubscription();

        fundSub.fundSubscription(config.vrfCoordinator, subId, config.link, config.deployerKey);

        (uint96 balance,,,,) = VRFCoordinatorV2_5Mock(config.vrfCoordinator).getSubscription(subId);
        assertTrue(balance > 0);

        DeployRaffle deployer = new DeployRaffle();
        (raffle,) = deployer.deployRaffle();

        AddConsumer addConsumer = new AddConsumer();

        addConsumer.addConsumer(subId, config.vrfCoordinator, address(raffle), config.deployerKey);

        bool isAdded = VRFCoordinatorV2_5Mock(config.vrfCoordinator).consumerIsAdded(subId, address(raffle));
        assertTrue(isAdded);
    }
}
