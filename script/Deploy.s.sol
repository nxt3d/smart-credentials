// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {AgentProjects} from "../src/credentials/AgentProjects.sol";
import {AgentProjectsFactory} from "../src/credentials/AgentProjectsFactory.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Default agent registry address
        address defaultRegistry = 0xD0a769d82F6e0bf9d8913E570b6C823c8f7e9f40;
        
        // Use provided registry address or default (zero address uses default in constructor)
        address registryAddress = vm.envOr("AGENT_REGISTRY_ADDRESS", defaultRegistry);
        
        // Deploy implementation contract
        console.log("Deploying AgentProjects implementation...");
        console.log("Using AgentRegistry at:", registryAddress);
        AgentProjects implementation = new AgentProjects(registryAddress);
        console.log("Implementation deployed at:", address(implementation));

        // Deploy factory
        console.log("");
        console.log("Deploying AgentProjectsFactory...");
        AgentProjectsFactory factory = new AgentProjectsFactory(address(implementation));
        console.log("Factory deployed at:", address(factory));

        // Optionally create a clone
        bool createClone = vm.envOr("CREATE_CLONE", false);
        address clone;
        if (createClone) {
            string memory cloneName = vm.envOr("CLONE_NAME", string("Default Agent Projects"));
            console.log("");
            console.log("Creating clone instance...");
            console.log("Clone name:", cloneName);
            clone = factory.createAgentProjects(registryAddress, cloneName);
            console.log("Clone deployed at:", clone);
            console.log("Clone owner:", AgentProjects(clone).owner());
        }

        // Log deployment info
        console.log("");
        console.log("=== Deployment Summary ===");
        console.log("AgentRegistry:", registryAddress);
        console.log("Implementation:", address(implementation));
        console.log("Factory:", address(factory));
        if (createClone) {
            console.log("Clone:", clone);
            console.log("Clone Owner:", AgentProjects(clone).owner());
        }
        console.log("Chain ID:", block.chainid);

        vm.stopBroadcast();
    }
}
