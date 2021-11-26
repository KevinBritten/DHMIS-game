require("dotenv").config();

const main = async () => {
  const gameContractFactory = await hre.ethers.getContractFactory("MyEpicGame");
  const gameContract = await gameContractFactory.deploy(
    ["Duck", "Yellow Guy", "Red Guy"], // Names
    [
      "QmRDwmfZrDEdevL9H2gescRmVHoAitHPsPnoPzwAa39bmy", // Images
      "QmRuY78mZDvk29BWqjRHMN6DoaNiAFUHLFUJD78VVx37Ux",
      "QmcgLpWYojqwcNXqvHtqyTxV1br5W4vQ2gSoFXJUMn3Xed",
    ],
    [100, 250, 300], // HP values
    [150, 100, 70], // Attack damage values
    [20, 25, 45], //Critical Hit Chance
    "Roy", // Boss name
    "QmaisduSWDEx5rBJA9Qb7R7mo6nDVSfTB1AwzFV2tT1dTV", // Boss image
    10000, // Boss hp
    50 // Boss attack damage
  );
  await gameContract.deployed();
  console.log("Contract deployed to:", gameContract.address);

  let txn;

  txn = await gameContract.mintCharacterNFT(2);
  await txn.wait();

  console.log("NFT 1 Minted");

  txn = await gameContract.attackBoss();
};
const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();
