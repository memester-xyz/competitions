// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PublicationId} from "./DataTypes.sol";

interface CompetitionV1 {
    function creation() external view returns (uint256 profileId, uint256 pubId);

    function entries(uint256 profileId, uint256 pubId) external returns (bool);

    function initialize(
        uint256 profileId,
        uint256 pubId,
        address sender,
        uint256 endTimestamp,
        bytes calldata competitionInitData
    ) external;

    function enter(uint256 profileId, uint256 pubId, address sender, bytes calldata competitionEnterData) external;

    function collected(uint256 profileId, uint256 pubId, address sender, bytes calldata competitionEntryCollectedData)
        external;

    function mirrored(uint256 profileId, uint256 pubId, address sender, bytes calldata competitionEntryMirroredData)
        external;

    function end(address sender, bytes calldata competitionEndData) external returns (PublicationId[] memory);

    function refund(address sender) external;

    function winners() external view returns (PublicationId[] memory);

    function version() external view returns (uint256);
}
