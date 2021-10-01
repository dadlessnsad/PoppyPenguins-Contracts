// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./../IPoppyPenguinWithGeneChanger.sol";

contract TestContractInteractor {
    
    IPoppyPenguinWithGeneChanger public poppyPenguinContract;

    constructor(address _poppyPengiuinAddress) public {
        poppyPenguinContract = IPoppyPenguinWithGeneChanger(_poppyPengiuinAddress);
    }

    function triggerGeneChange(uint256 tokenId, uint256 genePosition) payable public {
        poppyPenguinContract.morphGene{value: msg.value}(tokenId, genePosition);
    }

    function triggerRandomize(uint256 tokenId) payable public {
        poppyPenguinContract.randomizeGenome{value: msg.value}(tokenId);
    }
}
