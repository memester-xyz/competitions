// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LensCompetitionHub} from "../../src/LensCompetitionHub.sol";
import {JudgeCompetition} from "../../src/competitions/JudgeCompetition.sol";
import {JudgeCompetitionMultipleWinners} from "../../src/competitions/JudgeCompetitionMultipleWinners.sol";
import {FeePrizeJudgeCompetition} from "../../src/competitions/FeePrizeJudgeCompetition.sol";
import {PrizeJudgeCompetition} from "../../src/competitions/PrizeJudgeCompetition.sol";

library ScriptReturns {
    struct Deploy_01 {
        LensCompetitionHub lensCompetitionHubImpl;
        LensCompetitionHub lensCompetitionHub;
        JudgeCompetition judgeCompetition;
        JudgeCompetitionMultipleWinners judgeCompetitionMultipleWinners;
        FeePrizeJudgeCompetition feePrizeJudgeCompetition;
        PrizeJudgeCompetition prizeJudgeCompetition;
    }
}
