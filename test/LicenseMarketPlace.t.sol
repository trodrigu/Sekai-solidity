pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IPAssetRegistry} from "@story-protocol/protocol-core/contracts/registries/IPAssetRegistry.sol";
import {LicenseMarketPlace} from "../src/LicenseMarketPlace.sol";
import {MockLicensingModule} from "@story-protocol/protocol-core/test/foundry/mocks/module/MockLicensingModule.sol";
import {MockRoyaltyModule} from "@story-protocol/protocol-core/test/foundry/mocks/module/MockRoyaltyModule.sol";
import {ILicensingModule} from "@story-protocol/protocol-core/contracts/interfaces/modules/licensing/ILicensingModule.sol";
import {MockLicenseRegistry} from "@story-protocol/protocol-core/test/foundry/mocks/registry/MockLicenseRegistry.sol";
import "./Users.t.sol";


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

    // MockLicensingModule licensingModule = new MockLicensingModule();
    // MockLicenseRegistry licenseRegistry = new MockLicenseRegistry();
    // MockIpAssetRegistry ipAssetRegistry = new MockIpAssetRegistry();
    address royalityModule = 0xA6bEf9CC650A16939566c1da5d5088f3F028a865;
    address licenseRegistryAddress = 0xc2BC7a2d5784768BDEd98436f2522A4931e2FBb4;
    address licensingModuleAddr = 0x950d766A1a0afDc33c3e653C861A8765cb42DbdC;
    address ipAssetRegistry = 0x292639452A975630802C17c9267169D93BD5a793;

    function setUp() public {
        NFT = new MockERC721("Story Mock NFT", "STORY");

        users = UsersLib.createMockUsers(vm);

        

        licenseMarketPlace = new LicenseMarketPlace(
            licensingModuleAddr,
            licenseRegistryAddress,
            ipAssetRegistry,
            address(NFT),
            1
        );

        vm.stopPrank();
    }

    // 1. Mint an NFT
    // 2. Register the NFT in the LicenseMarketPlace
    // 3. Have another person buy the NFT
    function test_LicenseMarketPlaceRegistration() public {
        vm.startPrank(users.alice);
        uint256 tokenId = NFT.mint();

        uint256 licenseId = licenseMarketPlace.registerExistingNFT(
            address(NFT),
            tokenId,
            "MyNFT",
            "random bytes",
            "www.sekai.com"
        );

        assertTrue(licenseMarketPlace.balanceOfHolder(address(NFT), users.alice) == 1, "not registered");
        vm.stopPrank();
    }
}
