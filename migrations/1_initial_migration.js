const GoodNft = artifacts.require("GoodNft");

module.exports = function (deployer) {
  deployer.deploy(GoodNft, "ARBO Heros", "ARBO");
};
