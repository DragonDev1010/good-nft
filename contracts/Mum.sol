// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Mum is ERC721A, Ownable{
    using SafeMath for uint256;

    IERC721 starContract;

    string public baseURI;
    bool public paused;

    uint256 public maxSupply = 10000;
    uint256 public maxBatchAmount = 35;

    // holder, admin, influencer, whitelist, public
    bool[4] public mintPaused = [false, false, false, false];

    uint256 public holderMintedAmount;
    mapping(uint256 => bool) public usedStarIds;
    mapping(uint256 => uint256) public matchStarComp;

    uint256 public adminMintedAmount;


    bytes32 private influencerRoot;
    uint256 public maxInfluencerMintAmount = 100;
    uint256 public influencerMinteAmount;

    bytes32 private whitelistRoot;
    uint256 public whitelistPrice = 0.042 ether;
    uint256 public whitelistMintedAmount;

    uint256 public publicSoldAmount;
    uint256 public publicPrice;

    constructor(string memory name, string memory symbol) ERC721A(name, symbol) {}

    function setPaused(bool s_) public onlyOwner {
        paused = s_;
    }

    modifier emergencyPause {
        require(!paused, "Emergency Pause");
        _;
    }

    receive() external payable {}

	function withdrawAll() external onlyOwner{
        uint256 amount = address(this).balance;
        payable(owner()).transfer(amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function getStarContract(address addr_) public onlyOwner {
        starContract = IERC721(addr_);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMintPaused(uint256 stage, bool s) public onlyOwner {
        mintPaused[stage] = s;
    }

    function getTotalMinted() public view returns (uint256) {
        return holderMintedAmount.add(adminMintedAmount).add(influencerMinteAmount).add(whitelistMintedAmount).add(publicSoldAmount);
    }

    function holderMint(uint256[] memory ids) public emergencyPause {
        require(!mintPaused[0], "Holder Mint is paused.");
        require( ids.length <= maxBatchAmount, "holderMint : You can not mint more than 35 NFTs in one transaction." );
        for ( uint256 i = 0 ; i < ids.length ; i++ ) {
            require( starContract.ownerOf(ids[i]) == msg.sender, "holderMint : You are not owner of this $STAR tokens.");
            require( !usedStarIds[ids[i]], "holderMint : Some of $STAR tokens already used to mint new NFTs.");
        }

        _safeMint(msg.sender, ids.length);

        for ( uint256 i = 0 ; i < ids.length ; i++ ) {
            usedStarIds[ ids[i] ] = true;
            matchStarComp[ ids[i] ] = holderMintedAmount + i;
        }

        holderMintedAmount += ids.length;
    }

    function adminMint(uint256 amount) public emergencyPause onlyOwner {
        require( amount <= maxBatchAmount, "Can not mint more than 35 NFTs per one transaction.");

        uint256 estimated = adminMintedAmount.add(amount);
        require( estimated <= 100, "If you mint anymore, Admin_Mint_NFT is exceed to 100 NFTs.");
        _safeMint(msg.sender, amount);
        adminMintedAmount += amount;
    }

    function influencerMint(uint256 amount, bytes32[] memory proof) public emergencyPause {
        require(!mintPaused[1], "Influencer Mint is paused.");
        uint256 estimatedAmount = influencerMinteAmount + amount;
        require(estimatedAmount <= maxInfluencerMintAmount, "Influencers already minted 100 NFTs.");
        require(amount < maxBatchAmount, "Can mint at most 35 NFTs in one transaction");
        require(_verifyInfluencer(proof), "Msg.sender is not registered as Influencer.");

        _safeMint(msg.sender, amount);

        influencerMinteAmount += amount;
    }

    function whitelistMint(bytes32[] memory proof, uint256 level) public payable emergencyPause {
        require(!mintPaused[2], "Whitelist Mint is paused.");
        require(verifyWhitelist(proof, level), "Whitelist Mint : You are not allowed in whitelist mint.");
        uint256 cost = level.mul(whitelistPrice);
        require(msg.value == cost, "Whitelist Mint : Not enough fund approved. One NFT is 0.042 ETH.");

        _safeMint(msg.sender, level);
        whitelistMintedAmount += level;
    }

    function publicSaleMint(uint256 amount) public payable emergencyPause {
        require(!mintPaused[3], "Public sale is paused.");
        require(publicPrice > 0, "Public sale price is not yet defined");
        uint256 estimatedTotal = getTotalMinted().add(amount);
        require( estimatedTotal <= maxSupply, "All 10000 NFTs are already minted or amount is too many.");
        uint256 cost = publicPrice.mul(amount);
        require( msg.value == cost, "Not enough found.");
        _safeMint(msg.sender, amount);
        publicSoldAmount += amount;
    }

    function setPriceForRemaining (uint256 price) public onlyOwner {
        publicPrice = price;
    }

    function setInfluenceRoot(bytes32 root_) public onlyOwner {
		influencerRoot = root_;
	}

	function _verifyInfluencer(bytes32[] memory proof) private view returns(bool) {
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
}