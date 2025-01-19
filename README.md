# Hyperledger Fabric Network Setup with Docker

This repository contains scripts and configurations to set up and deploy a Hyperledger Fabric network using Docker. The network consists of peers, orderers, and a Certificate Authority (CA), enabling the implementation of smart contracts (chaincode) and interaction with the network.

## Prerequisites
- **Docker**: Ensure Docker is installed and running on your machine. You can download it from [Docker's official website](https://www.docker.com/get-started).
- **Docker Compose**: Make sure Docker Compose is installed. It usually comes with Docker Desktop.
- **Hyperledger Fabric binaries** (orderer, peer, osnadmin, fabric-ca-server, fabric-ca-client ...) 

## Setup
1. **Clone this repository** at `/opt/fabric`. Run:
   ```bash
   git clone /opt/fabric https://github.com/mariecarvalho/fabric-network --depth 1