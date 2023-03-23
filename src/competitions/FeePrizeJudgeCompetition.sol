// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

import {BaseCompetitionV1} from "../BaseCompetitionV1.sol";
import {ILensHub} from "../lens/ILensHub.sol";
import {PublicationId} from "../DataTypes.sol";

struct FeePrizeJudgeCompetitionInitData {
    address judge;
    IERC20 token;
    uint256 entryFee;
}

struct FeePrizeJudgeCompetitionEndData {
    uint256 profileId;
    uint256 pubId;
}

contract FeePrizeJudgeCompetition is BaseCompetitionV1 {
    using SafeERC20 for IERC20;

    address public judge;
    IERC20 public token;
    uint256 public entryFee;
    uint256 public prize;
    bool public refundMode;
    mapping(address => uint256) balances;

    FeePrizeJudgeCompetitionEndData private endData;

    constructor(ILensHub _lensHub, address _competitionHub) BaseCompetitionV1(_lensHub, _competitionHub) {}

    function initialize(
        uint256 profileId,
        uint256 pubId,
        address,
        uint256 _endTimestamp,
        bytes calldata competitionInitData
    ) external initializer {
        _onlyCompetitionHub();
        creationProfileId = profileId;
        creationPubId = pubId;
        endTimestamp = _endTimestamp;

        FeePrizeJudgeCompetitionInitData memory compeitionInit =
            abi.decode(competitionInitData, (FeePrizeJudgeCompetitionInitData));

        judge = compeitionInit.judge;
        token = compeitionInit.token;
        entryFee = compeitionInit.entryFee;
    }

    function enter(uint256 profileId, uint256 pubId, address, bytes calldata) external override {
        _onlyCompetitionHub();

        entries[profileId][pubId] = true;

        if ((endData.profileId != 0 && endData.pubId != 0) || block.timestamp > endTimestamp || refundMode) {
            revert CompetitionFinished();
        }

        address from = lensHub.ownerOf(profileId);

        token.safeTransferFrom(from, address(this), entryFee);
        balances[from] += entryFee;
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

        if ((endData.profileId != 0 && endData.pubId != 0) || refundMode) {
            revert CompetitionFinished();
        }

        FeePrizeJudgeCompetitionEndData memory compeitionEnd =
            abi.decode(competitionEndData, (FeePrizeJudgeCompetitionEndData));

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

        prize = token.balanceOf(address(this));

        address to = lensHub.ownerOf(profileId);

        token.safeTransfer(to, prize);

        endData = FeePrizeJudgeCompetitionEndData({profileId: profileId, pubId: pubId});

        publicationIds = new PublicationId[](1);
        publicationIds[0] = PublicationId({profileId: profileId, pubId: pubId});
    }

    function refund(address sender) external {
        _onlyCompetitionHub();

        if (endData.profileId != 0 && endData.pubId != 0) {
            revert CompetitionFinished();
        }

        if (block.timestamp <= endTimestamp) {
            revert CompetitionOngoing();
        }

        if (sender != judge && !refundMode) {
            revert Unauthorized();
        }

        if (sender == judge && !refundMode) {
            refundMode = true;
            return;
        }

        uint256 amount = balances[sender];
        if (amount > 0) {
            balances[sender] = 0;
            token.safeTransferFrom(address(this), sender, amount);
        } else {
            revert Unauthorized();
        }
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
