// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Test721A is ERC721A, Ownable {
    IERC721 star;

    constructor(string memory name, string memory symbol, address starAddr) ERC721A(name, symbol) {
		star = IERC721(starAddr);
	}

    function holderMint(uint256[] memory ids) public {
		for(uint256 i = 0 ; i < ids.length ; i++) {
			require(_checkStarOwner(msg.sender, ids[i]), "holderMint : Only own $STAR can be used to mint.");
		}

		_safeMint(msg.sender, ids.length);
	}

    function _checkStarOwner(address minter, uint256 id) private view returns(bool) {
		return (minter == star.ownerOf(id));
	}
}