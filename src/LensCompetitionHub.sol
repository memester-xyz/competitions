// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Clones} from "openzeppelin-contracts/proxy/Clones.sol";
import {Initializable} from "openzeppelin-contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts/proxy/utils/UUPSUpgradeable.sol";

import {ILensHub} from "./lens/ILensHub.sol";
import {DataTypes} from "./lens/DataTypes.sol";
import {CompetitionV1} from "./CompetitionV1.sol";
import {Events} from "./Events.sol";
import {PublicationId} from "./DataTypes.sol";

/// @title Main entry point to interact with LensCompetitions
/// @author devanon.lens
/// @author apedev.lens
contract LensCompetitionHub is UUPSUpgradeable, Initializable {
    mapping(uint256 => CompetitionV1) public competitions;
    mapping(address => bool) public competitionWhitelist;

    uint256 public competitionCount;

    ILensHub public lensHub;
    address public governance;

    error CompetitionNotWhitelisted();
    error IncorrectPublicationPointed();
    error NoWinner();
    error Unauthorized();

    function intialize(ILensHub _lensHub, address _governance) public initializer {
        lensHub = _lensHub;
        governance = _governance;
    }

    /// @notice Creates a new competition based on the provided implementation and passing any supplied init data
    ///
    /// @param competitionImpl the address of a contract which implements the CompetitionV1 interface
    /// @param postWithSigData the competition details as a Lens Publication
    /// @param competitionInitData data to be passed to the newly created competition's initialize function
    ///
    /// @return pubId An integer representing the competition's publication ID from LensHub
    /// @return competitionId Your competition's ID to be used
    /// @return competition CompetitionV1 contract that was created
    function createCompetition(
        address competitionImpl,
        uint256 endTimestamp,
        DataTypes.PostWithSigData calldata postWithSigData,
        bytes calldata competitionInitData
    ) external returns (uint256 pubId, uint256 competitionId, CompetitionV1 competition) {
        pubId = lensHub.postWithSig(postWithSigData);

        if (!competitionWhitelist[competitionImpl]) {
            revert CompetitionNotWhitelisted();
        }

        competitionId = ++competitionCount;

        bytes32 salt = keccak256(abi.encodePacked(msg.sender, competitionInitData, abi.encode(postWithSigData.sig)));

        competition = CompetitionV1(Clones.cloneDeterministic(competitionImpl, salt));
        competition.initialize(postWithSigData.profileId, pubId, msg.sender, endTimestamp, competitionInitData);

        competitions[competitionId] = competition;

        emit Events.CompetitionCreated(
            competitionId, address(competition), postWithSigData.profileId, pubId, endTimestamp
        );
    }

    /// @notice Enter into a competition by posting to Lens with the supplied commentWithSigData
    ///
    /// @param competitionId ID of competition to enter
    /// @param commentWithSigData the competition entry as a Lens Publication
    /// @param competitionEnterData data to be passed to the competition's enter function
    ///
    /// @return pubId An integer representing the entry's publication ID from LensHub
    function enterCompetition(
        uint256 competitionId,
        DataTypes.CommentWithSigData calldata commentWithSigData,
        bytes calldata competitionEnterData
    ) external returns (uint256 pubId) {
        pubId = lensHub.commentWithSig(commentWithSigData);

        CompetitionV1 competition = competitions[competitionId];

        (uint256 creationProfileId, uint256 creationPubId) = competition.creation();
        if (
            creationProfileId != commentWithSigData.profileIdPointed || creationPubId != commentWithSigData.pubIdPointed
        ) {
            revert IncorrectPublicationPointed();
        }

        competition.enter(commentWithSigData.profileId, pubId, msg.sender, competitionEnterData);

        emit Events.EnteredCompetition(competitionId, commentWithSigData.profileId, pubId);
    }

    /// @notice Collect a competition entry
    ///
    /// @param competitionId ID of competition to enter
    /// @param collectWithSigData data for LensHub to collect the Publication
    /// @param competitionEntryCollectedData data to be passed to the competition's collected function
    ///
    /// @return tokenId An integer representing the minted token ID from LensHub
    function collectCompetitionEntry(
        uint256 competitionId,
        DataTypes.CollectWithSigData calldata collectWithSigData,
        bytes calldata competitionEntryCollectedData
    ) external returns (uint256 tokenId) {
        tokenId = lensHub.collectWithSig(collectWithSigData);

        CompetitionV1 competition = competitions[competitionId];
        competition.collected(
            collectWithSigData.profileId, collectWithSigData.pubId, msg.sender, competitionEntryCollectedData
        );

        emit Events.CompetitionEntryCollected(competitionId, collectWithSigData.profileId, collectWithSigData.pubId);
    }

    /// @notice Mirror a competition entry
    ///
    /// @param competitionId ID of competition to enter
    /// @param mirrorWithSigData data for LensHub to mirror the Publication
    /// @param competitionEntryMirroredData data to be passed to the competition's mirrored function
    ///
    /// @return pubId An integer representing the mirrored publication ID from LensHub
    function mirrorCompetitionEntry(
        uint256 competitionId,
        DataTypes.MirrorWithSigData calldata mirrorWithSigData,
        bytes calldata competitionEntryMirroredData
    ) external returns (uint256 pubId) {
        pubId = lensHub.mirrorWithSig(mirrorWithSigData);

        CompetitionV1 competition = competitions[competitionId];
        competition.mirrored(mirrorWithSigData.profileId, pubId, msg.sender, competitionEntryMirroredData);

        emit Events.CompetitionEntryMirrored(competitionId, mirrorWithSigData.profileId, pubId);
    }

    /// @notice End a competition
    ///
    /// @param competitionId ID of competition to end
    /// @param competitionEndData data to be passed to the competition's end function
    ///
    /// @return publicationIds an array of PublicationId (profileId, pubId) structs, in winning order e.g. 0 index = 1st, 1 index = 2nd...
    function endCompetition(uint256 competitionId, bytes calldata competitionEndData)
        external
        returns (PublicationId[] memory publicationIds)
    {
        CompetitionV1 competition = competitions[competitionId];
        publicationIds = competition.end(msg.sender, competitionEndData);

        if (publicationIds.length == 0) {
            revert NoWinner();
        }

        emit Events.CompetitionEnded(competitionId, publicationIds[0].profileId, publicationIds[0].pubId);
    }

    /// @notice Refund a competition
    ///
    /// @param competitionId ID of competition to refund
    function refundCompetition(uint256 competitionId) external {
        CompetitionV1 competition = competitions[competitionId];
        competition.refund(msg.sender);

        emit Events.CompetitionRefunded(competitionId, msg.sender);
    }

    /// @notice Get the winner(s) for a competition
    ///
    /// @param competitionId ID of competition from which to get the winner
    ///
    /// @return publicationIds an array of PublicationId (profileId, pubId) structs, in winning order e.g. 0 index = 1st, 1 index = 2nd...
    function winners(uint256 competitionId) external view returns (PublicationId[] memory) {
        CompetitionV1 competition = competitions[competitionId];
        return competition.winners();
    }

    function determineCompetitionAddress(
        address competitionImpl,
        DataTypes.PostWithSigData calldata postWithSigData,
        bytes calldata competitionInitData
    ) external view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, competitionInitData, abi.encode(postWithSigData.sig)));

        return Clones.predictDeterministicAddress(competitionImpl, salt, address(this));
    }

    /// GOVERNANCE FUNCTIONS

    function whitelistCompetition(address competitionImpl, bool whitelisted) external {
        if (msg.sender != governance) {
            revert Unauthorized();
        }

        competitionWhitelist[competitionImpl] = whitelisted;
    }

    function setGovernance(address newGovernance) external {
        if (msg.sender != governance) {
            revert Unauthorized();
        }

        governance = newGovernance;
    }

    function _authorizeUpgrade(address) internal view override {
        if (msg.sender != governance) {
            revert Unauthorized();
        }
    }
}
