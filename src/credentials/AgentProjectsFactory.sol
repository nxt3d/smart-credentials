// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {AgentProjects} from "./AgentProjects.sol";
import {IERC8049} from "../interfaces/IERC8049.sol";

/**
 * @title AgentProjectsFactory
 * @author @nxt3d
 * @notice Minimal clones factory for deploying AgentProjects instances
 * @dev Uses ERC-1167 minimal proxy pattern for gas-efficient deployments.
 *      Each clone can have its own name set via ERC-8049 contract metadata.
 */
contract AgentProjectsFactory {
    using Clones for address;

    /* --- Events --- */

    /// @notice Emitted when a new AgentProjects clone is created
    /// @param clone The address of the newly created clone
    /// @param agentRegistry The agent registry address used for the clone
    /// @param name The name of the credential instance
    /// @param owner The owner of the clone
    event AgentProjectsCreated(
        address indexed clone,
        address indexed agentRegistry,
        string name,
        address indexed owner
    );

    /* --- State Variables --- */

    /// @notice The implementation contract address
    address public immutable implementation;

    /// @notice Array of all deployed clones
    address[] public clones;

    /// @notice Mapping from owner to their clones
    mapping(address owner => address[] clones) public ownerClones;

    /* --- Constructor --- */

    /// @notice Deploy the factory with an implementation contract
    /// @param _implementation The AgentProjects implementation address
    constructor(address _implementation) {
        implementation = _implementation;
    }

    /* --- Factory Functions --- */

    /// @notice Create a new AgentProjects clone
    /// @param agentRegistry The agent registry address (zero address uses default)
    /// @param name The name for this credential instance
    /// @return clone The address of the newly created clone
    function createAgentProjects(
        address agentRegistry,
        string calldata name
    ) external returns (address clone) {
        // Deploy minimal proxy
        clone = implementation.clone();

        // Initialize the clone
        AgentProjects(clone).initialize(agentRegistry, msg.sender, name);

        // Track the clone
        clones.push(clone);
        ownerClones[msg.sender].push(clone);

        emit AgentProjectsCreated(clone, agentRegistry, name, msg.sender);

        return clone;
    }

    /// @notice Create a new AgentProjects clone with deterministic address
    /// @param agentRegistry The agent registry address (zero address uses default)
    /// @param name The name for this credential instance
    /// @param salt The salt for deterministic deployment
    /// @return clone The address of the newly created clone
    function createAgentProjectsDeterministic(
        address agentRegistry,
        string calldata name,
        bytes32 salt
    ) external returns (address clone) {
        // Deploy minimal proxy with deterministic address
        clone = implementation.cloneDeterministic(salt);

        // Initialize the clone
        AgentProjects(clone).initialize(agentRegistry, msg.sender, name);

        // Track the clone
        clones.push(clone);
        ownerClones[msg.sender].push(clone);

        emit AgentProjectsCreated(clone, agentRegistry, name, msg.sender);

        return clone;
    }

    /// @notice Predict the address of a deterministic clone
    /// @param salt The salt for deterministic deployment
    /// @return predicted The predicted address
    function predictDeterministicAddress(bytes32 salt) external view returns (address predicted) {
        return implementation.predictDeterministicAddress(salt, address(this));
    }

    /* --- View Functions --- */

    /// @notice Get the total number of clones
    /// @return The number of clones
    function getClonesCount() external view returns (uint256) {
        return clones.length;
    }

    /// @notice Get all clones
    /// @return An array of all clone addresses
    function getAllClones() external view returns (address[] memory) {
        return clones;
    }

    /// @notice Get clones owned by an address
    /// @param owner The owner address
    /// @return An array of clone addresses owned by the address
    function getOwnerClones(address owner) external view returns (address[] memory) {
        return ownerClones[owner];
    }

    /// @notice Get the number of clones owned by an address
    /// @param owner The owner address
    /// @return The number of clones owned
    function getOwnerClonesCount(address owner) external view returns (uint256) {
        return ownerClones[owner].length;
    }
}
