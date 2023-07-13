// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract MysteryBox is Ownable, ReentrancyGuard, ERC721Enumerable {
    using Strings for uint256;

    string public baseURI;
    
    uint256 public mintFee;
    uint256 public mintStart;
    
    uint256 public maxSupply;

    mapping (address => bool) public goldMember;
    mapping (address => bool) public whiteMember;

    constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC721 (_name, _symbol) {
        maxSupply = 10000;
        baseURI = _baseURI;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setMintStart(uint256 _mintStart) public onlyOwner {
        require(mintStart == 0, "minting already started");
        if (_mintStart > block.timestamp)
            mintStart = _mintStart;
        else
            mintStart = block.timestamp;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }
    
    function setMintFee (uint256 _mintFee) public onlyOwner {
        mintFee = _mintFee;
    }

    function setGoldMember (address member, bool status) public onlyOwner {
        goldMember[member] = status;
    }

    function setWhiteMember (address member, bool status) public onlyOwner {
        whiteMember[member] = status;
    }
    
    function mint (address to) public payable  {
        require(mintStart > 0, "minting not started yet");
        require(totalSupply() < maxSupply, "max supply reached");
        uint256 tokenId = totalSupply() + 1;
        //allow first 24 hours for only gold members to mint
        if (block.timestamp < mintStart + (24 * 60 * 60)) { 
            require(goldMember[msg.sender], "not a gold member");
            require(msg.value >= (mintFee * 75) / 100, "Value is not greater or equal to mintFee (for goldMember)");
        }
        //allow second 24 hours for only white members to mint
        else if (block.timestamp >= mintStart + (24 * 60 * 60) && block.timestamp < mintStart + (48 * 60 * 60)) {
            require(whiteMember[msg.sender], "not a white member");
            require(msg.value >= mintFee, "Value is not greater or equal to mintFee (for whiteMember)");
        }
        else
            require(msg.value >= mintFee, "Value is not greater or equal to mintFee");
        _mint(to, tokenId);
    }

    
    function MultipleMints(address to, uint256 No_of_Mints) public payable nonReentrant {
        if(goldMember[msg.sender]){
            require(No_of_Mints<=5, "Only 5 mints can be done by Gold Member at a time");
            while(No_of_Mints!=0){
            mint(to);
            No_of_Mints=No_of_Mints-1;
        }
        }
        else if(whiteMember[msg.sender]){
            require(No_of_Mints<=2, "Only 2 mints can be done By White Member at a time");
            while(No_of_Mints!=0){
            mint(to);
            No_of_Mints=No_of_Mints-1;
        }
        }
        else{
            revert("multiple mints not allowed");
        }
    }

    function tokensOfOwner (address owner) public view returns (uint256[] memory) {
        require(0 < ERC721.balanceOf(owner), "ERC721Enum: owner ioob");
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function manage(address to) public onlyOwner {
        (bool sent, ) = to.call{value: address(this).balance}("");
        require(sent, "Failed to manage Ether");
    }

}