// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERCXXXXReviews} from "./interfaces/IERCXXXXReviews.sol";
import {ERCXXXXReviews} from "./extensions/ERCXXXXReviews.sol";

/**
 * @title SmartCredential
 * @author @nxt3d
 * @notice A simple, open smart credential contract that allows anyone to review any ID
 * @dev Implements ERCXXXXReviews with no authorization checks - completely open for anyone to use
 */
contract SmartCredential is ERCXXXXReviews {
    /* --- ERC-165 --- */

    /// @notice Check if the contract supports an interface
    /// @param interfaceId The interface identifier
    /// @return True if the interface is supported
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERCXXXXReviews).interfaceId;
    }

    /* --- Review Functions --- */

    /// @inheritdoc IERCXXXXReviews
    function review(uint256 reviewerId, uint256 reviewedId, bytes calldata reviewData) external override {
        _setReview(reviewerId, reviewedId, reviewData);
    }
}
