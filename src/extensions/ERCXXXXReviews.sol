// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERCXXXXReviews} from "../interfaces/IERCXXXXReviews.sol";

/**
 * @title ERCXXXXReviews
 * @author @nxt3d
 * @notice Abstract extension for Smart Credential Reviews
 * @dev Uses Diamond Storage pattern (ERC-8042) for predictable storage locations.
 *      Implementing contracts must define their own authorization logic.
 */
abstract contract ERCXXXXReviews is IERCXXXXReviews {
    /// @custom:storage-location erc8042:ercXXXX.reviews.storage
    struct ReviewsStorage {
        mapping(uint256 reviewerId => mapping(uint256 reviewedId => bytes reviewData)) reviews;
    }

    // keccak256("ercXXXX.reviews.storage")
    bytes32 private constant REVIEWS_STORAGE_LOCATION =
        keccak256("ercXXXX.reviews.storage");

    function _getReviewsStorage() private pure returns (ReviewsStorage storage $) {
        bytes32 location = REVIEWS_STORAGE_LOCATION;
        assembly {
            $.slot := location
        }
    }

    /// @inheritdoc IERCXXXXReviews
    function getReview(uint256 reviewerId, uint256 reviewedId) external view virtual returns (bytes memory) {
        ReviewsStorage storage $ = _getReviewsStorage();
        return $.reviews[reviewerId][reviewedId];
    }

    /**
     * @notice Internal function to set a review
     * @dev Call this from your public review function after checking authorization
     * @param reviewerId The ID of the reviewer
     * @param reviewedId The ID of the entity being reviewed
     * @param reviewData The review data as bytes
     */
    function _setReview(uint256 reviewerId, uint256 reviewedId, bytes calldata reviewData) internal virtual {
        ReviewsStorage storage $ = _getReviewsStorage();
        $.reviews[reviewerId][reviewedId] = reviewData;
        emit ReviewSubmitted(reviewerId, reviewedId, reviewData);
    }
}
