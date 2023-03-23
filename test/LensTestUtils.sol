// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library LensTestUtils {
    string internal constant name = "Lens Protocol Profiles";
    bytes32 internal constant EIP712_REVISION_HASH = keccak256("1");
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 internal constant POST_WITH_SIG_TYPEHASH = keccak256(
        "PostWithSig(uint256 profileId,string contentURI,address collectModule,bytes collectModuleInitData,address referenceModule,bytes referenceModuleInitData,uint256 nonce,uint256 deadline)"
    );
    bytes32 internal constant COMMENT_WITH_SIG_TYPEHASH = keccak256(
        "CommentWithSig(uint256 profileId,string contentURI,uint256 profileIdPointed,uint256 pubIdPointed,bytes referenceModuleData,address collectModule,bytes collectModuleInitData,address referenceModule,bytes referenceModuleInitData,uint256 nonce,uint256 deadline)"
    );

    string internal constant MOCK_PROFILE_URI = "https://ipfs.io/ipfs/Qme7ss3ARVgxv6rXqVPiikMJ8u2NLgmgszg13pYrDKEoiu";
    string internal constant MOCK_FOLLOW_NFT_URI =
        "https://ipfs.fleek.co/ipfs/ghostplantghostplantghostplantghostplantghostplantghostplan";

    string internal constant MOCK_URI = "https://ipfs.io/ipfs/QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR";

    address internal constant FREE_COLLECT_MODULE = 0x23b9467334bEb345aAa6fd1545538F3d54436e96;

    /**
     * @dev Calculates EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     * https://github.com/lens-protocol/core/blob/main/contracts/core/base/LensNFTBase.sol
     */
    function calculateDomainSeparator(address lensHub) internal view returns (bytes32) {
        return keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256(bytes(name)), EIP712_REVISION_HASH, block.chainid, lensHub)
        );
    }

    /**
     * @dev Calculates EIP712 digest based on the current DOMAIN_SEPARATOR.
     * https://github.com/lens-protocol/core/blob/main/contracts/core/base/LensNFTBase.sol
     *
     * @param hashedMessage The message hash from which the digest should be calculated.
     *
     * @return bytes32 A 32-byte output representing the EIP712 digest.
     */
    function calculateDigest(bytes32 hashedMessage, address lensHub) internal view returns (bytes32) {
        bytes32 digest;
        unchecked {
            digest = keccak256(abi.encodePacked("\x19\x01", calculateDomainSeparator(lensHub), hashedMessage));
        }
        return digest;
    }
}
