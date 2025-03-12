import { ethers } from "hardhat";

async function main() {
  // Deploy NFTMarketplace
  const NFTMarketplace = await ethers.getContractFactory("NFTMarketplace");
  const marketplace = await NFTMarketplace.deploy();
  await marketplace.deployed();
  console.log("NFTMarketplace deployed to:", marketplace.address);

  // Deploy SampleNFT
  const SampleNFT = await ethers.getContractFactory("SampleNFT");
  const nft = await SampleNFT.deploy();
  await nft.deployed();
  console.log("SampleNFT deployed to:", nft.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
}); 