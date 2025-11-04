// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MicroSubs.sol";

contract DeployScript is Script {
    function run() external returns (MicroSubs) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        MicroSubs microSubs = new MicroSubs();
        console.log("MicroSubs deployed at:", address(microSubs));
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        
        vm.stopBroadcast();
        
        return microSubs;
    }
}
