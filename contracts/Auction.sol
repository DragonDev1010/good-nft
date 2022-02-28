// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/access/Ownable.sol';

contract Auction {
    IERC721 public nft;
    
    struct Auction {
        uint256 startPrice;
        address creator;
        uint256 interval;
        uint256 created;
    }

    mapping(uint256 => Auction) public auctions;

    struct HighestBid {
        uint256 price;
        address bidder;
    }

    mapping(uint256 => HighestBid) public bids;

    constructor (address nftAddr_) {
        nft = IERC721(nftAddr_);
    }

    function setAuction(uint256 id, uint256 price, uint256 interval) public onlyOwner {
        require(nft.ownerOf(id) == address(this), '');
        require(auctions[id].price == 0, '');
        auctions[id] = Auction({
            startPrice: price,
            creator: msg.sender,
            interval: interval,
            created: block.timestamp
        });
    }

    function bid(uint256 id, uint256 price) public payable{
        require(nft.ownerOf(id) == address(this), "");
        require(auctions[id].price == 0, '');
        require(price > bids(id).price, "");
        
    }

    function sell(uint256 id) public {
        
    }
}