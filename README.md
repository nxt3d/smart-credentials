# Smart Credentials

A specification and reference implementation for blockchain-based credentials that are resolved via smart contracts with support for onchain, offchain, and zero-knowledge proofs.

## Deployments

**Sepolia Testnet (Latest - Factory Pattern v1.1.0):**
- **Block:** `9912730` (Dec 23, 2025)
- **Implementation:** [`0x867990E9bec0B52067d5f5ce80f26096896d09c8`](https://sepolia.etherscan.io/address/0x867990e9bec0b52067d5f5ce80f26096896d09c8)
- **Factory:** [`0x4EC7776636f664E3AbBD700fB4BF745FC9E6c0DC`](https://sepolia.etherscan.io/address/0x4ec7776636f664e3abbd700fb4bf745fc9e6c0dc)
- **Deployment Report:** [sepolia-2025-12-25-0030.md](./deployments/sepolia-2025-12-25-0030.md)

Create your own Smart Credential instance:
```solidity
AgentProjectsFactory(0x4EC7776636f664E3AbBD700fB4BF745FC9E6c0DC)
    .createAgentProjects(registryAddress, "My Credential");
```

## Overview

Smart Credentials provide a uniform method for resolving credentials in the context of onchain identity profiles. Credentials are records "about" an entity controlled by a credential issuer, as opposed to records "by" an entity that the entity controls directly.

Smart Credentials support fully onchain data, a mix of onchain and offchain data, or fully offchain data with onchain verification. They are designed to support Zero Knowledge Proofs (ZKPs), enabling privacy-preserving credentials where users can prove specific facts without revealing the underlying data (e.g., proving age is over 18 without revealing birthdate).

## Motivation

With the rise of AI agents, users on the internet will become increasingly indistinguishable from AI agents. We need provable onchain identities that allow real human users to prove their humanity, AI agents to prove who controls them and what they can do, and AI agents to develop reputations and trust based on their work. Blockchains are well-positioned to provide provable identity because records can be broadcast publicly with provable ownership and provenance.

### Identity and Credentials

For the purposes of this specification, "users" refers to both human users and AI agents. Unlike profile data that a user controls (e.g., name, avatar), credentials are records "about" a user controlled by credential issuers—verifiable facts that users cannot fabricate. Examples include:

- **Proof of Personhood / KYC**: Verify humanity or identity from trusted credential issuers
- **Reputation Systems**: Ratings for AI agents based on work and reviews
- **Privacy-Preserving Proofs**: ZKPs that prove facts without revealing underlying data

## Specification

This repository contains the reference implementation for [ERC-XXXX: Smart Credentials](https://eips.ethereum.org/EIPS/eip-XXXX). For the complete specification, please refer to the ERC document.

### Reviews Extension Interface

Contracts implementing the Reviews extension must implement the following interface:

```solidity
interface IERCXXXXReviews {
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
    
    /// @notice Emitted when a review is submitted or updated
    event ReviewSubmitted(uint256 indexed reviewerId, uint256 indexed reviewedId, bytes reviewData);
}
```

## Installation

This project uses [Foundry](https://book.getfoundry.sh/). To install dependencies:

```bash
forge install
```

## Usage

### Simple Smart Credential

The `SmartCredential` contract is a simple, open implementation that allows anyone to review any ID:

```solidity
import {SmartCredential} from "./src/SmartCredential.sol";

// Deploy the contract
SmartCredential credential = new SmartCredential();

// Submit a review
bytes memory reviewData = "score: 95 review: successfully completed";
credential.review(123, 456, reviewData);

// Retrieve a review
bytes memory retrieved = credential.getReview(123, 456);
```

### Agent Projects Credential

The `AgentProjects` contract implements both ERC-8048 metadata and the Reviews extension with authorization checks. It also supports ERC-8049 for contract-level metadata.

#### Direct Deployment

```solidity
import {AgentProjects} from "./src/credentials/AgentProjects.sol";

// Deploy with an agent registry (zero address uses default registry)
AgentProjects projects = new AgentProjects(agentRegistryAddress);

// Set project metadata (requires authorization)
projects.setProject(agentId, "project-name", "My Project");

// Submit a review (requires authorization)
bytes memory reviewData = "score: 95 review: excellent work";
projects.review(reviewerId, reviewedId, reviewData);

// Set contract metadata (only owner)
projects.setContractMetadata("name", "Agent Projects");
projects.setContractMetadata("description", "A credential for agent projects");

// Update agent registry (only owner)
projects.setAgentRegistry(newRegistryAddress);

// Transfer ownership
projects.transferOwnership(newOwner);
```

#### Factory Pattern (Recommended)

For gas-efficient deployments, use the factory pattern with minimal clones (ERC-1167):

```solidity
import {AgentProjectsFactory} from "./src/credentials/AgentProjectsFactory.sol";
import {AgentProjects} from "./src/credentials/AgentProjects.sol";

// Deploy factory with implementation (one-time)
AgentProjects implementation = new AgentProjects(defaultRegistry);
AgentProjectsFactory factory = new AgentProjectsFactory(address(implementation));

// Create clones (cheap deployments)
address clone = factory.createAgentProjects(
    agentRegistryAddress,  // Registry address (or zero for default)
    "My Custom Credential" // Name for this instance
);

// Use the clone
AgentProjects projects = AgentProjects(clone);
projects.setProject(agentId, "project-name", "My Project");

// Create deterministic clones
bytes32 salt = keccak256("my-unique-salt");
address predicted = factory.predictDeterministicAddress(salt);
address clone2 = factory.createAgentProjectsDeterministic(
    agentRegistryAddress,
    "Another Credential",
    salt
);
```

## Architecture

### Core Components

- **`ERCXXXXReviews`**: Abstract extension contract implementing the Reviews interface using Diamond Storage
- **`SmartCredential`**: Simple, open implementation with no authorization checks
- **`AgentProjects`**: Full-featured implementation with ERC-8048 metadata, ERC-8049 contract metadata, authorization, and updatable registry
- **`AgentProjectsFactory`**: Minimal clones factory (ERC-1167) for gas-efficient deployments

### Extensions

- **`ERC8048`**: Token-level metadata extension
- **`ERC8049`**: Contract-level metadata extension
- **`ERCXXXXReviews`**: Reviews extension with double mapping storage

### Interfaces

- **`IERCXXXXReviews`**: Reviews interface specification
- **`IERC8048`**: Token-level metadata interface specification
- **`IERC8049`**: Contract-level metadata interface specification
- **`IAgentProjects`**: Agent projects interface

## Development

### Build

```bash
forge build
```

### Test

```bash
forge test
```

### Deploy

Deploy implementation and factory:

```bash
# Set environment variables
export DEPLOYER_PRIVATE_KEY=<your_private_key>
export AGENT_REGISTRY_ADDRESS=<registry_address>  # Optional, defaults to 0xD0a769d82F6e0bf9d8913E570b6C823c8f7e9f40

# Deploy with verification
forge script script/Deploy.s.sol:Deploy \
  --rpc-url <RPC_URL> \
  --broadcast \
  --verify \
  --etherscan-api-key <ETHERSCAN_API_KEY>

# Optionally create a clone during deployment
export CREATE_CLONE=true
export CLONE_NAME="My Agent Projects"
forge script script/Deploy.s.sol:Deploy --rpc-url <RPC_URL> --broadcast
```

See [deployment reports](./deployments/) for latest deployments.

## Rationale

For the design rationale and technical details, please refer to [ERC-XXXX: Smart Credentials](https://eips.ethereum.org/EIPS/eip-XXXX).

### Factory Pattern

The `AgentProjectsFactory` uses the ERC-1167 minimal proxy pattern for gas-efficient deployments:

- **Implementation**: Deploy once, reuse many times
- **Clones**: ~10x cheaper to deploy than full contracts
- **Deterministic**: Optional deterministic addresses using CREATE2
- **Initialization**: Each clone is automatically initialized with registry, owner, and name
- **Tracking**: Factory tracks all clones and per-owner deployments

### Gas Savings

| Operation | Full Contract | Factory Clone | Savings |
|-----------|--------------|---------------|---------|
| First Deployment | ~2.1M gas | ~2.1M gas | 0% |
| Second Deployment | ~2.1M gas | ~200K gas | ~90% |
| Third+ Deployments | ~2.1M gas | ~200K gas | ~90% |

## Security Considerations

Smart Credential implementations should carefully consider:

- Authorization mechanisms for credential submission and updates
- Validation of offchain data when using ERC-3668
- Storage costs for onchain credential data
- Privacy implications of publicly accessible credentials

## Contributing

Contributions are welcome! Please ensure all tests pass and follow the existing code style.

## License

This project is licensed under the MIT License.

## Copyright

Copyright and related rights waived via CC0.
