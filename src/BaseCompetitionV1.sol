// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Initializable} from "openzeppelin-contracts/proxy/utils/Initializable.sol";

import {CompetitionV1} from "./CompetitionV1.sol";
import {ILensHub} from "./lens/ILensHub.sol";
import {RefundBehavior} from "./DataTypes.sol";

abstract contract BaseCompetitionV1 is CompetitionV1, Initializable {
    ILensHub immutable lensHub;
    address immutable competitionHub;

    uint256 internal creationProfileId;
    uint256 internal creationPubId;
    uint256 public endTimestamp;
    RefundBehavior public refundBehavior;

    error AlreadyEntered();
    error AlreadyCollected();
    error AlreadyMirrored();
    error CompetitionOngoing();
    error CompetitionFinished();
    error InvalidEntry();
    error WinnerNotSelected();
    error UnsupportedAction();
    error Unauthorized();
    error RefundDisabled();

    /// @notice profileId -> pubId -> true if publication is an entry
    mapping(uint256 => mapping(uint256 => bool)) public entries;

    constructor(ILensHub _lensHub, address _competitionHub) {
        lensHub = _lensHub;
        competitionHub = _competitionHub;
    }

    function creation() external view override returns (uint256 profileId, uint256 pubId) {
        return (creationProfileId, creationPubId);
    }

    function _onlyCompetitionHub() internal view {
        if (msg.sender != competitionHub) {
            revert Unauthorized();
        }
    }

    function version() external pure override returns (uint256) {
        return 1;
    }
}
