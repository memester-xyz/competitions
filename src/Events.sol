// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library Events {
    event CompetitionCreated(
        uint256 indexed competitionId,
        address indexed competition,
        uint256 indexed profileId,
        uint256 pubId,
        uint256 endTimestamp
    );

    event EnteredCompetition(uint256 indexed competitionId, uint256 indexed profileId, uint256 indexed pubId);

    event CompetitionEntryCollected(uint256 indexed competitionId, uint256 indexed profileId, uint256 indexed pubId);

    event CompetitionEntryMirrored(uint256 indexed competitionId, uint256 indexed profileId, uint256 indexed pubId);

    event CompetitionEnded(
        uint256 indexed competitionId, uint256 indexed winningProfileId, uint256 indexed winningPubId
    );

    event CompetitionRefunded(uint256 indexed competitionId, address indexed refundee);
}
