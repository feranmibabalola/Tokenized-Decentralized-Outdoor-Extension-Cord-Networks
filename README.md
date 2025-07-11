# Tokenized Decentralized Outdoor Extension Cord Networks

A blockchain-based system for managing community extension cord sharing with automated safety, weather protection, and usage optimization.

## Overview

This system tokenizes outdoor extension cords and manages their safe sharing through a decentralized network of smart contracts. Each contract handles specific aspects of cord management to ensure safety, efficiency, and community coordination.

## Smart Contracts

### 1. Safety Inspection Contract (`safety-inspection.clar`)
- Monitors cord condition and electrical hazard prevention
- Tracks inspection dates, safety ratings, and maintenance records
- Prevents usage of damaged or unsafe cords
- Manages inspector certifications and safety protocols

### 2. Weather Protection Contract (`weather-protection.clar`)
- Manages waterproof covering and storage during storms
- Monitors weather conditions and automatically triggers protection protocols
- Tracks storage locations and weatherproofing equipment
- Coordinates emergency cord retrieval during severe weather

### 3. Length Optimization Contract (`length-optimization.clar`)
- Coordinates appropriate cord sizing for different projects
- Optimizes cord allocation based on distance requirements
- Prevents voltage drop issues through intelligent matching
- Manages cord length inventory and availability

### 4. Sharing Schedule Contract (`sharing-schedule.clar`)
- Organizes community extension cord lending and availability
- Manages reservation system and usage calendars
- Handles conflict resolution and priority scheduling
- Tracks usage patterns and community needs

### 5. Overload Prevention Contract (`overload-prevention.clar`)
- Ensures safe electrical capacity limits and usage guidelines
- Monitors power consumption and prevents dangerous overloads
- Manages device compatibility and power requirements
- Provides real-time safety alerts and automatic shutoffs

## Features

- **Tokenized Cord Assets**: Each extension cord is represented as a unique token
- **Safety-First Design**: Multiple layers of safety checks and monitoring
- **Weather-Aware**: Automatic protection during adverse conditions
- **Community-Driven**: Decentralized sharing and governance
- **Smart Optimization**: Intelligent matching of cords to projects
- **Real-Time Monitoring**: Continuous safety and usage tracking

## Getting Started

### Prerequisites
- Stacks blockchain node
- Clarity development environment
- Web3 wallet for interaction

### Installation

1. Clone the repository
2. Deploy contracts to Stacks testnet
3. Initialize cord tokens and safety parameters
4. Set up community governance and inspector roles

### Usage

1. **Register Cords**: Add extension cords to the network with safety certifications
2. **Schedule Usage**: Reserve cords through the sharing schedule contract
3. **Monitor Safety**: Continuous monitoring through safety inspection contract
4. **Weather Protection**: Automatic activation during storms
5. **Optimize Allocation**: Smart matching based on project requirements

## Contract Interactions

Each contract operates independently while maintaining data consistency:

- Safety inspections must be current before cord usage
- Weather protection automatically overrides scheduling during storms
- Length optimization considers safety ratings and availability
- Sharing schedules respect safety and weather constraints
- Overload prevention provides real-time monitoring during usage

## Safety Features

- **Pre-Use Inspections**: Mandatory safety checks before each usage
- **Weather Monitoring**: Automatic protection during adverse conditions
- **Overload Protection**: Real-time monitoring and automatic shutoffs
- **Community Oversight**: Distributed safety responsibility
- **Emergency Protocols**: Rapid response to safety incidents

## Governance

The network operates through community governance:

- Inspector certification and management
- Safety protocol updates
- Emergency response procedures
- Community dispute resolution
- Network parameter adjustments

## Testing

Run the test suite with:

\`\`\`bash
npm test
\`\`\`

Tests cover:
- Contract deployment and initialization
- Safety inspection workflows
- Weather protection triggers
- Sharing schedule management
- Overload prevention mechanisms

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Submit pull request with detailed description

## License

MIT License - See LICENSE file for details

## Support

For technical support or questions:
- Create an issue in the repository
- Join the community Discord
- Consult the documentation wiki

## Roadmap

- [ ] Mobile app integration
- [ ] IoT sensor integration
- [ ] Advanced weather prediction
- [ ] Cross-network compatibility
- [ ] Enhanced governance features
