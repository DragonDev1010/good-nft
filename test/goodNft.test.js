require('chai')
    .use(require('chai-as-promised'))
    .should()

const {assert} = require('chai')
// const { MerkleTree } = require('./Merkle/merkleTree.js');
// const {Server} = require('./HoldToken/server.js')
const NFT = artifacts.require('./GoodNft.sol')
const starOwnersById = require('./HoldToken/wallets.json')

contract('NFT contract', (accounts) => {
    let res, gasEstimate
    let nft
    let adminMintWallets = [accounts[1], accounts[2], accounts[3]]
    let adminMintAmounts = [3, 4, 5]

    let starHolder_1 = "0x8090dd2831092d07c013e8252cd7a19f9149e2ea"
    let starHolder_2 = "0xa784779bd895b2db4c0009a7468f090012e12ff9"
    let starHolder_3 = "0x7c2845d6b48cb2feb76532558e2033c145745e35"

    let ownedStar_1 = []
    let ownedStar_2 = []
    let ownedStar_3 = []

    function spliteChunk(ids) {
        let chunkArray = []
        let i,j, chunk = 35;
        let temporary = []
        for (i = 0,j = ids.length; i < j; i += chunk) {
            temporary = ids.slice(i, i + chunk);
            chunkArray.push(temporary)
        }
        return chunkArray
    }

    before(async() => {
        nft = await NFT.deployed()
        
        for(let i = 0 ; i < 2000 ; i++) {
            if(starOwnersById[i].wallet_address.toLowerCase() == starHolder_1.toLowerCase()) {
                ownedStar_1.push(i)
            }

            if(starOwnersById[i].wallet_address.toLowerCase() == starHolder_2.toLowerCase()) {
                ownedStar_2.push(i)
            }

            if(starOwnersById[i].wallet_address.toLowerCase() == starHolder_3.toLowerCase()) {
                ownedStar_3.push(i)
            }
        }

    })

    it('Holder mint', async() => {
        let chunk = []
        chunk = spliteChunk(ownedStar_1)

        for(let i = 0 ; i < chunk.length ; i++) {
            gasEstimate = await nft.holderMint.estimateGas(chunk[i], {from: starHolder_1})
            console.log(gasEstimate)
            await nft.holderMint(chunk[i], {from: starHolder_1})
        }
    })

    // it('Admin mint', async() => {
    //     res = await nft.mintStage.call()
    //     assert.equal(res, 0, 'mint stage is zero (admin mint stage)')

    //     await nft.adminMint(adminMintWallets, adminMintAmounts)

    //     res = await nft.ownerOf(0)
    //     assert.equal(res, adminMintWallets[0])
    //     res = await nft.ownerOf(1)
    //     assert.equal(res, adminMintWallets[0])
    //     res = await nft.ownerOf(2)
    //     assert.equal(res, adminMintWallets[0])
    //     res = await nft.balanceOf(adminMintWallets[0])
    //     assert.equal(res, adminMintAmounts[0])

    //     res = await nft.ownerOf(3)
    //     assert.equal(res, adminMintWallets[1])
    //     res = await nft.ownerOf(4)
    //     assert.equal(res, adminMintWallets[1])
    //     res = await nft.ownerOf(5)
    //     assert.equal(res, adminMintWallets[1])
    //     res = await nft.ownerOf(6)
    //     assert.equal(res, adminMintWallets[1])
    //     res = await nft.balanceOf(adminMintWallets[1])
    //     assert.equal(res, adminMintAmounts[1])
        
    //     res = await nft.ownerOf(7)
    //     assert.equal(res, adminMintWallets[2])
    //     res = await nft.ownerOf(8)
    //     assert.equal(res, adminMintWallets[2])
    //     res = await nft.ownerOf(9)
    //     assert.equal(res, adminMintWallets[2])
    //     res = await nft.ownerOf(10)
    //     assert.equal(res, adminMintWallets[2])
    //     res = await nft.ownerOf(11)
    //     assert.equal(res, adminMintWallets[2])
    //     res = await nft.balanceOf(adminMintWallets[2])
    //     assert.equal(res, adminMintAmounts[2])
    // })

    // it('set base uri', async() => {
    //     await nft.setBaseURI("https://baseuri/")
    //     res = await nft.tokenURI(0)
    //     assert.equal(res, 'https://baseuri/0', 'set base uri')
    // })
})