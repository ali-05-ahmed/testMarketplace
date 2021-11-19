// scripts/upgrade_box.js
const { ethers, upgrades } = require('hardhat');

async function main() {
    const NftMarketplaceV2 = await ethers.getContractFactory('NftMarketplaceV2');
    console.log('Upgrading NftMarketplace...');
    await upgrades.upgradeProxy('0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0', NftMarketplaceV2, { initializer: 'initialize' });
    console.log('NftMarketplace upgraded');
}

main();