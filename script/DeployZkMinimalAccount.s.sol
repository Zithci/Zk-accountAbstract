// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {ZkMinimalAccount} from "../src/ZkMinimalAccount.sol";

contract DeployZkMinimalAccount is Script {
    function run() external returns (ZkMinimalAccount) {
        // vm.startBroadcast();
        ZkMinimalAccount minimalAccount = new ZkMinimalAccount();
        // vm.stopBroadcast();
        return minimalAccount;
    }
}
