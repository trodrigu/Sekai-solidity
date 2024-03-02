// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {IP} from "@story-protocol/protocol-core/contracts/lib/IP.sol";
import {IPAssetRegistry} from "@story-protocol/protocol-core/contracts/registries/IPAssetRegistry.sol";
import {IIPAssetRegistry} from "@story-protocol/protocol-core/contracts/interfaces/registries/IIPAssetRegistry.sol";
import {IPResolver} from "@story-protocol/protocol-core/contracts/resolvers/IPResolver.sol";
import {ILicenseRegistry} from "@story-protocol/protocol-core/contracts/interfaces/registries/ILicenseRegistry.sol";
import {ILicenseMarketPlace} from "./ILicenseMarketPlace.sol";
import {IERC6551Account} from "erc6551/interfaces/IERC6551Account.sol";
import {IIPAccount} from "@story-protocol/protocol-core/contracts/interfaces/IIPAccount.sol";
import {IStoryProtocolGateway} from "@story-protocol/protocol-periphery/contracts/StoryProtocolGateway.sol";
import {SPG} from "@story-protocol/protocol-periphery/contracts/lib/SPG.sol";
import {Metadata} from "@story-protocol/protocol-periphery/contracts/lib/Metadata.sol";
import {ILicensingModule} from "@story-protocol/protocol-core/contracts/interfaces/modules/licensing/ILicensingModule.sol";
import {PILPolicyFrameworkManager} from "@story-protocol/protocol-core/contracts/modules/licensing/PILPolicyFrameworkManager.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IRegistrationModule} from "@story-protocol/protocol-core/contracts/interfaces/modules/IRegistrationModule.sol";
import {console2} from "forge-std/console2.sol";
import {SekaiObjs} from "./SekaiObjs.sol";

interface IERC1271 {
    function isValidSignature(
        bytes32 _hash,
        bytes memory _signature
    ) external view returns (bytes4);
}

contract LicenseMarketPlace is
    ILicenseMarketPlace,
    IERC165,
    IERC1271,
    IERC721Receiver,
    IERC1155Receiver
{
    bytes4 internal constant MAGICVALUE = 0x1626ba7e;
    IIPAssetRegistry public immutable IPA_REGISTRY;

    ILicenseRegistry public immutable LICENSE_REGISTRY;
    uint256 public immutable POLICY_ID;
    IStoryProtocolGateway public spg;
    address public immutable DEFAULT_SPG_NFT;
    ILicensingModule public immutable LICENSING_MODULE;
    PILPolicyFrameworkManager public immutable POLICY_MANAGER;
    IRegistrationModule public immutable REGISTRATION_MODULE;
    address public immutable BURN_ADDRESS = address(123456789);

    event Trade(
        address trader,
        address subject,
        bool isBuy,
        uint256 shareAmount,
        uint256 ethAmount,
        uint256 protocolEthAmount,
        uint256 subjectEthAmount,
        uint256 supply
    );

    event PrintError(
        int256 userInput,
        int256 baseFee,
        int256 otherFee1,
        int256 otherFee2
    );

    uint256 public protocolFeePercent = (5 * 1 ether) / 100;
    uint256 public subjectFeePercent = (5 * 1 ether) / 100;

    // We will need to have a mapping of the IP id to

    // SharesSubject => (Holder => Balance)
    mapping(address => mapping(address => uint256)) public sharesBalance;

    // SharesSubject => Supply
    mapping(address => SekaiObjs.LicenseMetadata) public sharesMetadata;

    mapping(uint256 => address) public licenseIdToAddress;

    function balanceOfHolder(
        address sharesAddr,
        address holderAddr
    ) public view returns (uint256) {
        return sharesBalance[sharesAddr][holderAddr];
    }

    function getMetadata(
        address sharesAddr
    ) public view returns (SekaiObjs.LicenseMetadata memory) {
        return sharesMetadata[sharesAddr];
    }

    function isRegisteredToLicenseMarketPlace(
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) public view returns (bool) {
        address addr = IPA_REGISTRY.ipAccount(chainId, tokenContract, tokenId);
        return sharesMetadata[addr].licenseId != 0;
    }

    function isRegisteredToStoryProtocol(
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) public view returns (bool) {
        address addr = IPA_REGISTRY.ipAccount(chainId, tokenContract, tokenId);
        // Check that the address is not null
        return addr != address(0);
    }

    constructor(
        address licensingModuleAddr,
        address licenseRegistryAddress,
        address ipAssetRegistry,
        address defaultSPGNFTAddr,
        address spgAddr,
        address registrationModuleAddr,
        uint256 policyId
    ) {
        LICENSE_REGISTRY = ILicenseRegistry(licenseRegistryAddress);
        IPA_REGISTRY = IPAssetRegistry(ipAssetRegistry);
        POLICY_ID = policyId;
        DEFAULT_SPG_NFT = defaultSPGNFTAddr;
        LICENSING_MODULE = ILicensingModule(licensingModuleAddr);
        spg = IStoryProtocolGateway(spgAddr);
        REGISTRATION_MODULE = IRegistrationModule(registrationModuleAddr);
    }

    function _registerIpAsset(
        address storyProtocolIpId
    ) internal returns (uint256) {
        // Construct a license with the policy id
        require(
            storyProtocolIpId != address(0) &&
                sharesBalance[storyProtocolIpId][storyProtocolIpId] <= 0,
            "Already Registered"
        );
        uint256 licenseId = LICENSING_MODULE.mintLicense(
            POLICY_ID,
            storyProtocolIpId,
            1,
            msg.sender,
            ""
        );
        sharesBalance[storyProtocolIpId][msg.sender] = 1;
        SekaiObjs.LicenseMetadata memory licenseMetadata = SekaiObjs
            .LicenseMetadata({
                totalSupply: 1,
                numDerivatives: 0,
                licenseId: licenseId
            });
        sharesMetadata[storyProtocolIpId] = licenseMetadata;
        return licenseId;
    }

    function registerIpAsset(
        address storyProtocolIpId
    ) external returns (uint256) {
        return _registerIpAsset(storyProtocolIpId);
    }

    function _generateMetadata(
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        address registrant,
        string calldata ip_name,
        string calldata url
    ) internal view returns (bytes memory) {
        bytes32 hash = keccak256(abi.encode(chainId, tokenContract, tokenId));
        return
            abi.encode(
                IP.MetadataV1({
                    name: ip_name,
                    hash: hash,
                    registrationDate: uint64(block.timestamp),
                    registrant: registrant,
                    uri: url
                })
            );
    }

    function registerExistingNFT(
        address tokenContract,
        uint256 tokenId,
        string calldata ip_name,
        bytes32 ip_content_hash,
        string calldata ip_url
    ) external returns (uint256, address) {
        IPA_REGISTRY.setApprovalForAll(address(spg), true);

        address nftAccountAddr = REGISTRATION_MODULE.registerRootIp(
            POLICY_ID,
            tokenContract,
            tokenId,
            ip_name,
            ip_content_hash,
            ip_url
        );

        return (_registerIpAsset(nftAccountAddr), nftAccountAddr);
    }

    function registerNewNFT(
        string calldata nftName,
        string calldata nftDescription,
        string calldata nftUrl
    ) external returns (uint256 tokenId, address tokenAddress) {
        // Setup metadata attribution related to the NFT itself.
        Metadata.Attribute[] memory nftAttributes = new Metadata.Attribute[](1);
        bytes memory nftMetadata = abi.encode(
            Metadata.TokenMetadata({
                name: nftName,
                description: nftDescription,
                externalUrl: nftUrl,
                image: "pic",
                attributes: nftAttributes
            })
        );

        // Setup metadata attribution related to the IP semantics.
        Metadata.Attribute[] memory ipAttributes = new Metadata.Attribute[](1);
        ipAttributes[0] = Metadata.Attribute({
            key: "trademarkType",
            value: "merchandising"
        });
        Metadata.IPMetadata memory ipMetadata = Metadata.IPMetadata({
            name: "name for your IP asset",
            hash: bytes32("your IP asset content hash"),
            url: nftUrl,
            customMetadata: ipAttributes
        });

        SPG.Signature memory signature = SPG.Signature({
            signer: address(this),
            deadline: block.timestamp + 1000,
            signature: ""
        });

        IPA_REGISTRY.setApprovalForAll(msg.sender, true);

        (tokenId, tokenAddress) = spg.mintAndRegisterIpWithSig(
            POLICY_ID,
            DEFAULT_SPG_NFT,
            nftMetadata,
            ipMetadata,
            signature
        );

        _registerIpAsset(tokenAddress);

        return (tokenId, tokenAddress);
    }

    function _verifyOwner(
        address ownerAddr,
        address nftAcctAddr
    ) internal view returns (bool) {
        IIPAccount ipAccount = IIPAccount(payable(nftAcctAddr));
        address queriedOwner = ipAccount.owner();
        return queriedOwner == ownerAddr;
    }

    /**
     * Allows a user to buy a key from the marketplace.
     * @param sourceIpAssetAddress The address of the IPAsset's license that you want to buy. It's required that you own the address
     * @param targeIpAssetAddress The address of the IPAsset that you want to receive.
     * @param amount The amount of the key to buy.
     */
    function buyKey(
        address sourceIpAssetAddress,
        address targeIpAssetAddress,
        uint256 amount
    ) public payable {
        // function implementation goes here
        // LICENSE_REGISTRY.setApprovalForAll(address(this), true);

        uint256 supply = sharesMetadata[sourceIpAssetAddress].totalSupply;
        require(
            supply > 0 || _verifyOwner(msg.sender, sourceIpAssetAddress),
            "Only the IPAccount owner can buy the first share"
        );

        uint256 price = getPrice(
            sharesMetadata[sourceIpAssetAddress].totalSupply,
            sharesMetadata[sourceIpAssetAddress].numDerivatives,
            amount
        );
        uint256 protocolFee = (price * protocolFeePercent) / 1 ether;
        uint256 subjectFee = (price * subjectFeePercent) / 1 ether;
        emit PrintError(
            int256(msg.value),
            int256(price),
            int256(protocolFee),
            int256(subjectFee)
        );
        require(
            msg.value >= price + protocolFee + subjectFee,
            "Insufficient payment :)"
        );
        sharesBalance[sourceIpAssetAddress][targeIpAssetAddress] =
            sharesBalance[sourceIpAssetAddress][targeIpAssetAddress] +
            amount;
        sharesMetadata[sourceIpAssetAddress].totalSupply = supply + amount;
        emit Trade(
            targeIpAssetAddress,
            sourceIpAssetAddress,
            true,
            amount,
            price,
            0,
            0,
            supply + amount
        );

        //         uint256 licenseId = LICENSING_MODULE.mintLicense(
        //     POLICY_ID,
        //     storyProtocolIpId,
        //     1,
        //     msg.sender,
        //     ""
        // );

        LICENSING_MODULE.mintLicense(
            POLICY_ID,
            sourceIpAssetAddress,
            amount,
            msg.sender,
            ""
        );
    }

    // So youre NFT can own items as well as you
    function sellKey(
        address sourceIpAssetAddress,
        address targeIpAssetAddress,
        uint256 amount
    ) public payable {
        uint256 supply = sharesMetadata[sourceIpAssetAddress].totalSupply;
        require(supply > amount, "Cannot sell the last share");

        uint256 price = getPrice(
            supply,
            sharesMetadata[sourceIpAssetAddress].numDerivatives,
            amount
        );

        uint256 protocolFee = (price * protocolFeePercent) / 1 ether;
        uint256 subjectFee = (price * subjectFeePercent) / 1 ether;

        require(
            supply > 0 || _verifyOwner(msg.sender, targeIpAssetAddress),
            "Only the IPAccount owner can sell the first share"
        );

        require(
            sharesBalance[sourceIpAssetAddress][targeIpAssetAddress] >= amount,
            "Insufficient shares"
        );
        sharesBalance[sourceIpAssetAddress][targeIpAssetAddress] =
            sharesBalance[sourceIpAssetAddress][targeIpAssetAddress] -
            amount;
        sharesMetadata[sourceIpAssetAddress].totalSupply = supply - amount;
        emit Trade(
            targeIpAssetAddress,
            sourceIpAssetAddress,
            false,
            amount,
            price,
            protocolFee,
            subjectFee,
            supply - amount
        );
        (bool success1, ) = msg.sender.call{
            value: price - protocolFee - subjectFee
        }("");
        // (bool success2, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success3, ) = targeIpAssetAddress.call{value: subjectFee}("");
        require(success1 && success3, "Unable to send funds");
        LICENSE_REGISTRY.safeTransferFrom(
            targeIpAssetAddress,
            BURN_ADDRESS,
            sharesMetadata[sourceIpAssetAddress].licenseId,
            amount,
            ""
        );
    }

    function getPrice(
        uint256 totalCirculating,
        uint256 numBurned,
        uint256 amount
    ) public pure returns (uint256) {
        uint256 totalSupplyAndBurned = totalCirculating + numBurned;
        uint256 sum1 = totalSupplyAndBurned == 0
            ? 0
            : ((totalSupplyAndBurned - 1) *
                (totalSupplyAndBurned) *
                (2 * (totalSupplyAndBurned - 1) + 1)) / 6;
        uint256 sum2 = totalSupplyAndBurned == 0 && amount == 1
            ? 0
            : ((totalSupplyAndBurned - 1 + amount) *
                (totalSupplyAndBurned + amount) *
                (2 * (totalSupplyAndBurned - 1 + amount) + 1)) / 6;
        uint256 summation = sum2 - sum1;

        return (summation * 1 ether) / 16000;
    }

    function getPriceFromAccount(
        address sourceIpAssetAddress,
        uint256 amount
    ) public view returns (uint256) {
        return
            getPrice(
                sharesMetadata[sourceIpAssetAddress].totalSupply,
                sharesMetadata[sourceIpAssetAddress].numDerivatives,
                amount
            );
    }

    // This function will get all the licenses from each of the childIpids. Then, link them with LICENSE_REGISTRY.linkIpToParents.
    // Then, the license metadata will be update each of the numDerivatives by decrementing each of the parents by 1
    function linkIpToParents(
        address[] calldata parentIps,
        address childIpId,
        bytes calldata royaltyContext
    ) external {
        uint256[] memory licensesToLink = new uint256[](parentIps.length);
        for (uint256 i = 0; i < parentIps.length; i++) {
            IIPAccount ipAccount = IIPAccount(payable(childIpId));
            address owner = ipAccount.owner();
            uint256 licenseId = sharesMetadata[parentIps[i]].licenseId;
            // if (LICENSE_REGISTRY.balanceOf(owner, licenseId) > 0) {
            //     LICENSE_REGISTRY.safeTransferFrom(owner, childIpId, licenseId, 1, "");
            // }
            // LICENSE_REGISTRY.safeTransferFrom(owner, childIpId, licenseId, 1, "");

            licensesToLink[i] = licenseId;
        }

        LICENSING_MODULE.linkIpToParents(
            licensesToLink,
            childIpId,
            royaltyContext
        );
        for (uint256 i = 0; i < parentIps.length; i++) {
            sharesMetadata[parentIps[i]].totalSupply--;
            sharesMetadata[parentIps[i]].numDerivatives++;
        }
    }

    function setApproval(
        address licensorAddr,
        address childIpId,
        bool approved
    ) external {
        uint256 licenseId = sharesMetadata[licensorAddr].licenseId;
        POLICY_MANAGER.setApproval(licenseId, childIpId, approved);
    }

    function isValidSignature(
        bytes32 _hash,
        bytes memory _signature
    ) external view override returns (bytes4) {
        return MAGICVALUE;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) external pure returns (bool) {
        return (interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId);
    }

    /// @inheritdoc IERC721Receiver
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @inheritdoc IERC1155Receiver
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /// @inheritdoc IERC1155Receiver
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    // set Approval for the world

    // function claimRoyalties(
    //     address owner,
    //     uint256 storyProtocolIpId,
    //     uint256 tokenAmount
    // ) external view returns (address) {
    //     return address(owner);
    // }

    // function distributeRoyalties(
    //     address owner,
    //     uint256 storyProtocolIpId,
    //     uint256 tokenAmount
    // ) external view returns (address) {
    //     return address(owner);
    // }
}

/*
- Mint a world
- Create a story for a world that can build on top of a story
- function registerCharacterToWorld(uint256 worldId, address tokenContract, uint256 tokenId) public virtual;
- 
*/
