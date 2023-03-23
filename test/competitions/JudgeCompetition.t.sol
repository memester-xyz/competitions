// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../BaseTest.sol";

import "../../src/competitions/JudgeCompetition.sol";
import {CompetitionV1} from "../../src/CompetitionV1.sol";

contract JudgeCompetitionTest is BaseTest {
    address immutable attacker = vm.addr(4);

    function setUp() public override {
        super.setUp();
    }

    function testCreateCompetition() public {
        vm.startPrank(judge);
        createCompetition();
        vm.stopPrank();
    }

    function testEnterCompetition() public {
        vm.startPrank(judge);
        (, uint256 competitionId,) = createCompetition();
        vm.stopPrank();
        enterCompetition(competitionId);
    }

    function testEndCompetition() public {
        vm.startPrank(judge);
        (, uint256 competitionId,) = createCompetition();
        vm.stopPrank();
        uint256 pubId = enterCompetition(competitionId);

        skip(1 days + 1 seconds);

        vm.startPrank(judge);
        endCompetition(competitionId, userOneProfileId, pubId);
        vm.stopPrank();

        PublicationId[] memory winners = lensCompetitionHub.winners(competitionId);
        assertEq(winners[0].profileId, userOneProfileId);
        assertEq(winners[0].pubId, pubId);
    }

    function testCannotInitJudgeCompetition() public {
        vm.startPrank(judge);
        (,, CompetitionV1 competition) = createCompetition();
        vm.stopPrank();

        vm.expectRevert("Initializable: contract is already initialized");
        competition.initialize(0, 0, address(0), block.timestamp + 1 days, "");
    }

    function testCannotEnterCompetitionIfFinished() public {
        vm.startPrank(judge);
        (, uint256 competitionId,) = createCompetition();
        vm.stopPrank();
        enterCompetition(competitionId);

        skip(1 days + 1 seconds);

        (DataTypes.CommentWithSigData memory commentWithSigData, bytes memory competitionEnterData) =
            enterCompetitionParams(1, 1);

        vm.expectRevert(BaseCompetitionV1.CompetitionFinished.selector);
        lensCompetitionHub.enterCompetition(competitionId, commentWithSigData, competitionEnterData);
    }

    function testCannotEnterCompetitionWithWrongPubIdPointed() public {
        vm.startPrank(judge);
        (, uint256 competitionId,) = createCompetition();
        (DataTypes.PostWithSigData memory postWithSigData, bytes memory competitionInitData) =
            createCompetitionParams(3, judge, judgeProfileId);

        vm.expectEmit(true, false, true, true, address(lensCompetitionHub));
        emit Events.CompetitionCreated(2, address(0), judgeProfileId, 2, block.timestamp + 1 days);
        lensCompetitionHub.createCompetition(
            address(judgeCompetition), block.timestamp + 1 days, postWithSigData, competitionInitData
        );
        vm.stopPrank();

        (DataTypes.CommentWithSigData memory commentWithSigData, bytes memory competitionEnterData) =
            enterCompetitionParams(1, 2);

        vm.expectRevert(LensCompetitionHub.IncorrectPublicationPointed.selector);
        lensCompetitionHub.enterCompetition(competitionId, commentWithSigData, competitionEnterData);
    }

    function testCannotEndCompetitionIfFinished() public {
        vm.startPrank(judge);
        (, uint256 competitionId,) = createCompetition();
        vm.stopPrank();
        uint256 pubId = enterCompetition(competitionId);

        skip(1 days + 1 seconds);

        vm.startPrank(judge);
        endCompetition(competitionId, userOneProfileId, pubId);

        bytes memory competitionEndData = endCompetitionParams(userOneProfileId, pubId);

        vm.expectRevert(BaseCompetitionV1.CompetitionFinished.selector);
        lensCompetitionHub.endCompetition(competitionId, competitionEndData);

        vm.stopPrank();
    }

    function testCannotEndCompetitionIfOngoing() public {
        vm.startPrank(judge);
        (, uint256 competitionId,) = createCompetition();
        vm.stopPrank();
        uint256 pubId = enterCompetition(competitionId);

        skip(0.5 days);

        vm.startPrank(judge);

        bytes memory competitionEndData = endCompetitionParams(userOneProfileId, pubId);

        vm.expectRevert(BaseCompetitionV1.CompetitionOngoing.selector);
        lensCompetitionHub.endCompetition(competitionId, competitionEndData);

        vm.stopPrank();
    }

    function testCannotEndCompetitionIfNotJudge() public {
        vm.startPrank(judge);
        (, uint256 competitionId,) = createCompetition();
        vm.stopPrank();
        uint256 pubId = enterCompetition(competitionId);

        skip(1 days + 1 seconds);

        vm.startPrank(attacker);

        bytes memory competitionEndData = endCompetitionParams(userOneProfileId, pubId);

        vm.expectRevert(BaseCompetitionV1.Unauthorized.selector);
        lensCompetitionHub.endCompetition(competitionId, competitionEndData);

        vm.stopPrank();
    }

    function testCannotEndCompetitionIfNoEntryFound() public {
        vm.startPrank(judge);
        (, uint256 competitionId,) = createCompetition();
        vm.stopPrank();
        uint256 pubId = enterCompetition(competitionId);

        skip(1 days + 1 seconds);

        vm.startPrank(judge);

        bytes memory competitionEndData = endCompetitionParams(userOneProfileId, pubId + 1);

        vm.expectRevert(BaseCompetitionV1.InvalidEntry.selector);
        lensCompetitionHub.endCompetition(competitionId, competitionEndData);

        vm.stopPrank();
    }

    function testCannotCheckWinnerIfNone() public {
        vm.startPrank(judge);
        (, uint256 competitionId,) = createCompetition();
        vm.stopPrank();
        enterCompetition(competitionId);

        skip(1 days + 1 seconds);

        PublicationId[] memory winners = lensCompetitionHub.winners(competitionId);
        assertEq(winners.length, 0);
    }

    function testCannotCallJudgeCompetitionDirectly() public {
        vm.startPrank(judge);
        (,, CompetitionV1 competition) = createCompetition();
        vm.stopPrank();

        vm.expectRevert(BaseCompetitionV1.Unauthorized.selector);
        competition.enter(0, 0, address(0), "");

        vm.expectRevert(BaseCompetitionV1.Unauthorized.selector);
        competition.end(address(0), "");
    }

    function testCannotCallCollected() public {
        vm.startPrank(judge);
        (,, CompetitionV1 competition) = createCompetition();
        vm.stopPrank();

        vm.expectRevert(BaseCompetitionV1.UnsupportedAction.selector);
        competition.collected(0, 0, address(0), "");
    }

    function testCannotCallMirrored() public {
        vm.startPrank(judge);
        (,, CompetitionV1 competition) = createCompetition();
        vm.stopPrank();

        vm.expectRevert(BaseCompetitionV1.UnsupportedAction.selector);
        competition.mirrored(0, 0, address(0), "");
    }

    /// HELPER FUNCTIONS

    function createCompetitionParams(uint256 key, address user, uint256 profileId)
        internal
        returns (DataTypes.PostWithSigData memory, bytes memory)
    {
        JudgeCompetitionInitData memory competitionInit = JudgeCompetitionInitData({judge: judge});
        bytes memory competitionInitData = abi.encode(competitionInit);

        uint256 sigNonce = lensHub.sigNonces(user);

        bytes32 hashedPostData = keccak256(
            abi.encode(
                LensTestUtils.POST_WITH_SIG_TYPEHASH,
                profileId,
                keccak256(bytes(LensTestUtils.MOCK_URI)),
                LensTestUtils.FREE_COLLECT_MODULE,
                keccak256(abi.encode(true)),
                address(0),
                keccak256(""),
                sigNonce,
                block.timestamp
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, LensTestUtils.calculateDigest(hashedPostData, address(lensHub)));
        DataTypes.EIP712Signature memory sig = DataTypes.EIP712Signature(v, r, s, block.timestamp);

        DataTypes.PostWithSigData memory postWithSigData = DataTypes.PostWithSigData({
            profileId: profileId,
            contentURI: LensTestUtils.MOCK_URI,
            collectModule: LensTestUtils.FREE_COLLECT_MODULE,
            collectModuleInitData: abi.encode(true),
            referenceModule: address(0),
            referenceModuleInitData: "",
            sig: sig
        });

        return (postWithSigData, competitionInitData);
    }

    function createCompetition() internal returns (uint256, uint256, CompetitionV1) {
        (DataTypes.PostWithSigData memory postWithSigData, bytes memory competitionInitData) =
            createCompetitionParams(3, judge, judgeProfileId);

        vm.expectEmit(true, false, true, true, address(lensCompetitionHub));
        emit Events.CompetitionCreated(1, address(0), judgeProfileId, 1, block.timestamp + 1 days);
        return lensCompetitionHub.createCompetition(
            address(judgeCompetition), block.timestamp + 1 days, postWithSigData, competitionInitData
        );
    }

    function enterCompetitionParams(uint256 key, uint256 pubIdPointed)
        internal
        returns (DataTypes.CommentWithSigData memory, bytes memory)
    {
        uint256 sigNonce = lensHub.sigNonces(userOne);

        bytes32 hashedCommentData = keccak256(
            abi.encode(
                LensTestUtils.COMMENT_WITH_SIG_TYPEHASH,
                userOneProfileId,
                keccak256(bytes(LensTestUtils.MOCK_URI)),
                judgeProfileId,
                pubIdPointed,
                keccak256(""),
                LensTestUtils.FREE_COLLECT_MODULE,
                keccak256(abi.encode(true)),
                address(0),
                keccak256(""),
                sigNonce,
                block.timestamp
            )
        );

        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(key, LensTestUtils.calculateDigest(hashedCommentData, address(lensHub)));
        DataTypes.EIP712Signature memory sig = DataTypes.EIP712Signature(v, r, s, block.timestamp);

        DataTypes.CommentWithSigData memory commentWithSigData = DataTypes.CommentWithSigData({
            profileId: userOneProfileId,
            contentURI: LensTestUtils.MOCK_URI,
            profileIdPointed: judgeProfileId,
            pubIdPointed: pubIdPointed,
            referenceModuleData: "",
            collectModule: LensTestUtils.FREE_COLLECT_MODULE,
            collectModuleInitData: abi.encode(true),
            referenceModule: address(0),
            referenceModuleInitData: "",
            sig: sig
        });

        return (commentWithSigData, "");
    }

    function enterCompetition(uint256 competitionId) internal returns (uint256 pubId) {
        (DataTypes.CommentWithSigData memory commentWithSigData, bytes memory competitionEnterData) =
            enterCompetitionParams(1, 1);

        vm.expectEmit(true, true, true, true, address(lensCompetitionHub));
        emit Events.EnteredCompetition(competitionId, userOneProfileId, 1);
        pubId = lensCompetitionHub.enterCompetition(competitionId, commentWithSigData, competitionEnterData);
    }

    function endCompetitionParams(uint256 profileId, uint256 pubId) internal pure returns (bytes memory) {
        JudgeCompetitionEndData memory competitionEnd = JudgeCompetitionEndData({profileId: profileId, pubId: pubId});
        return abi.encode(competitionEnd);
    }

    function endCompetition(uint256 competitionId, uint256 profileId, uint256 pubId) internal {
        bytes memory competitionEndData = endCompetitionParams(profileId, pubId);

        vm.expectEmit(true, true, true, true, address(lensCompetitionHub));
        emit Events.CompetitionEnded(competitionId, userOneProfileId, pubId);
        lensCompetitionHub.endCompetition(competitionId, competitionEndData);
    }
}
