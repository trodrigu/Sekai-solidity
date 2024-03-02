pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IPAssetRegistry} from "@story-protocol/protocol-core/contracts/registries/IPAssetRegistry.sol";
import {LicenseMarketPlace} from "../src/LicenseMarketPlace.sol";
import {MockLicensingModule} from "@story-protocol/protocol-core/test/foundry/mocks/module/MockLicensingModule.sol";
import {MockRoyaltyModule} from "@story-protocol/protocol-core/test/foundry/mocks/module/MockRoyaltyModule.sol";
import {ILicensingModule} from "@story-protocol/protocol-core/contracts/interfaces/modules/licensing/ILicensingModule.sol";
import {MockLicenseRegistry} from "@story-protocol/protocol-core/test/foundry/mocks/registry/MockLicenseRegistry.sol";
import {IIPAssetRegistry} from "@story-protocol/protocol-core/contracts/interfaces/registries/IIPAssetRegistry.sol";
import {SPG} from "@story-protocol/protocol-periphery/contracts/lib/SPG.sol";
import "./Users.t.sol";
import {AccessPermission} from "@story-protocol/protocol-core/contracts/lib/AccessPermission.sol";
import {console} from "forge-std/console.sol";
import {Metadata} from "@story-protocol/protocol-periphery/contracts/lib/Metadata.sol";
import {SekaiObjs} from "../src/SekaiObjs.sol";
import {ILicenseRegistry} from "@story-protocol/protocol-core/contracts/interfaces/registries/ILicenseRegistry.sol";
import {IIPAccountRegistry} from "@story-protocol/protocol-core/contracts/interfaces/registries/IIPAccountRegistry.sol";
import {IIPAccount} from "@story-protocol/protocol-core/contracts/interfaces/IIPAccount.sol";

contract MockERC721 is ERC721 {
    uint256 public totalSupply = 0;

    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {}

    function mint() external returns (uint256 id) {
        id = totalSupply++;
        _mint(msg.sender, id);
    }
}

contract LicenseMarketPlaceTest is Test {
    address public constant IPA_REGISTRY_ADDR =
        address(0x7567ea73697De50591EEc317Fe2b924252c41608);
    address public constant IP_RESOLVER_ADDR =
        address(0xEF808885355B3c88648D39c9DB5A0c08D99C6B71);

    MockERC721 public NFT;
    LicenseMarketPlace public licenseMarketPlace;

    address public alice;
    address public bob;
    Users public users;

    address licensingModuleAddr = 0x950d766A1a0afDc33c3e653C861A8765cb42DbdC;
    address licenseRegistryAddress = 0xc2BC7a2d5784768BDEd98436f2522A4931e2FBb4;
    address ipAssetRegistry = 0x292639452A975630802C17c9267169D93BD5a793;
    address royalityModule = 0xA6bEf9CC650A16939566c1da5d5088f3F028a865;
    address defaultNFTAddr = 0x9d790FF5B6A7469f32f18E677E15D48b86C6839b;
    address spgAddr = 0xf82EEe73c2c81D14DF9bC29DC154dD3c079d80a0;
    address registrationAddress = 0x613128e88b568768764824f898C8135efED97fA6;
    address ipAccountAddress = 0xBD2780F291588C8bDDf7F5874988fA9d3179d560;
    address accessControllerAddress = 0xad64a4b2e18FF7D2f97aF083E7b193d7Dd141735;

    ILicensingModule public LICENSING_MODULE =
        ILicensingModule(licensingModuleAddr);

    IIPAccountRegistry public IP_ACCOUNT_REGISTRY =
        IIPAccountRegistry(ipAccountAddress);

    function setUp() public {
        NFT = new MockERC721("Story Mock NFT", "STORY");

        users = UsersLib.createMockUsers(vm);

        licenseMarketPlace = new LicenseMarketPlace(
            licensingModuleAddr,
            licenseRegistryAddress,
            ipAssetRegistry,
            defaultNFTAddr,
            spgAddr,
            registrationAddress,
            1
        );
    }

    // 1. Mint an NFT
    // 2. Register the NFT in the LicenseMarketPlace
    // 3. Have another person buy the NFT
    function test_LicenseMarketPlaceRegistration() public {
        vm.startPrank(users.alice);

        uint256 tokenId = NFT.mint();
        NFT.setApprovalForAll(address(licenseMarketPlace), true);

        (uint256 _licenseId, address nftAccountAddr) = licenseMarketPlace
            .registerExistingNFT(
                address(NFT),
                tokenId,
                "MyNFT",
                "random bytes",
                "www.joinsek.ai"
            );

        assertTrue(
            licenseMarketPlace.balanceOfHolder(nftAccountAddr, users.alice) ==
                1,
            "not registered"
        );
        vm.stopPrank();
    }

    function test_LicenseMarketPlaceBuyingAndSelling() public {
        vm.deal(users.bob, 1000 ether);
        vm.startPrank(users.alice);

        uint256 tokenId = NFT.mint();
        NFT.setApprovalForAll(address(licenseMarketPlace), true);

        (uint256 _licenseId, address nftAccountAddr) = licenseMarketPlace
            .registerExistingNFT(
                address(NFT),
                tokenId,
                "MyNFT",
                "random bytes",
                "www.joinsek.ai"
            );
        vm.stopPrank();

        vm.startPrank(users.bob);
        ILicenseRegistry(licenseRegistryAddress).setApprovalForAll(
            address(licenseMarketPlace),
            true
        );

        // Buy two licenses
        licenseMarketPlace.buyKey{value: 0.2 ether}(
            nftAccountAddr,
            users.bob,
            2
        );

        SekaiObjs.LicenseMetadata memory metadata1 = licenseMarketPlace
            .getMetadata(nftAccountAddr);

        assertTrue(
            metadata1.totalSupply == 3,
            "Should only have 3 NFT in the total supply"
        );

        assertTrue(
            metadata1.numDerivatives == 0,
            "Should only have 0 derivatives right now"
        );

        assertTrue(
            licenseMarketPlace.balanceOfHolder(nftAccountAddr, users.bob) == 2,
            "Should have bought 2 NFTs"
        );

        // Sell one of the licenses
        licenseMarketPlace.sellKey{value: 0.2 ether}(
            nftAccountAddr,
            users.bob,
            1
        );

        SekaiObjs.LicenseMetadata memory metadata2 = licenseMarketPlace
            .getMetadata(nftAccountAddr);

        // print out metadata2

        assertTrue(
            licenseMarketPlace.balanceOfHolder(nftAccountAddr, users.bob) == 1,
            "Should only have 1 NFT right now"
        );

        assertTrue(
            metadata2.totalSupply == 2,
            "Should only have 1 NFT right now"
        );

        assertTrue(
            metadata2.numDerivatives == 0,
            "Should only have 0 derivatives right now"
        );

        assertTrue(
            licenseMarketPlace.balanceOfHolder(nftAccountAddr, users.bob) == 1,
            "Should only have 1 NFT right now"
        );
        vm.stopPrank();
    }

    function test_LicenseMarketPlaceLinkingDerivatives() public {
        vm.deal(users.bob, 1000 ether);
        vm.startPrank(users.alice);

        uint256 tokenId = NFT.mint();
        NFT.setApprovalForAll(address(licenseMarketPlace), true);

        (uint256 _licenseId, address nftAccountAddr) = licenseMarketPlace
            .registerExistingNFT(
                address(NFT),
                tokenId,
                "MyNFT",
                "random bytes",
                "www.joinsek.ai"
            );
        vm.stopPrank();

        vm.startPrank(users.bob);
        NFT.setApprovalForAll(address(licenseMarketPlace), true);
        ILicenseRegistry(licenseRegistryAddress).setApprovalForAll(
            address(licenseMarketPlace),
            true
        );

        // Buy a license
        licenseMarketPlace.buyKey{value: 0.2 ether}(
            nftAccountAddr,
            users.bob,
            1
        );

        assertTrue(
            licenseMarketPlace.balanceOfHolder(nftAccountAddr, users.bob) == 1,
            "Should have bought 1 NFT"
        );

        // Create a derivative
        uint256 derivativeId = NFT.mint();
        // NFT.setApprovalForAll(address(licenseMarketPlace), true);
        address derivativeAddress = IP_ACCOUNT_REGISTRY.registerIpAccount(
            11155111,
            address(NFT),
            derivativeId
        );

        // Link the derivative to the original NFT
        address[] memory parentAddrs = new address[](1);
        parentAddrs[0] = nftAccountAddr;

        // We need to grat the derivative address permission to link to the original NFT
        IIPAccount(payable(derivativeAddress)).execute(
            accessControllerAddress,
            0,
            abi.encodeWithSignature(
                "setPermission(address,address,address,bytes4,uint8)",
                derivativeAddress,
                address(licenseMarketPlace),
                licensingModuleAddr,
                bytes4(0),
                AccessPermission.ALLOW
            )
        );

        licenseMarketPlace.linkIpToParents(parentAddrs, derivativeAddress, "");

        SekaiObjs.LicenseMetadata memory metadata = licenseMarketPlace
            .getMetadata(nftAccountAddr);

        // Check that the derivative was linked correctly
        assertTrue(
            metadata.numDerivatives == 1,
            "Should have 1 derivative linked"
        );
        vm.stopPrank();
    }
}
