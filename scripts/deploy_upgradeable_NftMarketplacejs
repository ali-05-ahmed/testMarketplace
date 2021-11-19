// scripts/deploy_upgradeable_adminbox.js
const { ethers, upgrades } = require('hardhat');

async function main() {
    const NftMarketplace = await ethers.getContractFactory('NftMarketplace');
    console.log('Deploying NftMarketplace...');
    const nftMarketplace = await upgrades.deployProxy(NftMarketplace, { initializer: 'initialize' });
    await nftMarketplace.deployed();
    console.log('NftMarketplace deployed to:', nftMarketplace.address);
}

main();