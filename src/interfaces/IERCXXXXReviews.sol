// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title IERCXXXXReviews
 * @notice Interface for Smart Credential Reviews extension
 * @dev Allows reviewers to submit reviews for reviewed entities using a double mapping structure
 */
interface IERCXXXXReviews {
    /// @notice Emitted when a review is submitted or updated
    /// @param reviewerId The ID of the reviewer
    /// @param reviewedId The ID of the entity being reviewed
    /// @param reviewData The review data
    event ReviewSubmitted(uint256 indexed reviewerId, uint256 indexed reviewedId, bytes reviewData);

    /// @notice Submit a review for a reviewed entity
    /// @param reviewerId The ID of the reviewer
    /// @param reviewedId The ID of the entity being reviewed
    /// @param reviewData The review data as bytes
    function review(uint256 reviewerId, uint256 reviewedId, bytes calldata reviewData) external;

    /// @notice Get review data for a reviewer-reviewed pair
    /// @param reviewerId The ID of the reviewer
    /// @param reviewedId The ID of the entity being reviewed
    /// @return The review data as bytes
    function getReview(uint256 reviewerId, uint256 reviewedId) external view returns (bytes memory);
}
