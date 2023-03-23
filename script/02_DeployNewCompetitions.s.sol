// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {ScriptReturns} from "./types/ScriptReturns.sol";

import {ILensHub} from "../src/lens/ILensHub.sol";
import {LensCompetitionHub} from "../src/LensCompetitionHub.sol";
import {JudgeCompetition} from "../src/competitions/JudgeCompetition.sol";
import {JudgeCompetitionMultipleWinners} from "../src/competitions/JudgeCompetitionMultipleWinners.sol";
import {FeePrizeJudgeCompetition} from "../src/competitions/FeePrizeJudgeCompetition.sol";
import {PrizeJudgeCompetition} from "../src/competitions/PrizeJudgeCompetition.sol";

contract DeployNewCompetitionsScript is Script {
    function run() public returns (ScriptReturns.Deploy_02 memory contracts) {
        ILensHub lensHub = ILensHub(vm.envAddress("LENS_HUB"));
        address lensCompetitionHub = vm.envAddress("LENS_COMPETITION_HUB");

        address deployer = vm.rememberKey(vm.envUint("DEPLOYER_PRIV_KEY"));

        vm.startBroadcast(deployer);

        contracts.feePrizeJudgeCompetition =
            new FeePrizeJudgeCompetition(lensHub, lensCompetitionHub);

        contracts.prizeJudgeCompetition = new PrizeJudgeCompetition(lensHub, lensCompetitionHub);

        vm.stopBroadcast();
    }
}
