// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Mum2 is ERC721A, Ownable
{
	using SafeMath for uint256;

	IERC721 starContract;

	string public baseURI;
	string public provenanceHash;

	uint256 public maxSupply = 10000;
	uint256 public maxBatchAmount = 50;

	uint256 public holderMintedAmount;
	uint256 public adminMintedAmount;
	uint256 public whitelistMintedAmount;
	uint256 public publicMintedAmount;

	uint256 public whitelistMintPrice = 0.042 ether;
	uint256 public publicMintPrice;
	uint256 public publicMaxPerTransaction = 10;
	uint256 public startingIndexBlock;
	uint256 public startingIndex;

	bool public holderMintActive = false;
	bool public whitelistMintActive = false;
	bool public publicMintActive = false;

	mapping(uint256 => bool) public usedStarIds;
	mapping(uint256 => uint256) public matchStarComp;
	mapping(address => bool) public mintedWhitelist;

	bytes32 private whitelistRoot;
	bytes32 private tieredWhitelistRoot;


	/**
	* @dev Mum2 Name.
	*/
	constructor() ERC721A("Mum2 Name", "Mum2 Symbol") {}


	/**
	* @dev Calculate the total amount minted so far.
	*/
	// function totalSupply() public view returns (uint256)
	// {
	// 	return holderMintedAmount.add(adminMintedAmount).add(whitelistMintedAmount).add(publicMintedAmount);
	// }


	/**
	* @dev Holders of the Star NFTs can mint 1 free per Star they own.
	*/
	function holderMint(uint256[] memory _ids) public
	{
		require(holderMintActive, "Holder mint is paused.");
		require(_ids.length <= maxBatchAmount, "Can't mint that many.");

		for (uint256 i=0; i<_ids.length; i++)
		{
			require(starContract.ownerOf(_ids[i]) == msg.sender, "You don't own this one.");
			require(!usedStarIds[_ids[i]], "This one was already used for minting.");
		}

		_safeMint(msg.sender, _ids.length);

		for (uint256 i=0; i<_ids.length; i++)
		{
			usedStarIds[_ids[i]] = true;
			matchStarComp[_ids[i]] = holderMintedAmount + i;
		}

		holderMintedAmount += _ids.length;
	}


	/**
        * @dev Whitelisted wallets.
        */
	function whitelistMint(bytes32[] memory _proof, uint256 _num_tokens) public payable
	{
		require(whitelistMintActive, "Whitelist mint is paused.");
		require(msg.value == _num_tokens.mul(whitelistMintPrice), "Insufficient funds.");
		require(mintedWhitelist[msg.sender] != true, "This wallet already minted");

		bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
		require(MerkleProof.verify(_proof, whitelistRoot, leaf), "Invalid proof.");

		_safeMint(msg.sender, _num_tokens);

		mintedWhitelist[msg.sender] = true;
		whitelistMintedAmount += _num_tokens;
	}


	/**
        * @dev Whitelisted wallets with Tiers.
        */
	function tieredWhitelistMint(bytes32[] memory _proof, uint256 _num_tokens) public payable
	{
		require(whitelistMintActive, "Whitelist mint is paused.");
		require(msg.value == _num_tokens.mul(whitelistMintPrice), "Insufficient funds.");
		require(mintedWhitelist[msg.sender] != true, "This wallet already minted");

		bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _num_tokens));
		require(MerkleProof.verify(_proof, tieredWhitelistRoot, leaf), "Invalid proof.");

		_safeMint(msg.sender, _num_tokens);

		mintedWhitelist[msg.sender] = true;
		whitelistMintedAmount += _num_tokens;
	}


	/**
        * @dev Public mint.
        */
	function publicMint(uint256 _num_tokens) public payable
	{
		require(publicMintActive, "Public mint is paused.");
		require(publicMintPrice > 0, "Public mint price not set.");
		require(_num_tokens <= publicMaxPerTransaction, "Can't mint that many at once.");
		require(msg.value == publicMintPrice.mul(_num_tokens), "Insufficient funds.");
		require(getTotalSupply().add(_num_tokens) <= maxSupply, "Can't mint that many.");

		_safeMint(msg.sender, _num_tokens);

		publicMintedAmount += _num_tokens;

		if (startingIndexBlock == 0 && (getTotalSupply().add(_num_tokens) == maxSupply))
		{
			startingIndexBlock = block.number;
		}
	}


	/**
        * @dev Admin mint.
        */
	function adminMint(address _to, uint256 _num_tokens) public onlyOwner
	{
		require(_num_tokens <= maxBatchSize, "Can't mint that many.");

		_safeMint(_to, _num_tokens);

		adminMintedAmount += _num_tokens;
	}


	/**
        * @dev Link to the other NFT contract to check ownership during holderMint.
        */
	function setStarContract(address _addr) public onlyOwner
	{
		starContract = IERC721(_addr);
	}


	/**
        * @dev Set the Merkle Root for the Whitelist.
        */
	function setWhitelistMerkleRoot(bytes32 _root) public onlyOwner
	{
		whitelistRoot = _root;
	}


	/**
        * @dev Set the Merkle Root for the Tiered Whitelist.
        */
	function setTieredWhitelistMerkleRoot(bytes32 _root) public onlyOwner
	{
		tieredWhitelistRoot = _root;
	}


	/**
        * @dev Toggle the Holder Mint status.
        */
	function toggleHolderMint() public onlyOwner
	{
		holderMintActive = !holderMintActive;
	}


	/**
        * @dev Toggle the Whitelist Mint status.
        */
	function toggleWhitelistMint() public onlyOwner
	{
		whitelistMintActive = !whitelistMintActive;
	}


	/**
        * @dev Toggle the Public Mint status.
        */
	function togglepublicMint() public onlyOwner
	{
		publicMintActive = !publicMintActive;
	}


	/**
        * @dev Set the cost of the tokens for the public mint.
        */
	function setPublicMintPrice(uint256 _price) public onlyOwner
	{
		publicMintPrice = _price;
	}


	/**
        * @dev Update the BaseURI for the reveals.
        */
	function setBaseURI(string memory _newBaseURI) public onlyOwner
	{
		baseURI = _newBaseURI;
	}


	/**
        * @dev Get the Base URI.
        */
	function _baseURI() internal view virtual override returns (string memory)
	{
		return baseURI;
	}


	/**
        * @dev Finalize starting index.
        */
	function finalizeStartingIndex() public onlyOwner
	{
		require(startingIndex == 0, "Starting index already set.");
		require(startingIndexBlock != 0, "Starting index block not set.");

		startingIndex = uint256(blockhash(startingIndexBlock)) % maxSupply;

		if (block.number.sub(startingIndexBlock) > 255)
		{
			startingIndex = uint256(blockhash(block.number.sub(1))) % maxSupply;
		}

		if (startingIndex == 0)
		{
			startingIndex = startingIndex.add(1);
		}
	}


	/**
	 * @dev Set the starting index block for the collection, essentially unblocking setting starting index.
	 */
	function emergencySetStartingIndexBlock() public onlyOwner
	{
		require(startingIndex == 0, "Starting index already set.");

		startingIndexBlock = block.number;
	}


	/**
	 * @dev Set provenance once it's calculated.
	 *
	 * @param _provenance_hash string memory
	 */
	function setProvenanceHash(string memory _provenance_hash) public onlyOwner
	{
		provenanceHash = _provenance_hash;
	}


	/**
        * @dev Withdraw the balance from the contract.
        */
	function withdraw() public onlyOwner
	{
		uint256 balance = address(this).balance;
		require(balance > 0, "Balance is 0");
		payable(msg.sender).transfer(balance);
	}
}