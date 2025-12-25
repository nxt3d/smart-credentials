// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {SmartCredential} from "../src/SmartCredential.sol";
import {IERCXXXXReviews} from "../src/interfaces/IERCXXXXReviews.sol";

contract SmartCredentialTest is Test {
    /* --- Test Accounts --- */
    
    address user1 = address(0x1);
    address user2 = address(0x2);
    address user3 = address(0x3);
    address randomUser = address(0x999);

    /* --- Contract Variables --- */
    
    SmartCredential public smartCredential;

    /* --- Constants --- */
    
    uint256 public constant REVIEWER_ID_1 = 1;
    uint256 public constant REVIEWER_ID_2 = 2;
    uint256 public constant REVIEWER_ID_3 = 3;
    uint256 public constant REVIEWED_ID_1 = 100;
    uint256 public constant REVIEWED_ID_2 = 200;
    uint256 public constant REVIEWED_ID_3 = 300;

    /* --- Events --- */
    
    event ReviewSubmitted(uint256 indexed reviewerId, uint256 indexed reviewedId, bytes reviewData);

    /* --- Setup --- */
    
    function setUp() public {
        smartCredential = new SmartCredential();
    }
    
    /* --- Test Dividers --- */
    
    function test1000________________________________________________________________________________() public pure {}
    function test1100____________________SMART_CREDENTIAL_TESTS_____________________________________() public pure {}
    function test1200________________________________________________________________________________() public pure {}
    
    /* --- Review Tests --- */

    function test_001____review_______________________AnyoneCanSubmitReview() public {
        bytes memory reviewData = "score: 95 review: excellent work";

        smartCredential.review(REVIEWER_ID_1, REVIEWED_ID_1, reviewData);

        bytes memory retrieved = smartCredential.getReview(REVIEWER_ID_1, REVIEWED_ID_1);
        assertEq(retrieved, reviewData);
    }

    function test_002____review_______________________DifferentUsersCanSubmitReviews() public {
        bytes memory review1 = "score: 95 review: excellent";
        bytes memory review2 = "score: 90 review: very good";
        bytes memory review3 = "score: 85 review: good";

        vm.prank(user1);
        smartCredential.review(REVIEWER_ID_1, REVIEWED_ID_1, review1);

        vm.prank(user2);
        smartCredential.review(REVIEWER_ID_2, REVIEWED_ID_1, review2);

        vm.prank(user3);
        smartCredential.review(REVIEWER_ID_3, REVIEWED_ID_2, review3);

        assertEq(smartCredential.getReview(REVIEWER_ID_1, REVIEWED_ID_1), review1);
        assertEq(smartCredential.getReview(REVIEWER_ID_2, REVIEWED_ID_1), review2);
        assertEq(smartCredential.getReview(REVIEWER_ID_3, REVIEWED_ID_2), review3);
    }

    function test_003____review_______________________RandomUserCanSubmitReview() public {
        bytes memory reviewData = "score: 80 review: satisfactory";

        vm.prank(randomUser);
        smartCredential.review(REVIEWER_ID_1, REVIEWED_ID_1, reviewData);

        bytes memory retrieved = smartCredential.getReview(REVIEWER_ID_1, REVIEWED_ID_1);
        assertEq(retrieved, reviewData);
    }

    function test_004____review_______________________CanSubmitMultipleReviewsForSameReviewed() public {
        bytes memory review1 = "score: 95 review: excellent";
        bytes memory review2 = "score: 90 review: very good";
        bytes memory review3 = "score: 85 review: good";

        smartCredential.review(REVIEWER_ID_1, REVIEWED_ID_1, review1);
        smartCredential.review(REVIEWER_ID_2, REVIEWED_ID_1, review2);
        smartCredential.review(REVIEWER_ID_3, REVIEWED_ID_1, review3);

        assertEq(smartCredential.getReview(REVIEWER_ID_1, REVIEWED_ID_1), review1);
        assertEq(smartCredential.getReview(REVIEWER_ID_2, REVIEWED_ID_1), review2);
        assertEq(smartCredential.getReview(REVIEWER_ID_3, REVIEWED_ID_1), review3);
    }

    function test_005____review_______________________CanUpdateExistingReview() public {
        bytes memory review1 = "score: 80 review: initial";
        bytes memory review2 = "score: 90 review: updated";

        smartCredential.review(REVIEWER_ID_1, REVIEWED_ID_1, review1);
        assertEq(smartCredential.getReview(REVIEWER_ID_1, REVIEWED_ID_1), review1);

        smartCredential.review(REVIEWER_ID_1, REVIEWED_ID_1, review2);
        assertEq(smartCredential.getReview(REVIEWER_ID_1, REVIEWED_ID_1), review2);
    }

    function test_006____review_______________________CanReviewSelf() public {
        bytes memory reviewData = "self review: completed";

        smartCredential.review(REVIEWER_ID_1, REVIEWER_ID_1, reviewData);

        bytes memory retrieved = smartCredential.getReview(REVIEWER_ID_1, REVIEWER_ID_1);
        assertEq(retrieved, reviewData);
    }

    function test_007____review_______________________EmitsReviewSubmittedEvent() public {
        bytes memory reviewData = "score: 95 review: excellent work";

        vm.expectEmit(true, true, false, true);
        emit ReviewSubmitted(REVIEWER_ID_1, REVIEWED_ID_1, reviewData);
        smartCredential.review(REVIEWER_ID_1, REVIEWED_ID_1, reviewData);
    }

    function test_008____review_______________________CanUseZeroIds() public {
        bytes memory reviewData = "review with zero ids";

        smartCredential.review(0, 0, reviewData);

        bytes memory retrieved = smartCredential.getReview(0, 0);
        assertEq(retrieved, reviewData);
    }

    function test_009____review_______________________CanUseLargeIds() public {
        uint256 largeId1 = type(uint256).max;
        uint256 largeId2 = type(uint256).max - 1;
        bytes memory reviewData = "review with large ids";

        smartCredential.review(largeId1, largeId2, reviewData);

        bytes memory retrieved = smartCredential.getReview(largeId1, largeId2);
        assertEq(retrieved, reviewData);
    }

    /* --- Getter Tests --- */

    function test_010____getReview__________________ReturnsEmptyForNonExistent() public view {
        bytes memory retrieved = smartCredential.getReview(REVIEWER_ID_1, REVIEWED_ID_1);
        assertEq(retrieved.length, 0);
    }

    function test_011____getReview__________________ReturnsCorrectReview() public {
        bytes memory reviewData = "score: 95 review: excellent work";

        smartCredential.review(REVIEWER_ID_1, REVIEWED_ID_1, reviewData);

        bytes memory retrieved = smartCredential.getReview(REVIEWER_ID_1, REVIEWED_ID_1);
        assertEq(retrieved, reviewData);
        assertEq(retrieved.length, reviewData.length);
    }

    function test_012____getReview__________________DifferentReviewerReviewedPairsAreIndependent() public {
        bytes memory review1 = "review 1";
        bytes memory review2 = "review 2";
        bytes memory review3 = "review 3";

        smartCredential.review(REVIEWER_ID_1, REVIEWED_ID_1, review1);
        smartCredential.review(REVIEWER_ID_1, REVIEWED_ID_2, review2);
        smartCredential.review(REVIEWER_ID_2, REVIEWED_ID_1, review3);

        assertEq(smartCredential.getReview(REVIEWER_ID_1, REVIEWED_ID_1), review1);
        assertEq(smartCredential.getReview(REVIEWER_ID_1, REVIEWED_ID_2), review2);
        assertEq(smartCredential.getReview(REVIEWER_ID_2, REVIEWED_ID_1), review3);
    }

    /* --- ERC-165 Tests --- */

    function test_013____supportsInterface__________SupportsIERC165() public view {
        assertTrue(smartCredential.supportsInterface(type(IERC165).interfaceId));
    }

    function test_014____supportsInterface__________SupportsIERCXXXXReviews() public view {
        assertTrue(smartCredential.supportsInterface(type(IERCXXXXReviews).interfaceId));
    }

    function test_015____supportsInterface__________ReturnsFalseForInvalidInterface() public view {
        assertFalse(smartCredential.supportsInterface(0x12345678));
    }

    /* --- Edge Cases --- */

    function test_016____review_______________________CanSetEmptyBytes() public {
        bytes memory empty = "";

        smartCredential.review(REVIEWER_ID_1, REVIEWED_ID_1, empty);

        bytes memory retrieved = smartCredential.getReview(REVIEWER_ID_1, REVIEWED_ID_1);
        assertEq(retrieved.length, 0);
    }

    function test_017____review_______________________CanSetLargeBytes() public {
        bytes memory large = new bytes(1000);
        for (uint256 i = 0; i < 1000; i++) {
            large[i] = bytes1(uint8(i % 256));
        }

        smartCredential.review(REVIEWER_ID_1, REVIEWED_ID_1, large);

        bytes memory retrieved = smartCredential.getReview(REVIEWER_ID_1, REVIEWED_ID_1);
        assertEq(retrieved.length, 1000);
        assertEq(retrieved, large);
    }

    function test_018____review_______________________CanSetVeryLargeBytes() public {
        bytes memory veryLarge = new bytes(10000);
        for (uint256 i = 0; i < 10000; i++) {
            veryLarge[i] = bytes1(uint8(i % 256));
        }

        smartCredential.review(REVIEWER_ID_1, REVIEWED_ID_1, veryLarge);

        bytes memory retrieved = smartCredential.getReview(REVIEWER_ID_1, REVIEWED_ID_1);
        assertEq(retrieved.length, 10000);
        assertEq(retrieved, veryLarge);
    }

    function test_019____review_______________________CanSetBinaryData() public {
        bytes memory binaryData = hex"deadbeefcafebabe1234567890abcdef";

        smartCredential.review(REVIEWER_ID_1, REVIEWED_ID_1, binaryData);

        bytes memory retrieved = smartCredential.getReview(REVIEWER_ID_1, REVIEWED_ID_1);
        assertEq(retrieved, binaryData);
    }

    function test_020____review_______________________CanSetUnicodeData() public {
        bytes memory unicodeData = unicode"🌟 ⭐ ✨ 🎉 🎊";

        smartCredential.review(REVIEWER_ID_1, REVIEWED_ID_1, unicodeData);

        bytes memory retrieved = smartCredential.getReview(REVIEWER_ID_1, REVIEWED_ID_1);
        assertEq(retrieved, unicodeData);
    }

    function test_021____review_______________________MultipleUpdatesFromDifferentUsers() public {
        bytes memory review1 = "first review";
        bytes memory review2 = "second review";
        bytes memory review3 = "third review";

        vm.prank(user1);
        smartCredential.review(REVIEWER_ID_1, REVIEWED_ID_1, review1);

        vm.prank(user2);
        smartCredential.review(REVIEWER_ID_1, REVIEWED_ID_1, review2);

        vm.prank(user3);
        smartCredential.review(REVIEWER_ID_1, REVIEWED_ID_1, review3);

        // Last review should be the one that persists
        assertEq(smartCredential.getReview(REVIEWER_ID_1, REVIEWED_ID_1), review3);
    }

    function test_022____review_______________________NoAuthorizationRequired() public {
        bytes memory reviewData = "anyone can review";

        // No prank needed - anyone can call directly
        smartCredential.review(REVIEWER_ID_1, REVIEWED_ID_1, reviewData);

        bytes memory retrieved = smartCredential.getReview(REVIEWER_ID_1, REVIEWED_ID_1);
        assertEq(retrieved, reviewData);
    }

    function test_023____review_______________________CanSubmitManyReviews() public {
        uint256 numReviews = 50;
        
        for (uint256 i = 0; i < numReviews; i++) {
            bytes memory reviewData = abi.encodePacked("review ", i);
            smartCredential.review(i, REVIEWED_ID_1, reviewData);
        }

        // Verify all reviews were stored
        for (uint256 i = 0; i < numReviews; i++) {
            bytes memory expected = abi.encodePacked("review ", i);
            bytes memory retrieved = smartCredential.getReview(i, REVIEWED_ID_1);
            assertEq(retrieved, expected);
        }
    }
}
