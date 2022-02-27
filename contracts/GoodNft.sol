// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract GoodNft is ERC721, Ownable{
	IERC721 star;
	string public baseURI;

	uint256 public mintStage;

	uint256 public totalSupply;
	mapping(uint256 => uint256) starCompMap;
	mapping(uint256 => bool) usedStar;

	bytes32 private influencerRoot;
	bytes32 private whitelistRoot;

	constructor(string memory name, string memory symbol, address starAddr) ERC721(name, symbol) {
		star = IERC721(starAddr);
	}

	function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

	// function mint(uint256 tokenId) public {
	// 	_safeMint(msg.sender, tokenId);
	// }

	function holderMint(uint256[] memory ids) public {
		require(totalSupply < 2000, "holderMint : Already all 2000 NFTs were minted.");
		require(mintStage == 0, "holderMint : Mint stage has to set as Holder Mint Stage.");
		for(uint256 i = 0 ; i < ids.length ; i++) {
			require(_checkStarOwner(msg.sender, ids[i]), "holderMint : Only own $STAR can be used to mint.");
			require(!usedStar[ids[i]],  "holderMint : This $STAR token already used.");
		}
		for(uint256 i = 0 ; i < ids.length ; i++) {
			_safeMint(msg.sender, totalSupply+i);
			usedStar[ids[i]] = true;
		}
		totalSupply += ids.length;
	}

	function adminMint(address[] memory wallets, uint256[] memory amounts) public onlyOwner {
		require(totalSupply < 2100, "Admin Mint : Admin mint is 2000 ~ 2099 NFTs.");
		require(mintStage == 1, "Admin Mint : Mint stage has to set as Admin Mint Stage.");
		require(wallets.length == amounts.length, "Admin Mint : Wallet array has to be match amount array.");
		for (uint256 i = 0 ; i < wallets.length ; i++) {
			require(amounts[i] > 0, "Admin Mint : Mint amount has to be greater than zero.");
			for (uint256 j = 0 ; j < amounts[i] ; j++) {
				_safeMint(wallets[i], totalSupply+j);
			}
			totalSupply += amounts[i];
		}
	}

	function influencerMint(uint256 amount, bytes32[] memory proof) public {
		require(amount > 0, "Influencer Mint : Mint amount has to be greater than zero.");
		require(verifyInfluencer(proof), "Influencer Mint : Msg.sender is not registered as Influencer.");
		require(totalSupply < 2200, "Influencer Mint : Influencer mint is 2100 ~ 2199 NFTs.");
		require(mintStage == 2, "Influencer Mint : Mint stage has to set as Influencer Mint Stage.");
		for (uint256 i = 0 ; i < amount ; i++) 
			_safeMint(msg.sender, totalSupply+i);
		totalSupply += amount;
	}

	function whitelistMint(uint256 amount, bytes32[] memory proof) public {
		require(amount > 0, "Whitelist Mint : Mint amount has to be greater than zero.");
		require(verifyWhitelist(proof), "Whitelist Mint : Msg.sender is not registered as Whitelist.");
		require(mintStage == 3, "Whitelist Mint : Mint stage has to set as Whitelist Mint Stage.");
		require(amount < 4, "Whitelist Mint : Maximum mint amount is 3 for Whitelist.");
		for (uint256 i = 0 ; i < amount ; i++) 
			_safeMint(msg.sender, totalSupply+i);
		totalSupply += amount;
	}

	function _checkStarOwner(address minter, uint256 id) private view returns(bool) {
		return (minter == star.ownerOf(id));
	}

	function whiteMint() public {}

	function setMintStage(uint256 stage_) public onlyOwner {
		require(stage_ < 4, "setMintStage : The stage can not be greater than 4.");
		mintStage = stage_;
	}

	function setInfluenceRoot(bytes32 root_) public onlyOwner {
		influencerRoot = root_;
	}

	function verifyInfluencer(bytes32[] memory proof) public view returns(bool) {
		bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
		return MerkleProof.verify(proof, influencerRoot, leaf);
	}

	function setWhitelistRoot(bytes32 root_) public onlyOwner {
		whitelistRoot = root_;
	}

	function verifyWhitelist(bytes32[] memory proof) public view returns(bool) {
		bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
		return MerkleProof.verify(proof, whitelistRoot, leaf);
	}
}
