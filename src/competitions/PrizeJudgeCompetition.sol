// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

import {BaseCompetitionV1} from "../BaseCompetitionV1.sol";
import {ILensHub} from "../lens/ILensHub.sol";
import {RefundBehavior, PublicationId} from "../DataTypes.sol";

struct PrizeJudgeCompetitionInitData {
    address judge;
    IERC20 token;
    uint256 prize;
    RefundBehavior refundBehavior;
}

struct PrizeJudgeCompetitionEndData {
    uint256 profileId;
    uint256 pubId;
}

contract PrizeJudgeCompetition is BaseCompetitionV1 {
    using SafeERC20 for IERC20;

    address public judge;
    IERC20 public token;
    uint256 public prize;
    bool public anyEntries;
    bool public refunded;

    PrizeJudgeCompetitionEndData private endData;

    constructor(ILensHub _lensHub, address _competitionHub) BaseCompetitionV1(_lensHub, _competitionHub) {}

    function initialize(
        uint256 profileId,
        uint256 pubId,
        address sender,
        uint256 _endTimestamp,
        bytes calldata competitionInitData
    ) external initializer {
        _onlyCompetitionHub();
        creationProfileId = profileId;
        creationPubId = pubId;
        endTimestamp = _endTimestamp;

        PrizeJudgeCompetitionInitData memory compeitionInit =
            abi.decode(competitionInitData, (PrizeJudgeCompetitionInitData));

        judge = compeitionInit.judge;
        token = compeitionInit.token;
        prize = compeitionInit.prize;
        refundBehavior = compeitionInit.refundBehavior;

        token.safeTransferFrom(sender, address(this), prize);
    }

    function enter(uint256 profileId, uint256 pubId, address, bytes calldata) external override {
        _onlyCompetitionHub();

        entries[profileId][pubId] = true;
        anyEntries = true;

        if ((endData.profileId != 0 && endData.pubId != 0) || block.timestamp > endTimestamp || refunded) {
            revert CompetitionFinished();
        }
    }

    function collected(uint256, uint256, address, bytes calldata) external pure override {
        revert UnsupportedAction();
    }

    function mirrored(uint256, uint256, address, bytes calldata) external pure override {
        revert UnsupportedAction();
    }

    function end(address sender, bytes calldata competitionEndData)
        external
        override
        returns (PublicationId[] memory publicationIds)
    {
        _onlyCompetitionHub();

        if ((endData.profileId != 0 && endData.pubId != 0) || refunded) {
            revert CompetitionFinished();
        }

        PrizeJudgeCompetitionEndData memory compeitionEnd =
            abi.decode(competitionEndData, (PrizeJudgeCompetitionEndData));

        uint256 profileId = compeitionEnd.profileId;
        uint256 pubId = compeitionEnd.pubId;

        if (sender != judge) {
            revert Unauthorized();
        }

        if (block.timestamp <= endTimestamp) {
            revert CompetitionOngoing();
        }

        if (!entries[profileId][pubId]) {
            revert InvalidEntry();
        }

        address to = lensHub.ownerOf(profileId);

        token.safeTransfer(to, prize);

        endData = PrizeJudgeCompetitionEndData({profileId: profileId, pubId: pubId});

        publicationIds = new PublicationId[](1);
        publicationIds[0] = PublicationId({profileId: profileId, pubId: pubId});
    }

    function refund(address sender) external {
        _onlyCompetitionHub();

        if ((endData.profileId != 0 && endData.pubId != 0) || refunded) {
            revert CompetitionFinished();
        }

        if (block.timestamp <= endTimestamp) {
            revert CompetitionOngoing();
        }

        if (sender != judge) {
            revert Unauthorized();
        }

        if (refundBehavior == RefundBehavior.None) {
            revert RefundDisabled();
        } else if (refundBehavior == RefundBehavior.Always) {
            token.safeTransfer(judge, prize);
        } else if (refundBehavior == RefundBehavior.IfNoEntries) {
            if (!anyEntries) {
                token.safeTransfer(judge, prize);
            } else {
                revert UnsupportedAction();
            }
        }

        refunded = true;
    }

    function winners() external view override returns (PublicationId[] memory publicationIds) {
        if (endData.profileId == 0 && endData.pubId == 0) {
            publicationIds = new PublicationId[](0);
        } else {
            publicationIds = new PublicationId[](1);
            publicationIds[0] = PublicationId({profileId: endData.profileId, pubId: endData.pubId});
        }
    }
}
