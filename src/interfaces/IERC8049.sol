// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title IERC8049
 * @notice Interface for ERC-8049 Contract-Level Onchain Metadata
 * @dev Contract-level metadata interface for storing metadata about the contract itself
 */
interface IERC8049 {
    /// @notice Emitted when contract metadata is updated
    /// @param key The metadata key
    /// @param indexedKey The indexed key for event filtering
    /// @param value The metadata value
    event ContractMetadataUpdated(string key, string indexed indexedKey, bytes value);

    /// @notice Get contract metadata
    /// @param key The metadata key
    /// @return The metadata value as bytes
    function getContractMetadata(string calldata key) external view returns (bytes memory);
}
