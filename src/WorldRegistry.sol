pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import {IWorldRegistry} from "./IWorldRegistry.sol";
import {SekaiObjs} from "./SekaiObjs.sol";

contract WorldRegistry is IWorldRegistry {
    
    
    address public licenseMarketPlace;
    address public licensingModule;

    constructor(
        address _licenseMarketPlaceAddress,
        address _licensingModuleAddress
    ) {
        licenseMarketPlace = _licenseMarketPlaceAddress;
        licensingModule = _licensingModuleAddress;
    }
    function createWorld(
        string memory worldName,
        string memory worldDescription,
        string calldata nftUrl
    ) public virtual override returns (uint256 tokenId, address tokenAddress) {
        // Create a license
        return registerNewNFT(worldName, worldDescription, nftUrl);



    }
    // function buyWorldLicense(address buyer, uint256 worldId, uint256 amount) public virtual;
    // function sellWorldLicense(address seller, uint256 worldId, uint256 amount) public virtual;
    // function getTotalWorldLicense(uint256 worldId) public virtual view returns (uint256);
    // function setAsCannon(address worldOwner, address storyId, address storyId2) public virtual;
    // function distributePayToAllCannonCreators(address worldOwner, address worldId, uint256 amount) public virtual;
}
