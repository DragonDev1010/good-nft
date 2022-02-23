require('chai')
    .use(require('chai-as-promised'))
    .should()

const {assert} = require('chai')
const { MerkleTree } = require('./helper/merkleTree.js');
const NFT = artifacts.require('./GoodNft.sol')

contract('NFT contract', (accounts) => {
    let res
    let nft
    let adminMintWallets = [accounts[1], accounts[2], accounts[3]]
    let adminMintAmounts = [3, 4, 5]
    before(async() => {
        nft = await NFT.deployed()
    })

    it('Admin mint', async() => {
        res = await nft.mintStage.call()
        assert.equal(res, 0, 'mint stage is zero (admin mint stage)')

        await nft.adminMint(adminMintWallets, adminMintAmounts)

        res = await nft.ownerOf(0)
        assert.equal(res, adminMintWallets[0])
        res = await nft.ownerOf(1)
        assert.equal(res, adminMintWallets[0])
        res = await nft.ownerOf(2)
        assert.equal(res, adminMintWallets[0])
        res = await nft.balanceOf(adminMintWallets[0])
        assert.equal(res, adminMintAmounts[0])

        res = await nft.ownerOf(3)
        assert.equal(res, adminMintWallets[1])
        res = await nft.ownerOf(4)
        assert.equal(res, adminMintWallets[1])
        res = await nft.ownerOf(5)
        assert.equal(res, adminMintWallets[1])
        res = await nft.ownerOf(6)
        assert.equal(res, adminMintWallets[1])
        res = await nft.balanceOf(adminMintWallets[1])
        assert.equal(res, adminMintAmounts[1])
        
        res = await nft.ownerOf(7)
        assert.equal(res, adminMintWallets[2])
        res = await nft.ownerOf(8)
        assert.equal(res, adminMintWallets[2])
        res = await nft.ownerOf(9)
        assert.equal(res, adminMintWallets[2])
        res = await nft.ownerOf(10)
        assert.equal(res, adminMintWallets[2])
        res = await nft.ownerOf(11)
        assert.equal(res, adminMintWallets[2])
        res = await nft.balanceOf(adminMintWallets[2])
        assert.equal(res, adminMintAmounts[2])
    })

    // it('set base uri', async() => {
    //     await nft.setBaseURI("https://baseuri/")
    //     res = await nft.tokenURI(0)
    //     assert.equal(res, 'https://baseuri/0', 'set base uri')
    // })
})