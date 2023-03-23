// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {ScriptReturns} from "./types/ScriptReturns.sol";

import {ILensHub} from "../src/lens/ILensHub.sol";
import {LensCompetitionHub} from "../src/LensCompetitionHub.sol";
import {JudgeCompetition} from "../src/competitions/JudgeCompetition.sol";
import {JudgeCompetitionMultipleWinners} from "../src/competitions/JudgeCompetitionMultipleWinners.sol";

contract DeployScript is Script {
    function run() public returns (ScriptReturns.Deploy_01 memory contracts) {
        ILensHub lensHub = ILensHub(vm.envAddress("LENS_HUB"));
        address governance = vm.envAddress("GOVERNANCE");

        address deployer = vm.rememberKey(vm.envUint("DEPLOYER_PRIV_KEY"));

        vm.startBroadcast(deployer);

        contracts.lensCompetitionHubImpl = new LensCompetitionHub();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(contracts.lensCompetitionHubImpl),
            abi.encodeWithSelector(
                LensCompetitionHub.intialize.selector,
                lensHub,
                governance
            )
        );

        contracts.lensCompetitionHub = LensCompetitionHub(address(proxy));

        contracts.judgeCompetition = new JudgeCompetition(lensHub, address(contracts.lensCompetitionHub));

        contracts.judgeCompetitionMultipleWinners =
            new JudgeCompetitionMultipleWinners(lensHub, address(contracts.lensCompetitionHub));

        vm.stopBroadcast();
    }
}
