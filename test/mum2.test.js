const {MerkleTree} = require("merkletreejs")
const keccak256 = require("keccak256")
const { soliditySha3 } = require("web3-utils");

const {assert} = require("chai")

const Mum2 = artifacts.require("Mum2.sol")
const Star = artifacts.require("Star.sol")
contract("Mum2 contract", (accounts) => {
    let tx, mum2, star
    let w1Merkle, w2Merkle

    let publicSalePrice = 0.06

    let holder = [accounts[1], accounts[2]]
    let adminReceiver = [accounts[3], accounts[4]]
    let whitelist_1 = [accounts[5], accounts[6]]
    let tierWhitelist = [
        {"wallet": accounts[7], "amount": 100},
        {"wallet": accounts[8], "amount": 400}
    ]

    const makeMerkleForW1 = () => {
        let leafNodes = whitelist_1.map(item => keccak256(item))
        w1Merkle = new MerkleTree(leafNodes, keccak256, {sortPairs: true})
    }

    const makeMerkleForW2 = () => {
        let leafNodes = tierWhitelist.map(item => soliditySha3(item.wallet, item.amount))
        w2Merkle = new MerkleTree(leafNodes, keccak256, {sortPairs: true})
    }

    before(async() => {
        mum2 = await Mum2.deployed()
        star = await Star.deployed()
        makeMerkleForW1()
        makeMerkleForW2()
    })

    it("star token", async() => {
        await star.mint(50, {from: holder[0]})

    })

    it("holder mint", async() => {
        await mum2.setStarContract(star.address)
        await mum2.toggleHolderMint()
        let ids = []
        for (let i = 0 ; i < 50 ; i++)
            ids.push(i)
        await mum2.holderMint(ids, {from: holder[0]})

        let currentIndex = await mum2.getTotalSupply()
        assert.equal(currentIndex, 50, "current index")

        let holderMintedAmount = await mum2.holderMintedAmount()
        assert.equal(holderMintedAmount, 50, "holderMintedAmount")

        let usedStarId_0 = await mum2.usedStarIds(0)
        assert.equal(usedStarId_0, true, "usedStarId_0")

        let usedStarId_49 = await mum2.usedStarIds(49)
        assert.equal(usedStarId_49, true, "usedStarId_49")

        let usedStarId_50 = await mum2.usedStarIds(50)
        assert.equal(usedStarId_50, false, "usedStarId_50")

        let matchStarComp_0 = await mum2.matchStarComp(0)
        assert.equal(matchStarComp_0, 0, "matchStarComp 0")

        let matchStarComp_49 = await mum2.matchStarComp(49)
        assert.equal(matchStarComp_49, 49, "matchStarComp 49")

        let matchStarComp_50 = await mum2.matchStarComp(50)
        assert.equal(matchStarComp_50, 0, "matchStarComp 50")
    })

    it("admin mint", async() => {
        await mum2.adminMint(adminReceiver[0], 400)

        let currentIndex = await mum2.getTotalSupply()
        assert.equal(currentIndex, 450, "current index")

        let adminMintedAmount = await mum2.adminMintedAmount()
        assert.equal(adminMintedAmount, 400, "adminMintedAmount")

        await mum2.adminMint(adminReceiver[1], 100)

        currentIndex = await mum2.getTotalSupply()
        assert.equal(currentIndex, 550, "current index")

        adminMintedAmount = await mum2.adminMintedAmount()
        assert.equal(adminMintedAmount, 500, "adminMintedAmount")
    })

    it("non-tier whitelist mint", async() => {
        await mum2.toggleWhitelistMint()

        let root = w1Merkle.getRoot()
        await mum2.setWhitelistMerkleRoot(root)

        let proof = w1Merkle.getHexProof(keccak256(whitelist_1[0]))
        let cost = 0.042 * 50
        cost = cost.toString()
        await mum2.whitelistMint(proof, 50, {from: whitelist_1[0], value: web3.utils.toWei(cost, "ether")})

        let currentIndex = await mum2.getTotalSupply()
        assert.equal(currentIndex, 600, "current index")

        let mintedWhitelist_0 = await mum2.mintedWhitelist(whitelist_1[0])
        assert.equal(mintedWhitelist_0, true, "mintedWhitelist 0")

        let whitelistMintedAmount = await mum2. whitelistMintedAmount()
        assert.equal(whitelistMintedAmount, 50, "whitelistMintedAmount")
    })

    it("tier whitelist mint", async() => {
        let root = w2Merkle.getRoot()
        await mum2.setTieredWhitelistMerkleRoot(root)

        let proof = w2Merkle.getHexProof(soliditySha3(tierWhitelist[0].wallet, tierWhitelist[0].amount))
        let cost = 0.042 * 100
        cost = cost.toString()
        await mum2.tieredWhitelistMint(proof, 100, {from: tierWhitelist[0].wallet, value: web3.utils.toWei(cost, "ether")})

        let currentIndex = await mum2.getTotalSupply()
        assert.equal(currentIndex, 700, "current index")

        let mintedWhitelist_0 = await mum2.mintedWhitelist(tierWhitelist[0].wallet)
        assert(mintedWhitelist_0, true, "whitelistMintedAmount")

        let whitelistMintedAmount = await mum2.whitelistMintedAmount()
        assert.equal(whitelistMintedAmount, 150, "whitelistMintedAmount")
    })

    it('public sale', async() => {
        await mum2.setPublicMintPrice(web3.utils.toWei(publicSalePrice.toString(), "ether"))
        await mum2.togglepublicMint()

        for(let i = 0 ; i < 30 ; i++) {
            let idx = i % 9 + 1
            await mum2.publicMint(10, {from: accounts[idx], value: web3.utils.toWei("0.6", "ether")})
        }

        let currentIndex = await mum2.getTotalSupply()
        assert.equal(currentIndex, 1000, "current index")

        let startingIndexBlock = await mum2.startingIndexBlock()
    })

    it('set base uri', async() => {
        const baseUri = "ipfs://234jlk2j34m,.j2k34j"
        await mum2.setBaseURI(baseUri)

        let uri_0 = await mum2.tokenURI(0)
        assert.equal(uri_0, baseUri+"0", "token uri")
    })

    it("withdraw", async() => {
        let prevBal = await web3.eth.getBalance(accounts[0])

        await mum2.withdraw()

        let afterBal = await web3.eth.getBalance(accounts[0])

        console.log((afterBal-prevBal))
    })
})