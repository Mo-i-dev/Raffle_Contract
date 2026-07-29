//SPDX-license-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

abstract contract ConstantVariables is Script {
    /**
     * MOCKS VALUES
     */
    uint96 public constant BASE_FEE = 0.25 ether; // 0.25 is the premium in LINK
    uint96 public constant GAS_PRICE_LINK = 1e9; // link per gas
    //LINK / ETH price
    int256 public constant WEI_PER_UNIT_LINK = 1e18; // 1 LINK

    uint256 public constant ETH_SEPOLIA_CHAINID = 11155111;
    uint256 public constant ANVIL_CHAINID = 31337;
    uint256 public constant DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
}

contract HelperConfig is Script, ConstantVariables {
    error HelperConfig__NoActiveNetworkConfig();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address link;
        uint256 deployerKey;
    }
    NetworkConfig public activeNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAINID] = getSepoliaEthConfig();
        networkConfigs[ANVIL_CHAINID] = getOrCreateAnvilEthConfig();
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == ANVIL_CHAINID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__NoActiveNetworkConfig();
        }
    }

    function getActiveNetworkConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory sepoliaConfig) {
        sepoliaConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0,
            callbackGasLimit: 500000,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            deployerKey: vm.envUint("SEPOLIA_PRIVATE_KEY")
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory anvilConfig) {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }

        // Deploy the VRFCoordinatorV2_5Mock contract
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
            BASE_FEE, // base fee
            GAS_PRICE_LINK, // gas price link
            WEI_PER_UNIT_LINK // wei per unit link
        );
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();
        activeNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoordinatorMock),
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, //doese not matter for mocks
            subscriptionId: 0,
            callbackGasLimit: 500000,
            link: address(linkToken),
            deployerKey: DEFAULT_ANVIL_KEY
        });
        return activeNetworkConfig;
    }
}
