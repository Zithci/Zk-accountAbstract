// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

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
        // ARRANGE
        Transaction memory transaction;
        transaction.txType = 113; // EIP-712
        transaction.from = uint256(uint160(address(minimalAccount)));
        transaction.nonce = 0;
        transaction.to = uint256(uint160(address(0x123)));
        transaction.value = 0;
        transaction.data = "";

        // PAKE HASH MANUAL UNTUK TESTING (Menghindari error precompile di lingkungan lokal)
        bytes32 mockHash = keccak256("zk-minimal-account-mock-hash");
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(mockHash);

        // Tanda tangan di atas hash yang sudah dibungkus
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, ethSignedMessageHash);
        transaction.signature = abi.encodePacked(r, s, v);

        // ACT
        vm.prank(BOOTLOADER_FORMAL_ADDRESS);
        // Kita kirim ethSignedMessageHash sebagai suggested hash
        bytes4 magic = minimalAccount.validateTransaction(mockHash, ethSignedMessageHash, transaction);

        // ASSERT
        assertEq(magic, ACCOUNT_VALIDATION_SUCCESS_MAGIC);
    }

    function testZkOwnerCanExecute() public {
        // ARRANGE
        address dest = makeAddr("destination");
        uint256 value = 1 ether;
        vm.deal(address(minimalAccount), value);

        Transaction memory transaction;
        transaction.to = uint256(uint160(dest));
        transaction.value = value;
        transaction.data = "";

        // ACT
        vm.prank(owner);
        minimalAccount.executeTransactionFromOutside(transaction);

        // ASSERT
        assertEq(dest.balance, value);
    }

    // HELPER JEMBATAN
    function _getTxHash(Transaction calldata _transaction) public view returns (bytes32) {
        return TransactionHelper.encodeHash(_transaction);
    }
}
