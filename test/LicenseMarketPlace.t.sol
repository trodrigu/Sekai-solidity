pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IPAssetRegistry} from "@story-protocol/protocol-core/contracts/registries/IPAssetRegistry.sol";
import {LicenseMarketPlace} from "../src/LicenseMarketPlace.sol";
import {MockLicensingModule} from "@story-protocol/protocol-core/test/foundry/mocks/module/MockLicensingModule.sol";
import {MockRoyaltyModule} from "@story-protocol/protocol-core/test/foundry/mocks/module/MockRoyaltyModule.sol";
import {ILicensingModule} from "@story-protocol/protocol-core/contracts/interfaces/modules/licensing/ILicensingModule.sol";
import {MockLicenseRegistry} from "@story-protocol/protocol-core/test/foundry/mocks/registry/MockLicenseRegistry.sol";

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

// MockLicensingModule licensingModule = new MockLicensingModule();
        // MockLicenseRegistry licenseRegistry = new MockLicenseRegistry();
        // MockIpAssetRegistry ipAssetRegistry = new MockIpAssetRegistry();
    function setUp() public {
        NFT = new MockERC721("Story Mock NFT", "STORY");
        address royalityModule = address(new MockRoyaltyModule());
        address licenseRegistryAddress = address(new MockLicenseRegistry());
        address licensingModuleAddr = address(new MockLicensingModule(address(0), address(0)));
        address ipAssetRegistry = address(new IPAssetRegistry());

        
        licenseMarketPlace = new LicenseMarketPlace(
            licensingModuleAddr,
            licenseRegistryAddress,
            ipAssetRegistry,
            address(NFT),
            1
        );
    }

    // function test_LicenseMarketPlaceRegistration() public {
    //     uint256 tokenId = NFT.mint();
    //     address ipId = licenseMarketPlace.registerIpAsset("test", tokenId);
    //     assertTrue(IPAssetRegistry(IPA_REGISTRY_ADDR).isRegistered(ipId), "not registered");
    // }
}
