// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

import {LensTestUtils} from "./LensTestUtils.sol";

import {ScriptReturns} from "../script/types/ScriptReturns.sol";
import {DeployScript} from "../script/01_Deploy.s.sol";
import {DeployNewCompetitionsScript} from "../script/02_DeployNewCompetitions.s.sol";

import {Events} from "../src/Events.sol";
import {ILensHub} from "../src/lens/ILensHub.sol";
import {DataTypes} from "../src/lens/DataTypes.sol";
import {LensCompetitionHub} from "../src/LensCompetitionHub.sol";
import {JudgeCompetition} from "../src/competitions/JudgeCompetition.sol";
import {JudgeCompetitionMultipleWinners} from "../src/competitions/JudgeCompetitionMultipleWinners.sol";
import {FeePrizeJudgeCompetition} from "../src/competitions/FeePrizeJudgeCompetition.sol";
import {PrizeJudgeCompetition} from "../src/competitions/PrizeJudgeCompetition.sol";

abstract contract BaseTest is Test {
    address constant profileCreator = 0x1eeC6ecCaA4625da3Fa6Cd6339DBcc2418710E8a;
    IERC20 constant wmatic = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address immutable userOne = vm.addr(1);
    address immutable userTwo = vm.addr(2);
    address immutable judge = vm.addr(3);

    ScriptReturns.Deploy_01 internal contracts;
    ScriptReturns.Deploy_02 internal contracts2;

    ILensHub internal lensHub;
    address internal governance;

    LensCompetitionHub internal lensCompetitionHub;
    JudgeCompetition internal judgeCompetition;
    JudgeCompetitionMultipleWinners internal judgeCompetitionMultipleWinners;
    FeePrizeJudgeCompetition internal feePrizeJudgeCompetition;
    PrizeJudgeCompetition internal prizeJudgeCompetition;

    uint256 internal userOneProfileId;
    uint256 internal userTwoProfileId;
    uint256 internal judgeProfileId;

    function setUp() public virtual {
        lensHub = ILensHub(vm.envAddress("LENS_HUB"));
        governance = vm.envAddress("GOVERNANCE");

        vm.createSelectFork("polygon");

        vm.label(userOne, "userOne");
        vm.label(userTwo, "userTwo");
        vm.label(judge, "judge");

        contracts = new DeployScript().run();
        lensCompetitionHub = contracts.lensCompetitionHub;
        vm.setEnv("LENS_COMPETITION_HUB", vm.toString(address(lensCompetitionHub)));
        contracts2 = new DeployNewCompetitionsScript().run();

        lensCompetitionHub = contracts.lensCompetitionHub;
        judgeCompetition = contracts.judgeCompetition;
        judgeCompetitionMultipleWinners = contracts.judgeCompetitionMultipleWinners;
        feePrizeJudgeCompetition = contracts2.feePrizeJudgeCompetition;
        prizeJudgeCompetition = contracts2.prizeJudgeCompetition;

        vm.startPrank(governance);
        contracts.lensCompetitionHub.whitelistCompetition(address(judgeCompetition), true);
        contracts.lensCompetitionHub.whitelistCompetition(address(judgeCompetitionMultipleWinners), true);
        contracts.lensCompetitionHub.whitelistCompetition(address(feePrizeJudgeCompetition), true);
        contracts.lensCompetitionHub.whitelistCompetition(address(prizeJudgeCompetition), true);
        vm.stopPrank();

        vm.startPrank(profileCreator);
        userOneProfileId = lensHub.createProfile(
            DataTypes.CreateProfileData({
                to: userOne,
                handle: "userone.memester",
                imageURI: LensTestUtils.MOCK_PROFILE_URI,
                followModule: address(0),
                followModuleInitData: "",
                followNFTURI: LensTestUtils.MOCK_FOLLOW_NFT_URI
            })
        );
        userTwoProfileId = lensHub.createProfile(
            DataTypes.CreateProfileData({
                to: userTwo,
                handle: "usertwo.memester",
                imageURI: LensTestUtils.MOCK_PROFILE_URI,
                followModule: address(0),
                followModuleInitData: "",
                followNFTURI: LensTestUtils.MOCK_FOLLOW_NFT_URI
            })
        );
        judgeProfileId = lensHub.createProfile(
            DataTypes.CreateProfileData({
                to: judge,
                handle: "judge.memester",
                imageURI: LensTestUtils.MOCK_PROFILE_URI,
                followModule: address(0),
                followModuleInitData: "",
                followNFTURI: LensTestUtils.MOCK_FOLLOW_NFT_URI
            })
        );
        vm.stopPrank();

        // WMATIC whale
        vm.startPrank(0x6e7a5FAFcec6BB1e78bAE2A1F0B612012BF14827);
        wmatic.transfer(userOne, 10 ether);
        wmatic.transfer(userTwo, 10 ether);
        wmatic.transfer(judge, 10 ether);
        vm.stopPrank();
    }
}
