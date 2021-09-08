var Game = artifacts.require("./Game.sol");

module.exports = function (deployer) {
  deployer.deploy(
    Game,
    "2300000000000000",
    "0x05a538A4Dc2917FbB5ef5c29aA41001B2b545Ef2",
    240,
    1,
    { value: 2300000000000000 }
  );
};
