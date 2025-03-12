const hre = require("hardhat");

async function main() {
  // Deploy NFTMarketplace
  const NFTMarketplace = await hre.ethers.getContractFactory("NFTMarketplace");
  const marketplace = await NFTMarketplace.deploy();
  await marketplace.waitForDeployment();
  console.log("NFTMarketplace deployed to:", await marketplace.getAddress());

  // Deploy SampleNFT
  const SampleNFT = await hre.ethers.getContractFactory("SampleNFT");
  const nft = await SampleNFT.deploy();
  await nft.waitForDeployment();
  console.log("SampleNFT deployed to:", await nft.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
}); 