// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {SekaiObjs} from "./SekaiObjs.sol";

interface ILicenseMarketPlace {
    // 	Registers an ipAsset that is registered on storyProtocol to the marketplace
    // function registerIpAsset(address storyProtocolIpId, uint256 setFee) external view returns (address);
    function registerIpAsset(
        address storyProtocolIpId
    ) external returns (uint256 licenseId);

    function registerExistingNFT(
        address tokenContract,
        uint256 tokenId,
        string calldata ip_name,
        bytes32 ip_content_hash,
        string calldata ip_url
    ) external returns (uint256 licenseId, address nft6551Addr);

    function registerNewNFT(
        string calldata nftName,
        string calldata nftDescription,
        string calldata nftUrl
    ) external returns (uint256 tokenId, address nft6551Addr);

    function isRegisteredToLicenseMarketPlace(
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external returns (bool);

    function isRegisteredToStoryProtocol(
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external returns (bool);

    // Allows a user to buy a key for a specific world based on it's ip address
    function buyKey(
        address sourceIpAssetAddress,
        address targeIpAssetAddress,
        uint256 amount
    ) external payable;

    // Allows a user to sell their key for a specific world.
    function sellKey(
        address sourceIpAssetAddress,
        address targeIpAssetAddress,
        uint256 amount
    ) external payable;

    function balanceOfHolder(
        address sharesAddr,
        address holderAddr
    ) external returns (uint256);

    function getMetadata(
        address sharesAddr
    ) external returns (SekaiObjs.LicenseMetadata memory);

    // function claimRoyalties(uint256 owner, uint256 storyProtocolIpId, uint256 tokenAmount) external view returns (address);

    // function distributeRoyalties(uint256 owner, uint256 storyProtocolIpId, uint256 tokenAmount) external view returns (address);
}
