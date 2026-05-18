# ZkMinimalAccount: Mastery Journey into zkSync Native AA

A production-grade, hardcore implementation of a **Native Account Abstraction** wallet on zkSync Era, built with **Foundry-zksync**.

## 🚀 The Big Picture

While standard Ethereum (L1) uses ERC-4337 as a wrapper, zkSync Era features **Native Account Abstraction**. This means every account is a smart contract by default. This project dives deep into the EraVM internals to build a secure, programmable, and highly efficient wallet from the ground up.

## 🧠 Technical Highlights

- **Native AA Architecture**: Direct interaction with the zkSync **Bootloader** (Kernel) and system contracts.
- **Nonce Management**: Manual integration with the `NonceHolder` system contract to prevent replay attacks.
- **EIP-712 Compliance**: Advanced signature validation using `ECDSA` and `MessageHashUtils` aligned with zkSync standards.
- **Raw Assembly Execution**: Utilizing Yul `assembly` for "Raw Forwarding" to ensure data purity and maximum gas efficiency.
- **Emergency Path**: An `onlyOwner` direct execution route (`executeTransactionFromOutside`) for manual control.

## 🛠 Hardcore Hurdles Overcome

During development, we conquered several "Final Boss" level errors:
- **Stack Too Deep**: Resolved by maximizing the Solidity optimizer and fine-tuning `foundry.toml`.
- **Memory vs Calldata**: Mastered the `this.function()` trick to force external calls for required memory-to-calldata conversions.
- **Precompile 0xFFF6**: Implemented manual hashing workarounds to ensure tests pass in local environments where system precompiles might be uninitialized.

## 📦 Tech Stack

- **Framework**: Foundry-zksync (zksolc)
- **Language**: Solidity 0.8.24
- **Libraries**: OpenZeppelin, Era-Contracts

## 🧪 Quick Start

### 1. Prerequisites
Install the specialized zkSync toolchain:
```bash
curl -L https://raw.githubusercontent.com/matter-labs/foundry-zksync/main/install.sh | bash
source ~/.zshrc
foundryup-zksync
```

### 2. Build
```bash
forge build --zksync
```

### 3. Test (The Battlefield)
Simulate the Bootloader environment with high-security flags:
```bash
forge test --zksync --system-mode -vvvv
```

## 📜 License
MIT

---
*Built with Pure Mathematical Certainty & Engineering Heart by Riel.*
