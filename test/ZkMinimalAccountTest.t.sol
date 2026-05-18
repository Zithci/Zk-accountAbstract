// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*
IMPORT
 */
import {Test} from "forge-std/Test.sol";
import {ZkMinimalAccount} from "../src/ZkMinimalAccount.sol";
import {DeployZkMinimalAccount} from "../script/DeployZkMinimalAccount.s.sol";
import {
    Transaction,
    TransactionHelper
} from "foundry-era-contracts/system-contracts/contracts/libraries/TransactionHelper.sol";
import {
    ACCOUNT_VALIDATION_SUCCESS_MAGIC
} from "foundry-era-contracts/system-contracts/contracts/interfaces/IAccount.sol";
import {BOOTLOADER_FORMAL_ADDRESS} from "foundry-era-contracts/system-contracts/contracts/Constants.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract ZkMinimalAccountTest is Test {
    using MessageHashUtils for bytes32;
    using TransactionHelper for Transaction;

    /* state */
    ZkMinimalAccount public minimalAccount;
    address public owner;
    uint256 public ownerKey;

    function setUp() public {
        (owner, ownerKey) = makeAddrAndKey("owner");

        vm.prank(owner);
        DeployZkMinimalAccount deployer = new DeployZkMinimalAccount();
        minimalAccount = deployer.run();

        // PENTING: Pindahin ownership
        vm.prank(minimalAccount.owner());
        minimalAccount.transferOwnership(owner);
    }

    function testZkOwnerCanSignAndValidate() public {
        /* lib component  / raw materials form*/
        Transaction memory transaction;
        transaction.txType = 113; // EIP-712
        transaction.from = uint256(uint160(address(minimalAccount)));
        transaction.nonce = 0;
        transaction.to = uint256(uint160(address(0x123)));
        transaction.value = 0;
        transaction.data = "";

        // PAKE HASH MANUAL BIAR GAK KENA PRECOMPILE ERROR 0xFFF6
        bytes32 txHash = keccak256("mock-tx-zk"); // hashing the tx
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(txHash); //
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, ethSignedMessageHash);
        transaction.signature = abi.encodePacked(r, s, v);

        vm.prank(BOOTLOADER_FORMAL_ADDRESS); /* pretend to big boss */
        bytes4 magic = minimalAccount.validateTransaction(txHash, txHash, transaction);
        /*knock the door  */

        assertEq(magic, ACCOUNT_VALIDATION_SUCCESS_MAGIC); /*verifying the address */
    }

    function testZkOwnerCanExecute() public {
        /* arrange */
        address dest = makeAddr("destination"); /* prepare the receiver] */
        uint256 value = 1 ether; // tx value
        vm.deal(address(minimalAccount), value); /* give wallet some balance */
        Transaction memory transaction; /* prepare the briefcase */
        transaction.to = uint256(uint160(dest));
        transaction.value = value;
        transaction.data = "";

        /* manipulate the owner + exe tx */
        vm.prank(owner);
        minimalAccount.executeTransactionFromOutside(transaction);

        /* verifyingx */
        assertEq(dest.balance, value);
    }

    // Kita hapus helper jembatan karena bikin ribet urusan precompile
}
