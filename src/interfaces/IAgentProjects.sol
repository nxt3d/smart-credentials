// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC8048} from "./IERC8048.sol";
import {IERCXXXXReviews} from "./IERCXXXXReviews.sol";

/**
 * @title IAgentProjects
 * @notice Interface for the AgentProjects smart credential contract
 * @dev Extends ERC-8048 for project metadata and ERCXXXXReviews for reviews
 */
interface IAgentProjects is IERC8048, IERCXXXXReviews {
    /// @notice Emitted when a project is created
    /// @param agentId The agent ID that owns the project
    /// @param key The project key
    /// @param value The initial project data
    event ProjectCreated(uint256 indexed agentId, string key, string indexed indexedKey, bytes value);

    /// @notice Get the agent registry address
    /// @return The address of the agent registry
    function agentRegistry() external view returns (address);

    /// @notice Set project data for an agent
    /// @dev Only callable by agent owner, operator, or approved address
    /// @param agentId The agent ID
    /// @param key The project key
    /// @param value The project data
    function setProject(uint256 agentId, string calldata key, bytes calldata value) external;

    /// @notice Submit a review for an agent's projects
    /// @dev Only callable by agents from the same registry
    /// @param reviewerId The reviewing agent's ID
    /// @param reviewedId The reviewed agent's ID
    /// @param reviewData The review data (can include project key references)
    function review(uint256 reviewerId, uint256 reviewedId, bytes calldata reviewData) external;

    /// @notice Update the agent registry address
    /// @dev Only callable by the contract owner
    /// @param _newRegistry The new agent registry address
    function setAgentRegistry(address _newRegistry) external;

    /// @notice Emitted when the agent registry is updated
    /// @param oldRegistry The previous registry address
    /// @param newRegistry The new registry address
    event RegistryUpdated(address indexed oldRegistry, address indexed newRegistry);
}
