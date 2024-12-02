# Makefile for deploying and testing smart contracts with Foundry

# Load environment variables from .env
include .env
export $(shell sed 's/=.*//' .env)

# Variables
FOUNDRY_CMD = forge
BUILD_CMD = forge build
TEST_CMD = forge test
SCRIPT_CMD = forge script
SCRIPT_FILE = script/DeployContractManager.s.sol
ANVIL_RPC_URL = http://127.0.0.1:8545

# Default target
all: build

# Phony targets
.PHONY: build test deploy-anvil deploy-sepolia deploy-mainnet clean help

# Build the project
build:
	$(BUILD_CMD)

# Run tests
test:
	$(TEST_CMD) --fork-url $(ANVIL_RPC_URL) --gas-report

# Deploy to Anvil
deploy-anvil:
	$(SCRIPT_CMD) $(SCRIPT_FILE) --broadcast --rpc-url $(ANVIL_RPC_URL) --private-key $(PRIVATE_KEY)

# Deploy to Sepolia
deploy-sepolia:
	$(SCRIPT_CMD) $(SCRIPT_FILE) --broadcast --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY)

# Deploy to Mainnet
deploy-mainnet:
	$(SCRIPT_CMD) $(SCRIPT_FILE) --broadcast --rpc-url $(MAINNET_RPC_URL) --private-key $(PRIVATE_KEY)

# Clean the project
clean:
	$(FOUNDRY_CMD) clean

# Help message
help:
	@echo "Usage:"
	@echo "  make build             Build the project"
	@echo "  make test              Run tests with fork and gas report"
	@echo "  make deploy-anvil      Deploy the contract to Anvil network"
	@echo "  make deploy-sepolia    Deploy the contract to Sepolia testnet"
	@echo "  make deploy-mainnet    Deploy the contract to Ethereum Mainnet"
	@echo "  make clean             Clean build artifacts"
	@echo "  make help              Show this help message"
