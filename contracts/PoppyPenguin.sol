// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC721PresetMinterPauserAutoId.sol";
import "./PoppyPenguinGeneGenerator.sol";
import "./IPoppyPenguin.sol";


contract PoppyPenguin is IPoppyPenguin, ERC721PresetMinterPauserAutoId, ReentrancyGuard {
    using PoppyPenguinGeneGenerator for PoppyPenguinGeneGenerator.Gene;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    PoppyPenguinGeneGenerator.Gene internal geneGenerator;

    address payable public daoAddress;
    uint256 public poppyPenguinPrice;
    uint256 public maxSupply;
    uint256 public bulkBuyLimit;
    string public arweaveAssetsJSON;

    event TokenMorphed(uint256 indexed tokenId, uint256 oldGene, uint256 newGene, uint256 price, PoppyPenguin.PoppyPenguinEventType eventType);
    event TokenMinted(uint256 indexed tokenId, uint256 newGene);
    event PoppyPenguinPriceChanged(uint256 newPoppyPenguinPrice);
    event MaxSupplyChanged(uint256 newMaxSupply);
    event BulkBuyLimitChanged(uint256 newBulkBuyLimit);
    event BaseURIChanged(string baseURI);
    event arweaveAssetsJSONChanged(string arweaveAssetsJSON);

    enum PoppyPenguinEventType { MINT, MORPH, TRANSFER }

    // Optional mapping for token URIs
    mapping (uint256 => uint256) internal _genes;

    constructor(string memory name, string memory symbol, string memory baseURI, address payable _daoAddress, uint premintedTokensCount, uint256 _poppyPenguinPrice, uint256 _maxSupply, uint256 _bulkBuyLimit, string memory _arweaveAssetsJSON) ERC721PresetMinterPauserAutoId(name, symbol, baseURI) public {
        daoAddress = _daoAddress;
        poppyPenguinPrice = _poppyPenguinPrice;
        maxSupply = _maxSupply;
        bulkBuyLimit = _bulkBuyLimit;
        arweaveAssetsJSON = _arweaveAssetsJSON;
        geneGenerator.random();

        _preMint(premintedTokensCount);
    }

    function _preMint(uint256 amountToMint) internal {
        for (uint i = 0; i < amountToMint; i++) {
            _tokenIdTracker.increment();
            uint256 tokenId = _tokenIdTracker.current();
            _genes[tokenId] = geneGenerator.random();
            _mint(_msgSender(), tokenId);
        } 
    }

    modifier onlyDAO() {
        require(msg.sender == daoAddress, "Not Called from the dao");
        _;
    }

    function geneOf(uint256 tokenId) public view virtual override returns (uint256 gene) {
         return _genes[tokenId];
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override (ERC721PresetMinterPauserAutoId) {
       ERC721PresetMinterPauserAutoId._beforeTokenTransfer(from, to, tokenId);
        emit TokenMorphed(tokenId, _genes[tokenId], _genes[tokenId], 0, PoppyPenguinEventType.TRANSFER);
    }

    function mint() public override payable nonReentrant {
        require(_tokenIdTracker.current() < maxSupply, "Total supply reached!");

        _tokenIdTracker.increment();

        uint256 tokenId = _tokenIdTracker.current();
        _genes[tokenId] = geneGenerator.random();

        (bool transferToDaoStatus, ) = daoAddress.call{value:poppyPenguinPrice}("");
        require(transferToDaoStatus, "Address: unable to send value, recipient may have reverted");

        uint256 excessAmount = msg.value.sub(poppyPenguinPrice);
        if (excessAmount > 0) {
            (bool returnExcessStatus, ) = _msgSender().call {value: excessAmount}("");
            require(returnExcessStatus, "Failed to return excess.");
        }

        _mint(_msgSender(), tokenId);

        emit TokenMinted(tokenId, _genes[tokenId]);
        emit TokenMorphed(tokenId, 0, _genes[tokenId], poppyPenguinPrice, PoppyPenguinEventType.MINT);
    }

    function bulkBuy(uint256 amount) public override payable nonReentrant {
        require(amount <= bulkBuyLimit, "Cannot bulk buy more than the preset limit.");
        require(_tokenIdTracker.current().add(amount) <= maxSupply, "Total supply reached");

        (bool transferToDaoStatus, ) = daoAddress.call{value:poppyPenguinPrice.mul(amount)}("");
        require(transferToDaoStatus, "AddressL unable to send value, recipient may have reverted");

        uint256 excessAmount = msg.value.sub(poppyPenguinPrice.mul(amount));
        if (excessAmount > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{value: excessAmount}("");
            require(returnExcessStatus, "Failed to return excess.");
        }

        for (uint256 i = 0; i < amount; i++) {
            _tokenIdTracker.increment();

            uint256 tokenId = _tokenIdTracker.current();
            _genes[tokenId] = geneGenerator.random();
            _mint(_msgSender(), tokenId);

            emit TokenMinted(tokenId, _genes[tokenId]);
            emit TokenMorphed(tokenId, 0, _genes[tokenId], poppyPenguinPrice, PoppyPenguinEventType.MINT);
        }

    }

    function lastTokenId() public override view returns (uint256 tokenId) {
        return _tokenIdTracker.current();
    }

    function mint(address to) public override (ERC721PresetMinterPauserAutoId) {
        revert("Should not use this one");
    }

    function setPoppyPenguinPrice(uint256 newPoppyPenguinPrice) public override virtual onlyDAO {
        poppyPenguinPrice = newPoppyPenguinPrice;

        emit PoppyPenguinPriceChanged(newPoppyPenguinPrice);
    }

    function setMaxSupply(uint256 _maxSupply) public override virtual onlyDAO {
        maxSupply = _maxSupply;

        emit MaxSupplyChanged(maxSupply);
    }

    function setBulkBuyLimit(uint256 _bulkBuyLimit) public override virtual onlyDAO {
        bulkBuyLimit = _bulkBuyLimit;

        emit BulkBuyLimitChanged(_bulkBuyLimit);
    }

    function setBaseURI(string memory _baseURI) public virtual onlyDAO {
        _setBaseURI(_baseURI);

        emit BaseURIChanged(_baseURI);
    }

    function setArweaveAssetsJSON(string memory _arweaveAssetsJSON) public virtual onlyDAO {
        arweaveAssetsJSON = _arweaveAssetsJSON;

        emit arweaveAssetsJSONChanged(_arweaveAssetsJSON);
    }

    receive() external payable {
        mint();
    }

}
