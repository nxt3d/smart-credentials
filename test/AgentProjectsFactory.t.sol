// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {AgentProjects} from "../src/credentials/AgentProjects.sol";
import {AgentProjectsFactory} from "../src/credentials/AgentProjectsFactory.sol";
import {AgentRegistry as MockAgentRegistry} from "../src/mocks/AgentRegistry.sol";

contract AgentProjectsFactoryTest is Test {
    AgentProjects public implementation;
    AgentProjectsFactory public factory;
    MockAgentRegistry public registry;

    address public deployer = address(this);
    address public user1 = address(0x1);
    address public user2 = address(0x2);

    event AgentProjectsCreated(
        address indexed clone,
        address indexed agentRegistry,
        string name,
        address indexed owner
    );

    function setUp() public {
        // Deploy mock registry
        registry = new MockAgentRegistry();

        // Deploy implementation
        implementation = new AgentProjects(address(registry));

        // Deploy factory
        factory = new AgentProjectsFactory(address(implementation));
    }

    /* --- Basic Factory Tests --- */

    function test_001____factory______________________CanDeployFactory() public {
        assertEq(factory.implementation(), address(implementation));
        assertEq(factory.getClonesCount(), 0);
    }

    function test_002____clone_______________________CanCreateClone() public {
        vm.startPrank(user1);
        
        address clone = factory.createAgentProjects(address(registry), "Test Credential");
        
        assertGt(uint256(uint160(clone)), 0);
        assertEq(factory.getClonesCount(), 1);
        assertEq(factory.clones(0), clone);
        
        vm.stopPrank();
    }

    function test_003____clone_______________________CloneHasCorrectOwner() public {
        vm.startPrank(user1);
        
        address clone = factory.createAgentProjects(address(registry), "Test Credential");
        AgentProjects projects = AgentProjects(clone);
        
        assertEq(projects.owner(), user1);
        
        vm.stopPrank();
    }

    function test_004____clone_______________________CloneHasCorrectRegistry() public {
        vm.startPrank(user1);
        
        address clone = factory.createAgentProjects(address(registry), "Test Credential");
        AgentProjects projects = AgentProjects(clone);
        
        assertEq(projects.agentRegistry(), address(registry));
        
        vm.stopPrank();
    }

    function test_005____clone_______________________CloneHasName() public {
        vm.startPrank(user1);
        
        address clone = factory.createAgentProjects(address(registry), "My Custom Credential");
        AgentProjects projects = AgentProjects(clone);
        
        bytes memory name = projects.getContractMetadata("name");
        assertEq(string(name), "My Custom Credential");
        
        vm.stopPrank();
    }

    function test_006____clone_______________________CloneWithEmptyName() public {
        vm.startPrank(user1);
        
        address clone = factory.createAgentProjects(address(registry), "");
        AgentProjects projects = AgentProjects(clone);
        
        bytes memory name = projects.getContractMetadata("name");
        assertEq(name.length, 0);
        
        vm.stopPrank();
    }

    function test_007____clone_______________________CloneWithDefaultRegistry() public {
        vm.startPrank(user1);
        
        address clone = factory.createAgentProjects(address(0), "Test");
        AgentProjects projects = AgentProjects(clone);
        
        // Should use default registry
        assertEq(projects.agentRegistry(), 0xD0a769d82F6e0bf9d8913E570b6C823c8f7e9f40);
        
        vm.stopPrank();
    }

    function test_008____event_______________________EmitsCreatedEvent() public {
        vm.startPrank(user1);
        
        vm.expectEmit(false, true, false, true);
        emit AgentProjectsCreated(address(0), address(registry), "Test", user1);
        
        factory.createAgentProjects(address(registry), "Test");
        
        vm.stopPrank();
    }

    /* --- Deterministic Deployment Tests --- */

    function test_009____deterministic_______________CanCreateDeterministic() public {
        vm.startPrank(user1);
        
        bytes32 salt = keccak256("test-salt");
        address predicted = factory.predictDeterministicAddress(salt);
        
        address clone = factory.createAgentProjectsDeterministic(address(registry), "Test", salt);
        
        assertEq(clone, predicted);
        assertEq(factory.getClonesCount(), 1);
        
        vm.stopPrank();
    }

    function test_010____deterministic_______________SameSaltGivesSameAddress() public {
        vm.startPrank(user1);
        
        bytes32 salt = keccak256("test-salt");
        address predicted1 = factory.predictDeterministicAddress(salt);
        address predicted2 = factory.predictDeterministicAddress(salt);
        
        assertEq(predicted1, predicted2);
        
        vm.stopPrank();
    }

    function test_011____deterministic_______________DifferentSaltGivesDifferentAddress() public {
        vm.startPrank(user1);
        
        bytes32 salt1 = keccak256("salt-1");
        bytes32 salt2 = keccak256("salt-2");
        
        address predicted1 = factory.predictDeterministicAddress(salt1);
        address predicted2 = factory.predictDeterministicAddress(salt2);
        
        assertNotEq(predicted1, predicted2);
        
        vm.stopPrank();
    }

    function test_012____deterministic_______________CannotRedeployWithSameSalt() public {
        vm.startPrank(user1);
        
        bytes32 salt = keccak256("test-salt");
        factory.createAgentProjectsDeterministic(address(registry), "Test 1", salt);
        
        vm.expectRevert();
        factory.createAgentProjectsDeterministic(address(registry), "Test 2", salt);
        
        vm.stopPrank();
    }

    /* --- Multiple Clones Tests --- */

    function test_013____multiple____________________CanCreateMultipleClones() public {
        vm.startPrank(user1);
        
        address clone1 = factory.createAgentProjects(address(registry), "Credential 1");
        address clone2 = factory.createAgentProjects(address(registry), "Credential 2");
        address clone3 = factory.createAgentProjects(address(registry), "Credential 3");
        
        assertEq(factory.getClonesCount(), 3);
        assertNotEq(clone1, clone2);
        assertNotEq(clone2, clone3);
        assertNotEq(clone1, clone3);
        
        vm.stopPrank();
    }

    function test_014____multiple____________________TracksOwnerClones() public {
        vm.startPrank(user1);
        address clone1 = factory.createAgentProjects(address(registry), "User1-1");
        address clone2 = factory.createAgentProjects(address(registry), "User1-2");
        vm.stopPrank();
        
        vm.startPrank(user2);
        address clone3 = factory.createAgentProjects(address(registry), "User2-1");
        vm.stopPrank();
        
        assertEq(factory.getOwnerClonesCount(user1), 2);
        assertEq(factory.getOwnerClonesCount(user2), 1);
        
        address[] memory user1Clones = factory.getOwnerClones(user1);
        assertEq(user1Clones.length, 2);
        assertEq(user1Clones[0], clone1);
        assertEq(user1Clones[1], clone2);
        
        address[] memory user2Clones = factory.getOwnerClones(user2);
        assertEq(user2Clones.length, 1);
        assertEq(user2Clones[0], clone3);
    }

    function test_015____multiple____________________GetAllClones() public {
        vm.startPrank(user1);
        address clone1 = factory.createAgentProjects(address(registry), "Clone 1");
        address clone2 = factory.createAgentProjects(address(registry), "Clone 2");
        vm.stopPrank();
        
        address[] memory allClones = factory.getAllClones();
        assertEq(allClones.length, 2);
        assertEq(allClones[0], clone1);
        assertEq(allClones[1], clone2);
    }

    /* --- Clone Functionality Tests --- */

    function test_016____functionality_______________CloneCanSetProjects() public {
        // Register agent in registry
        registry.registerAgent(1, user1);
        
        vm.startPrank(user1);
        
        address clone = factory.createAgentProjects(address(registry), "Test");
        AgentProjects projects = AgentProjects(clone);
        
        // Should be able to set project metadata
        projects.setProject(1, "description", "Test project");
        
        bytes memory description = projects.getMetadata(1, "description");
        assertEq(string(description), "Test project");
        
        vm.stopPrank();
    }

    function test_017____functionality_______________CloneCanSubmitReviews() public {
        // Register agents
        registry.registerAgent(1, user1);
        registry.registerAgent(2, user2);
        
        vm.startPrank(user1);
        
        address clone = factory.createAgentProjects(address(registry), "Test");
        AgentProjects projects = AgentProjects(clone);
        
        // Should be able to submit reviews
        projects.review(1, 2, "Great work!");
        
        bytes memory review = projects.getReview(1, 2);
        assertEq(string(review), "Great work!");
        
        vm.stopPrank();
    }

    function test_018____functionality_______________CloneOwnerCanUpdateRegistry() public {
        vm.startPrank(user1);
        
        address clone = factory.createAgentProjects(address(registry), "Test");
        AgentProjects projects = AgentProjects(clone);
        
        MockAgentRegistry newRegistry = new MockAgentRegistry();
        projects.setAgentRegistry(address(newRegistry));
        
        assertEq(projects.agentRegistry(), address(newRegistry));
        
        vm.stopPrank();
    }

    function test_019____functionality_______________CloneOwnerCanUpdateMetadata() public {
        vm.startPrank(user1);
        
        address clone = factory.createAgentProjects(address(registry), "Original Name");
        AgentProjects projects = AgentProjects(clone);
        
        // Owner can update contract metadata
        projects.setContractMetadata("name", "Updated Name");
        projects.setContractMetadata("description", "A credential for testing");
        
        bytes memory name = projects.getContractMetadata("name");
        bytes memory description = projects.getContractMetadata("description");
        
        assertEq(string(name), "Updated Name");
        assertEq(string(description), "A credential for testing");
        
        vm.stopPrank();
    }

    function test_020____initialization______________CannotReinitialize() public {
        vm.startPrank(user1);
        
        address clone = factory.createAgentProjects(address(registry), "Test");
        AgentProjects projects = AgentProjects(clone);
        
        // Should revert when trying to reinitialize
        vm.expectRevert();
        projects.initialize(address(registry), user2, "New Name");
        
        vm.stopPrank();
    }

    function test_021____implementation______________CannotInitializeImplementation() public {
        // Implementation was initialized in constructor
        vm.expectRevert();
        implementation.initialize(address(registry), user1, "Test");
    }

    /* --- Interface Support Tests --- */

    function test_022____interface___________________CloneSupportsERC8049() public {
        vm.startPrank(user1);
        
        address clone = factory.createAgentProjects(address(registry), "Test");
        AgentProjects projects = AgentProjects(clone);
        
        // Check ERC-165 support
        assertTrue(projects.supportsInterface(type(IERC165).interfaceId));
        
        vm.stopPrank();
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
