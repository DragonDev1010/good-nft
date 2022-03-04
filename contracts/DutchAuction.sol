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

    uint256 public maxBuyAmount;

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

    function batchBuy(uint256[] memory nftIds) public payable {
        require(nftIds.length < maxBuyAmount, "batchBuy : It is exceed to maxBuyAmount.");
        uint256 price;
        for(uint256 i = 0 ; i < nftIds.length ; i++) {
            require(auctions[nftIds[i]].startPrice > 0, "batchBuy : The token is not registered in auction list.");
            require(block.timestamp < auctions[nftIds[i]].ended, "batchBuy : Auction is expired.");

            price += getPrice(nftIds[i]);
            require(msg.value > price, "buy : Pay greater or equal ETH than the price.");
        }

        for(uint256 j = 0 ; j < nftIds.length ; j++)
            nft.transferFrom(address(this), msg.sender, nftIds[j]);
    }

    function getPrice(uint256 nftId) public view returns (uint256) {
        uint timeElapsed = block.timestamp - auctions[nftId].created;
        uint discount = auctions[nftId].discountRate * timeElapsed;
        return auctions[nftId].startPrice - discount;
    }

    function setMaxBuyAmount(uint256 max_) public onlyOwner {
        maxBuyAmount = max_;
    }
}