// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

enum RefundBehavior {
    None,
    Always,
    IfNoEntries
}

struct PublicationId {
    uint256 profileId;
    uint256 pubId;
}
