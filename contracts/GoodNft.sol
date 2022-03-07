// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract GoodNft is ERC721A, Ownable{
	using SafeMath for uint256;
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

	bool public pause = false;

	uint256 public starting_index_block;
	uint256 public starting_index;

	modifier notPaused() {
		require(pause == false, "Mint is paused.");
		_;
	}

	constructor(string memory name, string memory symbol, address starAddr) ERC721A(name, symbol) {
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

	function holderMint(uint256[] memory ids) public notPaused {
		require(ids.length <= maxBatchSize, "holderMint : It is exceed to maxBatchSize.");
		require(totalSupply < 2000, "holderMint : Already all 2000 NFTs were minted.");
		require(mintStage == 0, "holderMint : Mint stage has to set as Holder Mint Stage.");
		for(uint256 i = 0 ; i < ids.length ; i++) {
			require(_checkStarOwner(msg.sender, ids[i]), "holderMint : Only own $STAR can be used to mint.");
			require(!usedStar[ids[i]],  "holderMint : This $STAR token already used.");
		}

		_safeMint(msg.sender, ids.length);

		for(uint256 i = 0 ; i < ids.length ; i++) {
			usedStar[ids[i]] = true;
			starCompMap[ids[i]] = totalSupply+i;
		}
		totalSupply += ids.length;
	}

	function adminMint(address[] memory wallets, uint256[] memory amounts) public onlyOwner notPaused {
		require(totalSupply < 2100, "Admin Mint : Admin mint is 2000 ~ 2099 NFTs.");
		require(mintStage == 1, "Admin Mint : Mint stage has to set as Admin Mint Stage.");
		require(wallets.length == amounts.length, "Admin Mint : Wallet array has to be match amount array.");
		for (uint256 i = 0 ; i < wallets.length ; i++) {
			require(amounts[i] <= maxBatchSize, "Admin Mint : It is exceed to maxBatchSize.");
			require(wallets[i] != address(0x0), "Admin Mint : Wallet address can not be zero.");
			require(amounts[i] > 0, "Admin Mint : Mint amount has to be greater than zero.");
			
			_safeMint(wallets[i], amounts[i]);
			
			totalSupply += amounts[i];
		}
	}

	function influencerMint(uint256 amount, bytes32[] memory proof) public notPaused {
		require(amount <= maxBatchSize, "Influencer Mint : It is exceed to maxBatchSize.");
		require(amount > 0, "Influencer Mint : Mint amount has to be greater than zero.");
		require(verifyInfluencer(proof), "Influencer Mint : Msg.sender is not registered as Influencer.");
		require(totalSupply < 2200, "Influencer Mint : Influencer mint is 2100 ~ 2199 NFTs.");
		require(mintStage == 2, "Influencer Mint : Mint stage has to set as Influencer Mint Stage.");
			
		_safeMint(msg.sender, amount);

		totalSupply += amount;
	}

	function whitelistMint(bytes32[] memory proof, uint256 level) public payable notPaused {
		require(verifyWhitelist(proof, level), "Whitelist Mint : Msg.sender is not registered as Whitelist Level - 1.");
		require(totalSupply < maxSupply, "Whitelist Mint : Already all 10K NFTs are minted.");
		require(mintStage == 3, "Whitelist Mint : Mint stage has to set as Whitelist Mint Stage.");
		require(msg.value == level * presalePrice, "Whitelist Mint : One NFT is 0.042 ETH. Please send correct value for 2 NFT.");

		_safeMint(msg.sender, level);
		totalSupply = totalSupply + level;
	}

	function publicSale() public onlyOwner notPaused {
		require(totalSupply < maxSupply, "Public Sale : Already all 10K NFTs are minted.");
		require(mintStage == 4, "Public Sale : Mint stage has to set as public sale Stage.");
		require(auctionAddress != address(0x0), "Public Sale : Auction contract address is not defined.");
		
		_safeMint(auctionAddress, maxSupply - totalSupply);
		
		if (starting_index_block == 0 && (totalSupply == maxSupply))
		{
			starting_index_block = block.number;
		}
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

	function setPause(bool pause_) public onlyOwner {
		pause = pause_;
	}

	function finalizeStartingIndex() public
	{
		require(starting_index == 0, "Starting index already set");
		require(starting_index_block != 0, "Starting index block not set");

		starting_index = uint256(blockhash(starting_index_block)) % maxSupply;

		if (block.number.sub(starting_index_block) > 255)
		{
			starting_index = uint256(blockhash(block.number-1)) % maxSupply;
		}

		if (starting_index == 0)
		{
			starting_index = starting_index.add(1);
		}
	}

	function emergencySetStartingIndexBlock() public onlyOwner
	{
		require(starting_index == 0, "Starting index is already set");
		starting_index_block = block.number;
	}
}
