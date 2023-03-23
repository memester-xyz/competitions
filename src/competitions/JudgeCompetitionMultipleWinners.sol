// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {BaseCompetitionV1} from "../BaseCompetitionV1.sol";
import {ILensHub} from "../lens/ILensHub.sol";
import {PublicationId} from "../DataTypes.sol";

struct JudgeCompetitionMultipleWinnersInitData {
    address judge;
}

struct JudgeCompetitionMultipleWinnersEndData {
    PublicationId[] publicationIds;
}

contract JudgeCompetitionMultipleWinners is BaseCompetitionV1 {
    address public judge;

    JudgeCompetitionMultipleWinnersEndData private endData;

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

        JudgeCompetitionMultipleWinnersInitData memory compeitionInit =
            abi.decode(competitionInitData, (JudgeCompetitionMultipleWinnersInitData));

        judge = compeitionInit.judge;
    }

    function enter(uint256 profileId, uint256 pubId, address, bytes calldata) external override {
        _onlyCompetitionHub();

        entries[profileId][pubId] = true;

        if ((endData.publicationIds.length != 0) || block.timestamp > endTimestamp) {
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

        if (endData.publicationIds.length != 0) {
            revert CompetitionFinished();
        }

        JudgeCompetitionMultipleWinnersEndData memory compeitionEnd =
            abi.decode(competitionEndData, (JudgeCompetitionMultipleWinnersEndData));

        publicationIds = compeitionEnd.publicationIds;

        if (sender != judge) {
            revert Unauthorized();
        }

        if (block.timestamp <= endTimestamp) {
            revert CompetitionOngoing();
        }

        uint256 length = publicationIds.length;

        if (length == 0) {
            revert WinnerNotSelected();
        }

        for (uint256 i = 0; i < length;) {
            PublicationId memory publicationId = publicationIds[i];
            if (!entries[publicationId.profileId][publicationId.pubId]) {
                revert InvalidEntry();
            }

            endData.publicationIds.push(publicationId);

            unchecked {
                ++i;
            }
        }
    }

    function refund(address) external pure {
        revert UnsupportedAction();
    }

    function winners() external view override returns (PublicationId[] memory publicationIds) {
        return endData.publicationIds;
    }
}
