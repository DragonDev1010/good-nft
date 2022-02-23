// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract GoodNft is ERC721, Ownable{
	string public baseURI;

	uint256 public mintStage;

	uint256 public totalSupply;

	constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

	function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

	// function mint(uint256 tokenId) public {
	// 	_safeMint(msg.sender, tokenId);
	// }

	function adminMint(address[] memory wallets, uint256[] memory amounts) public onlyOwner {
		require(totalSupply < 200, "adminMint : Admin mint is 200 NFTs.");
		require(mintStage == 0, "adminMint : Mint stage has to set as Admin Mint Stage.");
		require(wallets.length == amounts.length, "adminMint : Wallet array has to be match amount array.");
		for (uint256 i = 0 ; i < wallets.length ; i++) {
			for (uint256 j = 0 ; j < amounts[i] ; j++) {
				_safeMint(wallets[i], totalSupply+j);
			}
			totalSupply += amounts[i];
		}
	}
	function holderMint() public {}
	function whiteMint() public {}

	function setMintStage(uint256 stage_) public onlyOwner {
		require(stage_ < 4, "setMintStage : The stage can not be greater than 4.");
		mintStage = stage_;
	}
}
