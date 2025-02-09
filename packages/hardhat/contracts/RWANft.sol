// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RWANft is ERC721URIStorage, Ownable {
    string public constant DEFAULT_TOKEN_URI =
        "https://orange-bright-ocelot-583.mypinata.cloud/ipfs/bafkreidmlcnew5tyampojhcfbcjynlcxuepcubrzpiwrcgm6qpy4lmaaoq";
    uint256 private s_tokenCounter;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
        s_tokenCounter = 0;
    }

    function mintDefaultNft() public onlyOwner returns (uint) {
        _safeMint(msg.sender, s_tokenCounter);
        _setTokenURI(s_tokenCounter, DEFAULT_TOKEN_URI); 
        s_tokenCounter = s_tokenCounter + 1;
        return s_tokenCounter;
    }

    function mintNft(string memory tokenURI) public onlyOwner returns (uint) {
        _safeMint(msg.sender, s_tokenCounter);
        _setTokenURI(s_tokenCounter, tokenURI); 
        s_tokenCounter = s_tokenCounter + 1;
        return s_tokenCounter;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
}