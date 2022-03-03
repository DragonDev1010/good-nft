require('chai')
    .use(require('chai-as-promised'))
    .should()

const {assert} = require('chai')
const { isTopic } = require('web3-utils')

const Test721A = artifacts.require('./Test721A.sol')

contract('Test721A contract', (accounts) => {
    let res, testCon
    let holder_1, holder_2, holder_3
    let ownedStar_1, ownedStar_2, ownedStar_3
    before(async() => {
        testCon = await Test721A.deployed()

        holder_1 = "0x8090dd2831092d07c013e8252cd7a19f9149e2ea"
        holder_2 = "0xa784779bd895b2db4c0009a7468f090012e12ff9"
        holder_3 = "0x7c2845d6b48cb2feb76532558e2033c145745e35"

        ownedStar_1 = [961, 960, 959, 958, 957]
        ownedStar_2 = [1202, 1841, 1955, 1947]
        ownedStar_3 = [1351, 1616, 1837, 1838]
    })

    it('holder mint', async() => {
        await web3.eth.sendTransaction({
            from: accounts[9],
            to: holder_3,
            value: web3.utils.toWei('10', 'ether')
        })

        await testCon.holderMint(ownedStar_1, {from: holder_1})
        await testCon.holderMint(ownedStar_2, {from: holder_2})
        await testCon.holderMint(ownedStar_3, {from: holder_3})

        res = await testCon.balanceOf(holder_1)
        assert.equal(res, ownedStar_1.length, 'holder-1 balance')

        res = await testCon.balanceOf(holder_2)
        assert.equal(res, ownedStar_2.length, 'holder-2 balance')

        res = await testCon.balanceOf(holder_3)
        assert.equal(res, ownedStar_3.length, 'holder-3 balance')

        res = await testCon.ownerOf(0)
        assert.equal(res.toLowerCase(), holder_1.toLowerCase(), "NFT-0 owner")

        res = await testCon.ownerOf(5)
        assert.equal(res.toLowerCase(), holder_2.toLowerCase(), "NFT-5 owner")

        res = await testCon.ownerOf(9)
        assert.equal(res.toLowerCase(), holder_3.toLowerCase(), "NFT-9 owner")
    })

    it('transfer', async() => {
        await testCon.transferFrom(holder_1, accounts[5], 0, {from: holder_1})

        res = await testCon.balanceOf(holder_1)
        assert.equal(res, ownedStar_1.length - 1, 'holder-1 balance')

        res = await testCon.balanceOf(accounts[5])
        assert.equal(res, 1, 'accounts[5] balance')

        res = await testCon.ownerOf(0)
        assert.equal(res.toLowerCase(), accounts[5].toLowerCase(), "NFT-9 owner")
    })

    it('approve', async() => {
        await testCon.approve(accounts[4], 1, {from: holder_1})
        res = await testCon.getApproved(1)
        assert.equal(res, accounts[4], "get approved")
    })
})