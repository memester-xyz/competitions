// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {BaseCompetitionV1} from "../BaseCompetitionV1.sol";
import {ILensHub} from "../lens/ILensHub.sol";
import {PublicationId} from "../DataTypes.sol";

struct JudgeCompetitionInitData {
    address judge;
}

struct JudgeCompetitionEndData {
    uint256 profileId;
    uint256 pubId;
}

contract JudgeCompetition is BaseCompetitionV1 {
    address public judge;

    JudgeCompetitionEndData private endData;

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

        JudgeCompetitionInitData memory compeitionInit = abi.decode(competitionInitData, (JudgeCompetitionInitData));

        judge = compeitionInit.judge;
    }

    function enter(uint256 profileId, uint256 pubId, address, bytes calldata) external override {
        _onlyCompetitionHub();

        entries[profileId][pubId] = true;

        if ((endData.profileId != 0 && endData.pubId != 0) || block.timestamp > endTimestamp) {
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

        if (endData.profileId != 0 && endData.pubId != 0) {
            revert CompetitionFinished();
        }

        JudgeCompetitionEndData memory compeitionEnd = abi.decode(competitionEndData, (JudgeCompetitionEndData));

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

        endData = JudgeCompetitionEndData({profileId: profileId, pubId: pubId});

        publicationIds = new PublicationId[](1);
        publicationIds[0] = PublicationId({profileId: profileId, pubId: pubId});
    }

    function refund(address) external pure {
        revert UnsupportedAction();
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
