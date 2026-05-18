# zkSync Native Account Abstraction - Minimal Account

A minimal implementation of a Native Account Abstraction wallet on zkSync Era, built with Foundry-zksync.

## 🚀 Overview

Unlike Ethereum (L1), where Account Abstraction is implemented via ERC-4337 as an extra layer, zkSync Era features **Native Account Abstraction**. Every account on zkSync is effectively a smart contract. This project demonstrates a minimal AA wallet that implements:

- **Signature Validation**: Securely verifying owner signatures using ECDSA.
- **Nonce Management**: Interacting with zkSync's `NonceHolder` system contract via `SystemContractsCaller`.
- **Transaction Execution**: Handling both standard calls and contract deployments.
- **Direct Access**: An emergency execution path for the owner.

## 🛠 Prerequisites

To work with this project, you need the specialized Foundry toolchain for zkSync:

```bash
# Install foundry-zksync
curl -L https://raw.githubusercontent.com/matter-labs/foundry-zksync/main/install.sh | bash
source ~/.zshrc
foundryup-zksync
```

## 🧪 Testing

The test suite simulates the zkSync Bootloader environment using `--system-mode`.

```bash
# Clean, Build and Run all tests
forge clean && forge build --zksync && forge test --zksync --system-mode
```

### Key Learning Points during Development:
- **Precompile Workarounds**: Handled `0xFFF6` hashing precompile issues in local environments by using manual hashing in tests.
- **Memory vs Calldata**: Utilized the `this.function()` trick to force external calls for memory-to-calldata conversion.
- **System Mode**: Used `--system-mode` to allow `vm.prank` into restricted system addresses.

## 🏗 Project Structure

- `src/ZkMinimalAccount.sol`: The core AA contract.
- `script/DeployZkMinimalAccount.s.sol`: Deployment automation script.
- `test/ZkMinimalAccountTest.t.sol`: Comprehensive test suite.

## 📜 License
MIT
