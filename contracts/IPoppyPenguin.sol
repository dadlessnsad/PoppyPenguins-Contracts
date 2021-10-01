// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


interface IPoppyPenguin is IERC721 {

    function geneOf(uint256 tokenId) external view returns (uint256 gene);
    function mint() external payable;
    function bulkBuy(uint256 amount) external payable;
    function lastTokenId() external view returns (uint256 tokenId);
    function setPoppyPenguinPrice(uint256 newPoppyPenguinPrice) external virtual;
    function setMaxSupply(uint256 maxSupply) external virtual;
    function setBulkBuyLimit(uint256 bulkBuyLimit) external virtual;
     
}