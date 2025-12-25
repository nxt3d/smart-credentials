// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC6909} from "@openzeppelin/contracts/interfaces/IERC6909.sol";

/**
 * @title AgentRegistry
 * @notice Minimal ERC-6909 registry for agents (one token per ID = one owner)
 * @dev Stripped down version for testing - implements ERC-6909 NFT functionality only
 */
contract AgentRegistry is IERC6909 {
    /* --- State Variables --- */

    /// @notice ERC-6909 approvals: owner => spender => id => approved
    mapping(address owner => mapping(address spender => mapping(uint256 id => bool))) private _approvals;

    /// @notice ERC-6909 operator approvals: owner => operator => approved
    mapping(address owner => mapping(address spender => bool)) public isOperator;

    /// @notice Single ownership mapping: agentId => owner
    mapping(uint256 agentId => address) private _owners;

    /// @notice Counter for agent IDs (next ID to be assigned)
    uint256 public agentIndex;

    /* --- Errors --- */

    /// @notice Thrown when the sender has insufficient balance
    error InsufficientBalance(address owner, uint256 id);

    /// @notice Thrown when the sender lacks permission
    error InsufficientPermission(address spender, uint256 id);

    /// @notice Thrown when an invalid amount is provided (must be 1 for transfers)
    error InvalidAmount();

    /// @notice Thrown when querying a non-existent agent
    error AgentNotFound();

    /* --- ERC-165 --- */

    /// @notice Check if the contract supports an interface
    /// @param interfaceId The interface identifier
    /// @return True if the interface is supported
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC6909).interfaceId;
    }

    /* --- ERC-6909 View Functions --- */

    /// @inheritdoc IERC6909
    function balanceOf(address owner, uint256 id) public view returns (uint256) {
        return _owners[id] == owner ? 1 : 0;
    }

    /// @inheritdoc IERC6909
    function allowance(address owner, address spender, uint256 id) public view returns (uint256) {
        return _approvals[owner][spender][id] ? 1 : 0;
    }

    /// @notice Get the owner of an agent
    /// @param agentId The agent ID
    /// @return The owner address
    function ownerOf(uint256 agentId) external view returns (address) {
        address owner = _owners[agentId];
        if (owner == address(0)) revert AgentNotFound();
        return owner;
    }

    /* --- ERC-6909 Transfer Functions --- */

    /// @inheritdoc IERC6909
    function transfer(address receiver, uint256 id, uint256 amount) public returns (bool) {
        if (amount != 1) revert InvalidAmount();
        if (_owners[id] != msg.sender) revert InsufficientBalance(msg.sender, id);

        _owners[id] = receiver;

        emit Transfer(msg.sender, msg.sender, receiver, id, 1);
        return true;
    }

    /// @inheritdoc IERC6909
    function transferFrom(address sender, address receiver, uint256 id, uint256 amount) public returns (bool) {
        if (amount != 1) revert InvalidAmount();

        _checkApprovedOwnerOrOperator(sender, id);
        if (_owners[id] != sender) revert InsufficientBalance(sender, id);

        _owners[id] = receiver;

        emit Transfer(msg.sender, sender, receiver, id, 1);
        return true;
    }

    /* --- ERC-6909 Approval Functions --- */

    /// @inheritdoc IERC6909
    /// @dev Any non-zero amount grants approval (stored as true), zero revokes it (stored as false)
    function approve(address spender, uint256 id, uint256 amount) public returns (bool) {
        bool approved = amount > 0;
        _approvals[msg.sender][spender][id] = approved;
        emit Approval(msg.sender, spender, id, approved ? 1 : 0);
        return true;
    }

    /// @inheritdoc IERC6909
    function setOperator(address spender, bool approved) public returns (bool) {
        isOperator[msg.sender][spender] = approved;
        emit OperatorSet(msg.sender, spender, approved);
        return true;
    }

    /* --- Registration Functions (for testing) --- */

    /// @notice Register a new agent (for testing purposes)
    /// @param owner The owner of the agent
    /// @return agentId The ID of the registered agent
    function register(address owner) external returns (uint256 agentId) {
        agentId = agentIndex++;
        _owners[agentId] = owner;
        emit Transfer(msg.sender, address(0), owner, agentId, 1);
    }

    /// @notice Register a new agent with a specific ID (for testing purposes)
    /// @param agentId The agent ID to register
    /// @param owner The owner of the agent
    function registerAgent(uint256 agentId, address owner) external {
        require(_owners[agentId] == address(0), "Agent already exists");
        _owners[agentId] = owner;
        emit Transfer(msg.sender, address(0), owner, agentId, 1);
    }

    /* --- Internal Functions --- */

    /// @dev Check if msg.sender is owner, operator, or has approval for the token
    ///      Consumes the approval if used (ERC-6909 compliant)
    function _checkApprovedOwnerOrOperator(address sender, uint256 id) internal {
        if (sender == msg.sender) return;
        if (isOperator[sender][msg.sender]) return;
        if (_approvals[sender][msg.sender][id]) {
            // Consume the approval (one-time use per ERC-6909)
            _approvals[sender][msg.sender][id] = false;
            return;
        }
        revert InsufficientPermission(msg.sender, id);
    }
}
