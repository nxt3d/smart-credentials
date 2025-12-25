// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC6909} from "@openzeppelin/contracts/interfaces/IERC6909.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IAgentProjects} from "../interfaces/IAgentProjects.sol";
import {IERC8048} from "../interfaces/IERC8048.sol";
import {IERC8049} from "../interfaces/IERC8049.sol";
import {IERCXXXXReviews} from "../interfaces/IERCXXXXReviews.sol";
import {ERC8048} from "../extensions/ERC8048.sol";
import {ERC8049} from "../extensions/ERC8049.sol";
import {ERCXXXXReviews} from "../extensions/ERCXXXXReviews.sol";

/**
 * @title AgentProjects
 * @author @nxt3d
 * @notice A smart credential contract for agent projects with reviews
 * @dev Implements ERC-8048 for project metadata, ERC-8049 for contract metadata,
 *      and ERCXXXXReviews for peer reviews.
 *      Projects are keyed by agent ID and can have arbitrary metadata structure.
 *      Only the agent owner/operator/approved can create and modify projects.
 *      Only agents from the same registry can submit reviews.
 */
contract AgentProjects is IAgentProjects, ERC8048, ERC8049, ERCXXXXReviews, Ownable, Initializable {
    /* --- Constants --- */

    /// @notice Default agent registry address
    address private constant DEFAULT_AGENT_REGISTRY = 0xD0a769d82F6e0bf9d8913E570b6C823c8f7e9f40;

    /* --- State Variables --- */

    /// @notice The agent registry contract
    address public agentRegistry;

    /* --- Errors --- */

    /// @notice Thrown when the caller is not authorized to modify agent projects
    error NotAuthorized();

    /// @notice Thrown when the reviewer is not an agent in the registry
    error ReviewerNotAgent();

    /// @notice Thrown when querying a non-existent agent
    error AgentNotFound();

    /// @notice Thrown when trying to set registry to zero address
    error InvalidRegistry();

    /* --- Constructor --- */

    /// @notice Initialize the contract with an optional agent registry address
    /// @param _agentRegistry The address of the agent registry contract (zero address uses default)
    constructor(address _agentRegistry) Ownable(msg.sender) {
        agentRegistry = _agentRegistry == address(0) ? DEFAULT_AGENT_REGISTRY : _agentRegistry;
        _disableInitializers();
    }

    /// @notice Initialize a cloned contract
    /// @dev Only callable once on clones. The implementation is protected by _disableInitializers().
    /// @param _agentRegistry The address of the agent registry contract (zero address uses default)
    /// @param _owner The owner of the clone
    /// @param _name The name of the credential instance
    function initialize(address _agentRegistry, address _owner, string memory _name) external initializer {
        // Set the agent registry
        agentRegistry = _agentRegistry == address(0) ? DEFAULT_AGENT_REGISTRY : _agentRegistry;

        // Transfer ownership to the specified owner
        _transferOwnership(_owner);

        // Set the name if provided
        if (bytes(_name).length > 0) {
            _setContractMetadataMemory("name", bytes(_name));
        }
    }

    /* --- ERC-165 --- */

    /// @notice Check if the contract supports an interface
    /// @param interfaceId The interface identifier
    /// @return True if the interface is supported
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC8048).interfaceId ||
            interfaceId == type(IERC8049).interfaceId ||
            interfaceId == type(IERCXXXXReviews).interfaceId ||
            interfaceId == type(IAgentProjects).interfaceId;
    }

    /* --- Project Functions --- */

    /// @inheritdoc IAgentProjects
    function setProject(uint256 agentId, string calldata key, bytes calldata value) external {
        _checkAgentAuthorization(agentId);
        _setMetadata(agentId, key, value);
    }

    /* --- Review Functions (ERCXXXXReviews) --- */

    /// @inheritdoc IAgentProjects
    function review(uint256 reviewerId, uint256 reviewedId, bytes calldata reviewData) external override(IERCXXXXReviews, IAgentProjects) {
        _checkReviewerAuthorization(reviewerId);
        _setReview(reviewerId, reviewedId, reviewData);
    }

    /* --- Registry Management --- */

    /// @notice Update the agent registry address
    /// @dev Only callable by the contract owner
    /// @param _newRegistry The new agent registry address
    function setAgentRegistry(address _newRegistry) external onlyOwner {
        if (_newRegistry == address(0)) revert InvalidRegistry();
        
        address oldRegistry = agentRegistry;
        agentRegistry = _newRegistry;
        emit RegistryUpdated(oldRegistry, _newRegistry);
    }

    /* --- Contract Metadata (ERC-8049) --- */

    /// @notice Set contract-level metadata
    /// @dev Only callable by the contract owner
    /// @param key The metadata key
    /// @param value The metadata value
    function setContractMetadata(string calldata key, bytes calldata value) external onlyOwner {
        _setContractMetadata(key, value);
    }

    /* --- Internal Functions --- */

    /// @dev Check if msg.sender is authorized to modify an agent's projects
    ///      Uses ERC-6909-style authorization: owner or operator
    function _checkAgentAuthorization(uint256 agentId) internal view {
        // Check if agent exists by calling ownerOf (reverts if not found)
        address agentOwner;
        try this._getAgentOwner(agentId) returns (address _owner) {
            agentOwner = _owner;
        } catch {
            revert AgentNotFound();
        }

        if (msg.sender == agentOwner) return;
        if (IERC6909(agentRegistry).isOperator(agentOwner, msg.sender)) return;
        if (IERC6909(agentRegistry).allowance(agentOwner, msg.sender, agentId) > 0) return;

        revert NotAuthorized();
    }

    /// @dev Check if msg.sender is authorized to submit a review as the reviewer agent
    function _checkReviewerAuthorization(uint256 reviewerId) internal view {
        // Check if reviewer agent exists and get owner
        address agentOwner;
        try this._getAgentOwner(reviewerId) returns (address _owner) {
            agentOwner = _owner;
        } catch {
            revert ReviewerNotAgent();
        }

        if (msg.sender == agentOwner) return;
        if (IERC6909(agentRegistry).isOperator(agentOwner, msg.sender)) return;
        if (IERC6909(agentRegistry).allowance(agentOwner, msg.sender, reviewerId) > 0) return;

        revert NotAuthorized();
    }

    /// @dev External helper to get agent owner (used with try/catch)
    function _getAgentOwner(uint256 agentId) external view returns (address) {
        // Call the ownerOf function on the registry
        // This will revert if the agent doesn't exist
        (bool success, bytes memory data) = agentRegistry.staticcall(
            abi.encodeWithSignature("ownerOf(uint256)", agentId)
        );
        if (!success || data.length == 0) revert AgentNotFound();
        return abi.decode(data, (address));
    }
}
