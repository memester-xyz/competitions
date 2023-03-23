// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

import {ScriptReturns} from "./types/ScriptReturns.sol";

import {DeployScript} from "./01_Deploy.s.sol";

contract LocalScript is Script {
    function run() public {
        address deployer = vm.rememberKey(vm.envUint("DEPLOYER_PRIV_KEY"));

        vm.setEnv("LENS_HUB", vm.envString("MUMBAI_LENS_HUB"));
        vm.setEnv("GOVERNANCE", Strings.toHexString(deployer));

        ScriptReturns.Deploy_01 memory contracts = new DeployScript().run();

        vm.startBroadcast(deployer);
        contracts.lensCompetitionHub.whitelistCompetition(address(contracts.judgeCompetition), true);
        contracts.lensCompetitionHub.whitelistCompetition(address(contracts.judgeCompetitionMultipleWinners), true);
        vm.stopBroadcast();

        console2.log("LensCompetitionHub deployed at: ", address(contracts.lensCompetitionHub));
        console2.log("JudgeCompetition deployed at: ", address(contracts.judgeCompetition));
        console2.log(
            "JudgeCompetitionMultipleWinners deployed at: ", address(contracts.judgeCompetitionMultipleWinners)
        );
    }
}
