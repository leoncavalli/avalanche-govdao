const Proposal = artifacts.require("Proposal");

module.exports = function (deployer) {
  deployer.deploy(Proposal, 1, "Öneri 1", "Bu yolla oluşturulan önerilerle topluluğa tavsiyelerde bulunabilir, oyunun gelişmesinde etkin rol oynayabilirsiniz.", 2, 6);
};
