# Tokenized Decentralized Music Rights Management Platform

A comprehensive blockchain-based platform for managing music rights, royalties, and collaborations using Clarity smart contracts on the Stacks blockchain.

## Overview

This platform provides a decentralized solution for music rights management, enabling artists, producers, and rights holders to:

- Register original music compositions with immutable proof of creation
- Track performance metrics across multiple platforms
- Calculate and distribute royalties fairly among contributors
- Manage sampling permissions and licensing
- Handle multi-artist collaboration agreements

## Smart Contracts

### 1. Composition Registration Contract (`composition-registry.clar`)
- Records original music creation with metadata
- Establishes ownership and creation timestamps
- Manages composition details and rights information

### 2. Performance Tracking Contract (`performance-tracker.clar`)
- Monitors song plays across different platforms
- Records streaming data and performance metrics
- Maintains historical performance records

### 3. Royalty Calculation Contract (`royalty-calculator.clar`)
- Computes fair compensation for all contributors
- Handles percentage-based revenue distribution
- Manages royalty payment records

### 4. Sampling Permission Contract (`sampling-permissions.clar`)
- Manages music excerpt usage rights
- Handles licensing requests and approvals
- Tracks sampling usage and payments

### 5. Collaboration Agreement Contract (`collaboration-agreements.clar`)
- Handles multi-artist project terms
- Manages contributor roles and revenue splits
- Maintains collaboration history and agreements

## Features

- **Immutable Records**: All registrations and agreements are permanently recorded on the blockchain
- **Transparent Royalties**: Fair and transparent royalty calculations and distributions
- **Decentralized Governance**: No central authority controls the platform
- **Multi-Platform Support**: Compatible with various streaming and distribution platforms
- **Flexible Licensing**: Customizable licensing terms for sampling and collaborations

## Getting Started

### Prerequisites
- Stacks blockchain node access
- Clarity development environment
- Basic understanding of smart contracts

### Installation

1. Clone the repository
2. Deploy contracts to Stacks testnet/mainnet
3. Interact with contracts using Stacks CLI or web interface

### Usage

1. **Register Composition**: Artists register their original works
2. **Track Performance**: Platforms report play counts and metrics
3. **Calculate Royalties**: System automatically computes earnings
4. **Request Sampling**: Artists request permission to sample existing works
5. **Create Collaborations**: Multiple artists establish project agreements

## Testing

Tests are written using Vitest and cover all contract functionality:

\`\`\`bash
npm test
\`\`\`

## Contract Interactions

Each contract provides specific functions for different aspects of music rights management. Refer to individual contract files for detailed function documentation.

## Security Considerations

- All contracts include proper access controls
- Input validation prevents malicious data
- Immutable records ensure data integrity
- No cross-contract dependencies for security isolation

## License

This project is open source and available under the MIT License.
