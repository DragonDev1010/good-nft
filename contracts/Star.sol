// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

contract Star is ERC721{

    uint256 mintedAmount;

    constructor() ERC721("Star Test", "TEST") {}

    function mint(uint256 amount) public {
        for (uint256 i = 0 ; i < amount ; i++)
            _safeMint(msg.sender, mintedAmount + i);
        mintedAmount += amount;
    }
}