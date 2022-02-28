const Web3 = require('web3')
const holdTokenABI = require('./abi.json')

const holdTokenAddr = "0x41a70a616a35cbfa00cc0319748f281396366736"
const starOwnersById = require('./wallets.json')
var web3 
var holdToken
var usedStarIds = []
class Server {
    constructor() {
        web3 = new Web3("https://mainnet.infura.io/v3/b8a10907bdda41c6ac713b5efc0257ee")
        holdToken = new web3.eth.Contract(holdTokenABI, holdTokenAddr)
    }
    async main() {
        let res = await holdToken.methods.balanceOf("0x8090dd2831092d07c013e8252cd7a19f9149e2ea").call()
    }

    // async getAllTokenIds(address) {
    //     let balance = await holdToken.methods.balanceOf(address).call()
    //     let totalSupply = await holdToken.methods.totalSupply().call()

    //     let tokenIds = []
    //     for(let i = 0 ; i < totalSupply ; i++) {
    //         let owner_tmp = await holdToken.methods.ownerOf(i).call()
    //         if(owner_tmp.toLowerCase() == address.toLowerCase()) {
    //             tokenIds.push(i)
    //             console.log(i, " : ", tokenIds.length)
    //         }
    //         if(tokenIds.length == balance)
    //             break;
    //     }
    //     console.log(tokenIds)
    // }

    checkMintable(address) {
        let starIds = []
        for(let i = 0 ; i < 2000 ; i++) {
            if(starOwnersById[i].wallet_address.toLowerCase() == address.toLowerCase()) {
                if(!this.checkUsed(i))
                    starIds.push(i)
            }
        }
        console.log(starIds)
        return starIds
    }

    useStar(id) {
        if(!this.checkUsed(id))
            usedStarIds.push(id)
    }

    checkUsed(id) {
        return usedStarIds.includes(id)
    }
    
}
// const s = new Server()
// s.mint("0x7c2845d6b48cb2feb76532558e2033c145745e35")
module.exports = {Server}