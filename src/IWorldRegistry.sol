pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract IWorldRegistry {
    function createWorld(
        string memory worldName,
        string memory worldDescription,
        string calldata nftUrl
    ) public virtual returns (uint256 tokenId, address tokenAddress);

    function buyWorldLicense(
        address buyer,
        address worldAddr,
        uint256 amount
    ) public virtual;

    function sellWorldLicense(
        address seller,
        address worldAddr,
        uint256 amount
    ) public virtual;

    // function setAsCannon(address worldOwner, address storyId, address storyId2) public virtual;
    // function distributePayToAllCannonCreators(address worldOwner, address worldId, uint256 amount) public virtual;

    // function buyStoryKey(address buyer, address storyId, uint256 amount);

    // function sellStoryKey(address seller, address storyId, uint256 amount);

    // // Checks if you have approval to link a world
    // // Requires the story key
    // function createAndLinkStory(
    //     address previousStory,
    //     string calldata nftName,
    //     string calldata nftDescription,
    //     string calldata nftUrl
    // );

    // // Checks if you have approval to link a world
    // // Requires the character
    // function createStoryRoot(
    //     address[] calldata dependencyAddr,
    //     string calldata nftName,
    //     string calldata nftDescription,
    //     string calldata nftUrl
    // );

    function branchStory(address worldAddr, address storyAddr) public virtual;

    //  - Mint a world
    // - Create a story for a world that can build on top of a story
    // - function registerCharacterToWorld(uint256 worldId, address tokenContract, uint256 tokenId) public virtual;
}
