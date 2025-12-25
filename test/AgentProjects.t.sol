// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {AgentProjects} from "../src/credentials/AgentProjects.sol";
import {AgentRegistry} from "../src/mocks/AgentRegistry.sol";
import {IAgentProjects} from "../src/interfaces/IAgentProjects.sol";
import {IERC8048} from "../src/interfaces/IERC8048.sol";
import {IERCXXXXReviews} from "../src/interfaces/IERCXXXXReviews.sol";

contract AgentProjectsTest is Test {
    /* --- Test Accounts --- */
    
    address owner1 = address(0x1);
    address owner2 = address(0x2);
    address operator1 = address(0x3);
    address approved1 = address(0x4);
    address unauthorized = address(0x5);

    /* --- Contract Variables --- */
    
    AgentProjects public agentProjects;
    AgentRegistry public registry;
    AgentRegistry public registry2;

    /* --- Constants --- */
    
    uint256 public constant AGENT_ID_1 = 1;
    uint256 public constant AGENT_ID_2 = 2;
    uint256 public constant AGENT_ID_3 = 3;

    /* --- Events --- */
    
    event MetadataSet(uint256 indexed tokenId, string key, string indexed indexedKey, bytes value);
    event ReviewSubmitted(uint256 indexed reviewerId, uint256 indexed reviewedId, bytes reviewData);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RegistryUpdated(address indexed oldRegistry, address indexed newRegistry);

    /* --- Setup --- */
    
    function setUp() public {
        registry = new AgentRegistry();
        registry2 = new AgentRegistry();
        agentProjects = new AgentProjects(address(registry));

        registry.registerAgent(AGENT_ID_1, owner1);
        registry.registerAgent(AGENT_ID_2, owner2);
        registry.registerAgent(AGENT_ID_3, owner1);
        
        // Also register agents in registry2 for testing registry updates
        registry2.registerAgent(AGENT_ID_1, owner1);
        registry2.registerAgent(AGENT_ID_2, owner2);
    }
    
    /* --- Test Dividers --- */
    
    function test1000________________________________________________________________________________() public pure {}
    function test1100____________________AGENT_PROJECTS_TESTS_____________________________________() public pure {}
    function test1200________________________________________________________________________________() public pure {}
    
    /* --- Project Setter Tests --- */
    
    function test_001____setProject____________________OwnerCanSetProject() public {
        string memory key = "firstproject";
        bytes memory value = "project data";

        vm.prank(owner1);
        agentProjects.setProject(AGENT_ID_1, key, value);

        bytes memory retrieved = agentProjects.getMetadata(AGENT_ID_1, key);
        assertEq(retrieved, value);
    }

    function test_002____setProject____________________OperatorCanSetProject() public {
        vm.prank(owner1);
        registry.setOperator(operator1, true);

        string memory key = "firstproject";
        bytes memory value = "project data";

        vm.prank(operator1);
        agentProjects.setProject(AGENT_ID_1, key, value);

        bytes memory retrieved = agentProjects.getMetadata(AGENT_ID_1, key);
        assertEq(retrieved, value);
    }

    function test_003____setProject____________________ApprovedCanSetProject() public {
        vm.prank(owner1);
        registry.approve(approved1, AGENT_ID_1, 1);

        string memory key = "firstproject";
        bytes memory value = "project data";

        vm.prank(approved1);
        agentProjects.setProject(AGENT_ID_1, key, value);

        bytes memory retrieved = agentProjects.getMetadata(AGENT_ID_1, key);
        assertEq(retrieved, value);
    }

    function test_004____setProject____________________UnauthorizedCannotSetProject() public {
        string memory key = "firstproject";
        bytes memory value = "project data";

        vm.prank(unauthorized);
        vm.expectRevert(AgentProjects.NotAuthorized.selector);
        agentProjects.setProject(AGENT_ID_1, key, value);
    }

    function test_005____setProject____________________RevertsWhenAgentNotFound() public {
        string memory key = "firstproject";
        bytes memory value = "project data";

        vm.prank(owner1);
        vm.expectRevert(AgentProjects.AgentNotFound.selector);
        agentProjects.setProject(999, key, value);
    }

    function test_006____setProject____________________CanSetMultipleKeys() public {
        vm.startPrank(owner1);
        agentProjects.setProject(AGENT_ID_1, "name", "Project Name");
        agentProjects.setProject(AGENT_ID_1, "version", "1.0");
        agentProjects.setProject(AGENT_ID_1, "deliverable", "deliverable data");
        vm.stopPrank();

        assertEq(agentProjects.getMetadata(AGENT_ID_1, "name"), "Project Name");
        assertEq(agentProjects.getMetadata(AGENT_ID_1, "version"), "1.0");
        assertEq(agentProjects.getMetadata(AGENT_ID_1, "deliverable"), "deliverable data");
    }

    function test_007____setProject____________________CanUpdateExistingProject() public {
        string memory key = "firstproject";
        bytes memory value1 = "initial data";
        bytes memory value2 = "updated data";

        vm.startPrank(owner1);
        agentProjects.setProject(AGENT_ID_1, key, value1);
        assertEq(agentProjects.getMetadata(AGENT_ID_1, key), value1);

        agentProjects.setProject(AGENT_ID_1, key, value2);
        assertEq(agentProjects.getMetadata(AGENT_ID_1, key), value2);
        vm.stopPrank();
    }

    function test_008____setProject____________________EmitsMetadataSetEvent() public {
        string memory key = "firstproject";
        bytes memory value = "project data";

        vm.prank(owner1);
        vm.expectEmit(true, true, false, true);
        emit MetadataSet(AGENT_ID_1, key, key, value);
        agentProjects.setProject(AGENT_ID_1, key, value);
    }

    /* --- Review Tests --- */

    function test_009____review_______________________OwnerCanSubmitReview() public {
        bytes memory reviewData = "score: 95 review: excellent work";

        vm.prank(owner1);
        agentProjects.review(AGENT_ID_1, AGENT_ID_2, reviewData);

        bytes memory retrieved = agentProjects.getReview(AGENT_ID_1, AGENT_ID_2);
        assertEq(retrieved, reviewData);
    }

    function test_010____review_______________________OperatorCanSubmitReview() public {
        vm.prank(owner1);
        registry.setOperator(operator1, true);

        bytes memory reviewData = "score: 90 review: good work";

        vm.prank(operator1);
        agentProjects.review(AGENT_ID_1, AGENT_ID_2, reviewData);

        bytes memory retrieved = agentProjects.getReview(AGENT_ID_1, AGENT_ID_2);
        assertEq(retrieved, reviewData);
    }

    function test_011____review_______________________ApprovedCanSubmitReview() public {
        vm.prank(owner1);
        registry.approve(approved1, AGENT_ID_1, 1);

        bytes memory reviewData = "score: 85 review: satisfactory";

        vm.prank(approved1);
        agentProjects.review(AGENT_ID_1, AGENT_ID_2, reviewData);

        bytes memory retrieved = agentProjects.getReview(AGENT_ID_1, AGENT_ID_2);
        assertEq(retrieved, reviewData);
    }

    function test_012____review_______________________UnauthorizedCannotSubmitReview() public {
        bytes memory reviewData = "score: 50 review: poor";

        vm.prank(unauthorized);
        vm.expectRevert(AgentProjects.NotAuthorized.selector);
        agentProjects.review(AGENT_ID_1, AGENT_ID_2, reviewData);
    }

    function test_013____review_______________________RevertsWhenReviewerNotAgent() public {
        bytes memory reviewData = "score: 50 review: poor";

        vm.prank(owner1);
        vm.expectRevert(AgentProjects.ReviewerNotAgent.selector);
        agentProjects.review(999, AGENT_ID_2, reviewData);
    }

    function test_014____review_______________________CanSubmitMultipleReviews() public {
        bytes memory review1 = "score: 95 review: excellent";
        bytes memory review2 = "score: 90 review: very good";
        bytes memory review3 = "score: 85 review: good";

        vm.startPrank(owner1);
        agentProjects.review(AGENT_ID_1, AGENT_ID_2, review1);
        vm.stopPrank();

        vm.startPrank(owner2);
        agentProjects.review(AGENT_ID_2, AGENT_ID_1, review2);
        vm.stopPrank();

        vm.startPrank(owner1);
        agentProjects.review(AGENT_ID_3, AGENT_ID_2, review3);
        vm.stopPrank();

        assertEq(agentProjects.getReview(AGENT_ID_1, AGENT_ID_2), review1);
        assertEq(agentProjects.getReview(AGENT_ID_2, AGENT_ID_1), review2);
        assertEq(agentProjects.getReview(AGENT_ID_3, AGENT_ID_2), review3);
    }

    function test_015____review_______________________CanUpdateExistingReview() public {
        bytes memory review1 = "score: 80 review: initial";
        bytes memory review2 = "score: 90 review: updated";

        vm.startPrank(owner1);
        agentProjects.review(AGENT_ID_1, AGENT_ID_2, review1);
        assertEq(agentProjects.getReview(AGENT_ID_1, AGENT_ID_2), review1);

        agentProjects.review(AGENT_ID_1, AGENT_ID_2, review2);
        assertEq(agentProjects.getReview(AGENT_ID_1, AGENT_ID_2), review2);
        vm.stopPrank();
    }

    function test_016____review_______________________EmitsReviewSubmittedEvent() public {
        bytes memory reviewData = "score: 95 review: excellent work";

        vm.prank(owner1);
        vm.expectEmit(true, true, false, true);
        emit ReviewSubmitted(AGENT_ID_1, AGENT_ID_2, reviewData);
        agentProjects.review(AGENT_ID_1, AGENT_ID_2, reviewData);
    }

    function test_017____review_______________________CanReviewSelf() public {
        bytes memory reviewData = "self review: completed";

        vm.prank(owner1);
        agentProjects.review(AGENT_ID_1, AGENT_ID_1, reviewData);

        bytes memory retrieved = agentProjects.getReview(AGENT_ID_1, AGENT_ID_1);
        assertEq(retrieved, reviewData);
    }

    /* --- Integration Tests --- */

    function test_018____setProjectAndReview________ProjectAndReviewIntegration() public {
        vm.startPrank(owner1);
        agentProjects.setProject(AGENT_ID_1, "firstproject-deliverable", "deliverable data");
        vm.stopPrank();

        bytes memory reviewData = "score: 95 review: successfully completed";
        vm.prank(owner2);
        agentProjects.review(AGENT_ID_2, AGENT_ID_1, reviewData);

        assertEq(agentProjects.getMetadata(AGENT_ID_1, "firstproject-deliverable"), "deliverable data");
        assertEq(agentProjects.getReview(AGENT_ID_2, AGENT_ID_1), reviewData);
    }

    function test_019____setProjectAndReview________MultipleProjectsAndReviews() public {
        vm.startPrank(owner1);
        agentProjects.setProject(AGENT_ID_1, "project1-name", "Project One");
        agentProjects.setProject(AGENT_ID_1, "project1-1", "version 1");
        agentProjects.setProject(AGENT_ID_1, "project1-1-deliverable", "deliverable 1");
        vm.stopPrank();

        vm.startPrank(owner2);
        agentProjects.review(AGENT_ID_2, AGENT_ID_1, "review for project1");
        vm.stopPrank();

        assertEq(agentProjects.getMetadata(AGENT_ID_1, "project1-name"), "Project One");
        assertEq(agentProjects.getMetadata(AGENT_ID_1, "project1-1"), "version 1");
        assertEq(agentProjects.getMetadata(AGENT_ID_1, "project1-1-deliverable"), "deliverable 1");
        assertEq(agentProjects.getReview(AGENT_ID_2, AGENT_ID_1), "review for project1");
    }

    /* --- ERC-165 Tests --- */

    function test_020____supportsInterface__________SupportsIERC165() public view {
        assertTrue(agentProjects.supportsInterface(type(IERC165).interfaceId));
    }

    function test_021____supportsInterface__________SupportsIERC8048() public view {
        assertTrue(agentProjects.supportsInterface(type(IERC8048).interfaceId));
    }

    function test_022____supportsInterface__________SupportsIERCXXXXReviews() public view {
        assertTrue(agentProjects.supportsInterface(type(IERCXXXXReviews).interfaceId));
    }

    function test_023____supportsInterface__________SupportsIAgentProjects() public view {
        assertTrue(agentProjects.supportsInterface(type(IAgentProjects).interfaceId));
    }

    function test_024____supportsInterface__________ReturnsFalseForInvalidInterface() public view {
        assertFalse(agentProjects.supportsInterface(0x12345678));
    }

    /* --- Getter Tests --- */

    function test_025____getMetadata_________________ReturnsEmptyForNonExistent() public view {
        bytes memory retrieved = agentProjects.getMetadata(AGENT_ID_1, "nonexistent");
        assertEq(retrieved.length, 0);
    }

    function test_026____getReview__________________ReturnsEmptyForNonExistent() public view {
        bytes memory retrieved = agentProjects.getReview(AGENT_ID_1, AGENT_ID_2);
        assertEq(retrieved.length, 0);
    }

    /* --- Edge Cases --- */

    function test_027____setProject_________________CanSetEmptyBytes() public {
        bytes memory empty = "";

        vm.prank(owner1);
        agentProjects.setProject(AGENT_ID_1, "empty", empty);

        bytes memory retrieved = agentProjects.getMetadata(AGENT_ID_1, "empty");
        assertEq(retrieved.length, 0);
    }

    function test_028____setProject_________________CanSetLargeBytes() public {
        bytes memory large = new bytes(1000);
        for (uint256 i = 0; i < 1000; i++) {
            large[i] = bytes1(uint8(i % 256));
        }

        vm.prank(owner1);
        agentProjects.setProject(AGENT_ID_1, "large", large);

        bytes memory retrieved = agentProjects.getMetadata(AGENT_ID_1, "large");
        assertEq(retrieved.length, 1000);
        assertEq(retrieved, large);
    }

    function test_029____agentRegistry______________ReturnsCorrectRegistryAddress() public view {
        assertEq(address(agentProjects.agentRegistry()), address(registry));
    }

    /* --- Ownable Tests --- */

    function test_030____owner_______________________ReturnsDeployerAsOwner() public view {
        assertEq(agentProjects.owner(), address(this));
    }

    function test_031____transferOwnership__________OwnerCanTransferOwnership() public {
        address newOwner = address(0x999);
        
        agentProjects.transferOwnership(newOwner);
        
        assertEq(agentProjects.owner(), newOwner);
    }

    function test_032____transferOwnership__________NonOwnerCannotTransferOwnership() public {
        address newOwner = address(0x999);
        
        vm.prank(unauthorized);
        vm.expectRevert();
        agentProjects.transferOwnership(newOwner);
        
        assertEq(agentProjects.owner(), address(this));
    }

    function test_033____transferOwnership__________EmitsOwnershipTransferredEvent() public {
        address newOwner = address(0x999);
        
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(address(this), newOwner);
        agentProjects.transferOwnership(newOwner);
    }

    function test_034____renounceOwnership__________OwnerCanRenounceOwnership() public {
        agentProjects.renounceOwnership();
        
        assertEq(agentProjects.owner(), address(0));
    }

    function test_035____renounceOwnership__________NonOwnerCannotRenounceOwnership() public {
        vm.prank(unauthorized);
        vm.expectRevert();
        agentProjects.renounceOwnership();
        
        assertEq(agentProjects.owner(), address(this));
    }

    /* --- Registry Update Tests --- */

    function test_036____setAgentRegistry___________OwnerCanUpdateRegistry() public {
        address oldRegistry = agentProjects.agentRegistry();
        
        vm.expectEmit(true, true, false, false);
        emit RegistryUpdated(oldRegistry, address(registry2));
        agentProjects.setAgentRegistry(address(registry2));
        
        assertEq(agentProjects.agentRegistry(), address(registry2));
    }

    function test_037____setAgentRegistry___________NonOwnerCannotUpdateRegistry() public {
        address oldRegistry = agentProjects.agentRegistry();
        
        vm.prank(unauthorized);
        vm.expectRevert();
        agentProjects.setAgentRegistry(address(registry2));
        
        assertEq(agentProjects.agentRegistry(), oldRegistry);
    }

    function test_038____setAgentRegistry___________RevertsWhenSettingZeroAddress() public {
        vm.expectRevert(AgentProjects.InvalidRegistry.selector);
        agentProjects.setAgentRegistry(address(0));
    }

    function test_039____setAgentRegistry___________CanUpdateRegistryMultipleTimes() public {
        AgentRegistry registry3 = new AgentRegistry();
        
        agentProjects.setAgentRegistry(address(registry2));
        assertEq(agentProjects.agentRegistry(), address(registry2));
        
        agentProjects.setAgentRegistry(address(registry3));
        assertEq(agentProjects.agentRegistry(), address(registry3));
    }

    function test_040____setAgentRegistry___________WorksAfterOwnershipTransfer() public {
        address newOwner = address(0x999);
        agentProjects.transferOwnership(newOwner);
        
        vm.prank(newOwner);
        agentProjects.setAgentRegistry(address(registry2));
        
        assertEq(agentProjects.agentRegistry(), address(registry2));
    }

    function test_041____setAgentRegistry___________NewRegistryWorksForAuthorization() public {
        // Set up project with old registry
        vm.prank(owner1);
        agentProjects.setProject(AGENT_ID_1, "test", "data");
        
        // Update registry
        agentProjects.setAgentRegistry(address(registry2));
        
        // Should still work with new registry (same agent IDs registered)
        vm.prank(owner1);
        agentProjects.setProject(AGENT_ID_1, "test2", "data2");
        
        assertEq(agentProjects.getMetadata(AGENT_ID_1, "test"), "data");
        assertEq(agentProjects.getMetadata(AGENT_ID_1, "test2"), "data2");
    }

    function test_042____setAgentRegistry___________NewRegistryWorksForReviews() public {
        // Set up review with old registry
        bytes memory reviewData = "initial review";
        vm.prank(owner1);
        agentProjects.review(AGENT_ID_1, AGENT_ID_2, reviewData);
        
        // Update registry
        agentProjects.setAgentRegistry(address(registry2));
        
        // Should still work with new registry
        bytes memory reviewData2 = "updated review";
        vm.prank(owner1);
        agentProjects.review(AGENT_ID_1, AGENT_ID_2, reviewData2);
        
        assertEq(agentProjects.getReview(AGENT_ID_1, AGENT_ID_2), reviewData2);
    }

    function test_043____setAgentRegistry___________FailsWithUnregisteredAgentInNewRegistry() public {
        // Update to registry2
        agentProjects.setAgentRegistry(address(registry2));
        
        // Try to use agent that doesn't exist in registry2
        vm.prank(owner1);
        vm.expectRevert(AgentProjects.AgentNotFound.selector);
        agentProjects.setProject(AGENT_ID_3, "test", "data");
    }
}
