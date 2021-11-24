const main = async () => {
  const gameContractFactory = await hre.ethers.getContractFactory("MyEpicGame");
  const gameContract = await gameContractFactory.deploy(
    ["Duck", "Yellow Guy", "Red Guy"], // Names
    [
      "QmRDwmfZrDEdevL9H2gescRmVHoAitHPsPnoPzwAa39bmy", // Images
      "QmRuY78mZDvk29BWqjRHMN6DoaNiAFUHLFUJD78VVx37Ux",
      "QmcgLpWYojqwcNXqvHtqyTxV1br5W4vQ2gSoFXJUMn3Xed",
    ],
    [100, 200, 300], // HP values
    [150, 75, 50], // Attack damage values
    "Roy", // Boss name
    "QmaisduSWDEx5rBJA9Qb7R7mo6nDVSfTB1AwzFV2tT1dTV", // Boss image
    10000, // Boss hp
    50 // Boss attack damage
  );
  await gameContract.deployed();
  console.log("Contract deployed to:", gameContract.address);
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
