// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/access/Ownable.sol';

contract DutchAuction is Ownable {
    IERC721 public nft;
    
    struct Auction {
        uint256 startPrice;
        uint256 interval;
        uint256 discountRate;
        uint256 created;
        uint256 ended;
    }

    mapping(uint256 => Auction) public auctions;

    mapping(uint256 => HighestBid) public bids;

    constructor (address nftAddr_) {
        nft = IERC721(nftAddr_);
    }

    function setAuction(uint256 id, uint256 price, uint256 interval, uint256 discountRate) public onlyOwner {
        require(nft.ownerOf(id) == address(this), '');
        uint256 endedTime = block.timestamp + interval;
        auctions[id] = Auction({
            startPrice: price,
            interval: interval,
            discountRate: discountRate,
            created: block.timestamp,
            ended: endedTime
        });
    }

    function buy(uint256 nftId) public payable {
        require(auctions[nftId].startPrice > 0, "buy : The token is not registered in auction list.");
        require(block.timestamp < auctions[nftId].ended, "buy : Auction is expired.");

        uint256 price = getPrice(nftId);
        require(msg.value > price, "buy : Pay greater or equal ETH than the price.");

        nft.transferFrom(address(this), msg.sender, nftId);
    }

    function getPrice(uint256 nftId) public view returns (uint256) {
        uint timeElapsed = block.timestamp - auctions[nftId].created;
        uint discount = discountRate * timeElapsed;
        return auctions[nftId].startPrice - discount;
    }
}