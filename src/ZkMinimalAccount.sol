// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {
    IAccount,
    ACCOUNT_VALIDATION_SUCCESS_MAGIC
} from "foundry-era-contracts/system-contracts/contracts/interfaces/IAccount.sol";
import {
    Transaction,
    TransactionHelper
} from "foundry-era-contracts/system-contracts/contracts/libraries/TransactionHelper.sol";
import {
    SystemContractsCaller
} from "foundry-era-contracts/system-contracts/contracts/libraries/SystemContractsCaller.sol";
import {
    NONCE_HOLDER_SYSTEM_CONTRACT,
    BOOTLOADER_FORMAL_ADDRESS,
    DEPLOYER_SYSTEM_CONTRACT
} from "foundry-era-contracts/system-contracts/contracts/Constants.sol";
import {INonceHolder} from "foundry-era-contracts/system-contracts/contracts/interfaces/INonceHolder.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title ZkMinimalAccount
 * @author Riel (Mastering Web3)
 * @notice A minimal native Account Abstraction wallet for zkSync Era.
 */
contract ZkMinimalAccount is IAccount, Ownable {
    using TransactionHelper for Transaction;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ZkMinimalAccount__NotBootloader();
    error ZkMinimalAccount__NotBootloaderOrOwner();
    error ZkMinimalAccount__ExecutionFailed();
    error ZkMinimalAccount__FailedToPayBootloader();
    error ZkMinimalAccount__InvalidSignature();

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Restricts call to only the zkSync Bootloader.
    modifier requireFromBootloader() {
        if (msg.sender != address(BOOTLOADER_FORMAL_ADDRESS)) {
            revert ZkMinimalAccount__NotBootloader();
        }
        _;
    }

    /// @dev Allows the Bootloader or the contract Owner to call the function.
    modifier requireFromBootloaderOrOwner() {
        if (msg.sender != address(BOOTLOADER_FORMAL_ADDRESS) && msg.sender != owner()) {
            revert ZkMinimalAccount__NotBootloaderOrOwner();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor() Ownable(msg.sender) {}

    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Validates a transaction. Called by the Bootloader.
     * @param _suggestedSignedHash The hash recommended for signature verification.
     * @param _transaction The full transaction data structure.
     * @return magic The validation success magic number.
     */
    function validateTransaction(
        bytes32, /* _txHash */
        bytes32 _suggestedSignedHash,
        Transaction calldata _transaction
    ) external payable requireFromBootloader returns (bytes4 magic) {
        return _validateTransaction(_suggestedSignedHash, _transaction);
    }

    /**
     * @notice Executes a transaction. Called by the Bootloader or Owner.
     * @param _transaction The transaction to be executed.
     */
    function executeTransaction(
        bytes32, /* _txHash */
        bytes32, /* _suggestedSignedHash */
        Transaction calldata _transaction
    ) external payable requireFromBootloaderOrOwner {
        _executeTransaction(_transaction);
    }

    /**
     * @notice Emergency/Direct execution path for the owner.
     */
    function executeTransactionFromOutside(Transaction calldata _transaction) external payable onlyOwner {
        _executeTransaction(_transaction);
    }

    /**
     * @notice Pays the transaction gas fee to the Bootloader.
     */
    function payForTransaction(
        bytes32, /* _txHash */
        bytes32, /* _suggestedSignedHash */
        Transaction calldata _transaction
    ) external payable requireFromBootloader {
        bool success = _transaction.payToTheBootloader();
        if (!success) {
            revert ZkMinimalAccount__FailedToPayBootloader();
        }
    }

    /**
     * @notice Required for paymaster support (currently placeholder).
     */
    function prepareForPaymaster(
        bytes32, /* _txHash */
        bytes32, /* _suggestedSignedHash */
        Transaction calldata _transaction
    ) external payable requireFromBootloader {
        // Future paymaster implementation
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Core logic for transaction validation: Nonce update + Signature check.
     */
    function _validateTransaction(bytes32 _suggestedSignedHash, Transaction calldata _transaction)
        internal
        returns (bytes4 magic)
    {
        // 1. Report and increment nonce in the system contract
        SystemContractsCaller.systemCallWithPropagatedRevert(
            uint32(gasleft()), // Gas budget
            address(NONCE_HOLDER_SYSTEM_CONTRACT), // System Police
            0, // msg.value
            abi.encodeCall(INonceHolder.incrementMinNonceIfEquals, (_transaction.nonce)) // Message
        );

        // 2. Recover signer from signature using ECDSA
        // We use _suggestedSignedHash directly as it is already formatted by the bootloader
        address signer = ECDSA.recover(_suggestedSignedHash, _transaction.signature);

        // 3. Final authorization decision
        if (signer != owner()) {
            return bytes4(0);
        }
        return ACCOUNT_VALIDATION_SUCCESS_MAGIC;
    }

    /**
     * @dev Low-level transaction execution handling.
     */
    function _executeTransaction(Transaction calldata _transaction) internal {
        address to = address(uint160(_transaction.to));
        uint128 value = uint128(_transaction.value);
        bytes calldata data = _transaction.data;

        // Handle deployment through the ContractDeployer system contract
        if (to == address(DEPLOYER_SYSTEM_CONTRACT)) {
            uint32 gas = uint32(gasleft());
            SystemContractsCaller.systemCallWithPropagatedRevert(gas, to, value, data);
        } else {
            // Standard call using inline assembly for raw forwarding
            bool success;
            assembly {
                success := call(gas(), to, value, add(data.offset, 0), data.length, 0, 0)
            }
            if (!success) {
                revert ZkMinimalAccount__ExecutionFailed();
            }
        }
    }
}
