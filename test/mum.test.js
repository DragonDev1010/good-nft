const {MerkleTree} = require("merkletreejs")
const keccak256 = require("keccak256")
const { soliditySha3 } = require("web3-utils");

require('chai')
    .use(require('chai-as-promised'))
    .should()

const {assert} = require('chai')

const Comp = artifacts.require('./Mum.sol')
const Star = artifacts.require('./Star.sol')

contract('Comp NFT', (accounts) => {
    let res
    let comp, star
    
    let admin = accounts[9]
    const influencers = [ accounts[0], accounts[1] ]
    const whitelist = [
        {"wallet": accounts[2], "level": 1},
        {"wallet": accounts[3], "level": 1},
        {"wallet": accounts[4], "level": 2},
        {"wallet": accounts[5], "level": 2},
        {"wallet": accounts[6], "level": 3},
        {"wallet": accounts[7], "level": 3},
    ]

    let influencerMerkle, whitelistMerkle

    const makeInfluencerMerkle = () => {
        let leafNodes = influencers.map(item => keccak256(item))
        influencerMerkle = new MerkleTree(leafNodes, keccak256, {sortPairs: true})
    }

    const makeWhitelistMerkle = () => {
        let leafNodes = whitelist.map(item => soliditySha3(item.wallet, item.level))
        whitelistMerkle = new MerkleTree(leafNodes, keccak256, {sortPairs: true})
    }

    before(async() => {
        comp = await Comp.deployed()
        star = await Star.deployed()

        await comp.transferOwnership(admin)

        makeWhitelistMerkle()
        makeInfluencerMerkle()
    })

    it('mint star nft', async() => {
        await star.mint(10, {from: accounts[0]})
        await star.mint(10, {from: accounts[1]})
    })

    it('get Star contract', async() => {
        await comp.getStarContract(star.address, {from: admin})
    })

    it('pause mint', async() => {
        
    })

    it('holder mint', async() => {
        await comp.holderMint([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], {from: accounts[0]})

        let usedStarIds_0 = await comp.usedStarIds.call(0)
        assert.equal(usedStarIds_0, true, "Star 0 is already used.")

        let matchStarComp_0 = await comp.matchStarComp.call(0)
        assert.equal(matchStarComp_0, 0, "Star 0 is matched Comp 0.")
    })

    it('admin mint', async() => {
        await comp.adminMint(35, {from: admin})
        await comp.adminMint(35, {from: admin})
        await comp.adminMint(30, {from: admin})
    })

    it('set influencer merkle tree', async() => {
        let influencerTreeRoot = influencerMerkle.getRoot()
        await comp.setInfluenceRoot(influencerTreeRoot, {from: admin})
    })

    it('influencer mint', async() => {
        let proof = influencerMerkle.getHexProof(keccak256(influencers[0]))
        await comp.influencerMint(3, proof, {from: influencers[0]})
    })

    it('set whitelist merkle tree', async() => {
        let merkleTreeRoot = whitelistMerkle.getRoot()
        await comp.setWhitelistRoot(merkleTreeRoot, {from: admin})
    })

    it('whitelist mint', async() => {
        let proof = whitelistMerkle.getHexProof(soliditySha3(whitelist[0].wallet, whitelist[0].level))
        let level = whitelist[0].level
        await comp.whitelistMint(proof, level, {from: whitelist[0].wallet, value: web3.utils.toWei("0.042", "ether")})
    })

    it('public sale', async() => {
        let totalMinted = await comp.getTotalMinted()
        let remaining = 10000 - totalMinted

        await comp.setPriceForRemaining(web3.utils.toWei("0.1", "ether"), {from: admin})

        await comp.publicSaleMint(100, {from: accounts[0], value: web3.utils.toWei("10", "ether")})
    })
})