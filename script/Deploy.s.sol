// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {AgentProjects} from "../src/credentials/AgentProjects.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Default agent registry address
        address defaultRegistry = 0xD0a769d82F6e0bf9d8913E570b6C823c8f7e9f40;
        
        // Use provided registry address or default (zero address uses default in constructor)
        address registryAddress = vm.envOr("AGENT_REGISTRY_ADDRESS", defaultRegistry);
        
        // Deploy AgentProjects with registry address (zero address uses default)
        console.log("Deploying AgentProjects...");
        console.log("Using AgentRegistry at:", registryAddress);
        AgentProjects agentProjects = new AgentProjects(registryAddress);
        console.log("AgentProjects deployed at:", address(agentProjects));
        console.log("Contract owner:", agentProjects.owner());
        console.log("AgentRegistry:", agentProjects.agentRegistry());

        // Log deployment info
        console.log("");
        console.log("=== Deployment Summary ===");
        console.log("AgentRegistry:", agentProjects.agentRegistry());
        console.log("AgentProjects:", address(agentProjects));
        console.log("Contract Owner:", agentProjects.owner());
        console.log("Chain ID:", block.chainid);

        vm.stopBroadcast();
    }
}
