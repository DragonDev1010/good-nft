const GoodNft = artifacts.require("GoodNft");

module.exports = function (deployer) {
  deployer.deploy(GoodNft, "ARBO Heros", "ARBO", "0x41a70A616a35CBFA00Cc0319748F281396366736");
};
