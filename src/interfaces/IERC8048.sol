// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title IERC8048
 * @notice Interface for ERC-8048 Onchain Token Metadata
 * @dev Token-standard agnostic metadata interface
 */
interface IERC8048 {
    /// @notice Emitted when metadata is set for a token
    /// @param tokenId The token ID
    /// @param key The metadata key
    /// @param indexedKey The indexed key for event filtering
    /// @param value The metadata value
    event MetadataSet(uint256 indexed tokenId, string key, string indexed indexedKey, bytes value);

    /// @notice Get metadata for a token
    /// @param tokenId The token ID
    /// @param key The metadata key
    /// @return The metadata value as bytes
    function getMetadata(uint256 tokenId, string calldata key) external view returns (bytes memory);
}
