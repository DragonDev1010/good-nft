// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract GoodNft is ERC721, Ownable{
	IERC721 star;
	string public baseURI;

	uint256 public mintStage;

	uint256 public presalePrice = 0.042 ether;
	uint256 public maxSupply = 10000;
	uint256 public totalSupply;

	mapping(uint256 => uint256) public starCompMap;
	mapping(uint256 => bool) public usedStar;

	bytes32 private influencerRoot;

	bytes32 private whitelistRoot;

	address public auctionAddress;

	constructor(string memory name, string memory symbol, address starAddr) ERC721(name, symbol) {
		star = IERC721(starAddr);
	}

	receive() external payable {}
	function withdrawAll() external onlyOwner{
        uint256 amount = address(this).balance;
        payable(owner()).transfer(amount);
    }

	function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

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
			starCompMap[ids[i]] = totalSupply+i;
		}
		totalSupply += ids.length;
	}

	function adminMint(address[] memory wallets, uint256[] memory amounts) public onlyOwner {
		require(totalSupply < 2100, "Admin Mint : Admin mint is 2000 ~ 2099 NFTs.");
		require(mintStage == 1, "Admin Mint : Mint stage has to set as Admin Mint Stage.");
		require(wallets.length == amounts.length, "Admin Mint : Wallet array has to be match amount array.");
		for (uint256 i = 0 ; i < wallets.length ; i++) {
			require(wallets[i] != address(0x0), "Admin Mint : Wallet address can not be zero.");
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

	function whitelistMint(uint256 amount, bytes32[] memory proof, uint256 level) public payable {
		require(verifyWhitelist(proof, level), "Whitelist Mint : Msg.sender is not registered as Whitelist Level - 1.");
		require(amount > 0, "Whitelist Mint : Mint amount has to be greater than zero.");
		require(totalSupply < maxSupply, "Whitelist Mint : Already all 10K NFTs are minted.");
		require(mintStage == 3, "Whitelist Mint : Mint stage has to set as Whitelist Mint Stage.");

		if(level == 1) {
			require(amount == 1, "Whitelist Mint : Whitelist Level-1 can mint only 1 NFT.");	
			require(msg.value == presalePrice, "Whitelist Mint : One NFT is 0.042 ETH. Please send correct value for 1 NFT.");
			// require(verifyWhitelist(proof), "Whitelist Mint : Msg.sender is not registered as Whitelist Level - 1.");
			
			_safeMint(msg.sender, totalSupply);
			totalSupply = totalSupply + 1;
		} else if (level == 2) {
			require(amount == 2, "Whitelist Mint : Whitelist Level-2 can mint only 2 NFT.");
			require(msg.value == 2 * presalePrice, "Whitelist Mint : One NFT is 0.042 ETH. Please send correct value for 2 NFT.");
			// require(verifyWhitelist(proof), "Whitelist Mint : Msg.sender is not registered as Whitelist Level - 2.");	
			
			for (uint256 i = 0 ; i < 2 ; i++) 
				_safeMint(msg.sender, totalSupply+i);
			totalSupply += 2;
		} else {
			require(amount == 3, "Whitelist Mint : Whitelist Level-3 can mint only 3 NFT.");
			require(msg.value == 3 * presalePrice, "Whitelist Mint : One NFT is 0.042 ETH. Please send correct value for 3 NFT.");
			// require(verifyWhitelist(proof), "Whitelist Mint : Msg.sender is not registered as Whitelist Level - 3.");	
			
			for (uint256 i = 0 ; i < 3 ; i++) 
				_safeMint(msg.sender, totalSupply+i);
			totalSupply += 3;
		}
	}

	function publicSale() public onlyOwner{
		require(totalSupply < maxSupply, "Public Sale : Already all 10K NFTs are minted.");
		require(mintStage == 4, "Public Sale : Mint stage has to set as public sale Stage.");
		require(auctionAddress != address(0x0), "Public Sale : Auction contract address is not defined.");
		for(uint256 i = totalSupply ; i < maxSupply ; i++)
			_safeMint(auctionAddress, totalSupply+i);
	}

	function _checkStarOwner(address minter, uint256 id) private view returns(bool) {
		return (minter == star.ownerOf(id));
	}


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

	function verifyWhitelist(bytes32[] memory proof, uint256 lvl) public view returns(bool) {
		bytes32 leaf = keccak256(abi.encodePacked(msg.sender, lvl));
		return MerkleProof.verify(proof, whitelistRoot, leaf);
	}

	function setAuctionAddress(address auction_) public onlyOwner {
		auctionAddress = auction_;
	}
}
