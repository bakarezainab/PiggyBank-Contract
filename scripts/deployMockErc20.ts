import { ethers } from "hardhat";

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log(`Deploying contracts with the account: ${deployer.address}`);

    // Deploy Mock USDC
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    const usdc = await MockERC20.deploy("USD Coin", "USDC", 1000000);
    await usdc.waitForDeployment();
    console.log(`Mock USDC deployed to: ${await usdc.getAddress()}`);

    // Deploy Mock USDT
    const usdt = await MockERC20.deploy("Tether", "USDT", 1000000);
    await usdt.waitForDeployment();
    console.log(`Mock USDT deployed to: ${await usdt.getAddress()}`);

    // Deploy Mock DAI
    const dai = await MockERC20.deploy("Dai", "DAI", 1000000);
    await dai.waitForDeployment();
    console.log(`Mock DAI deployed to: ${await dai.getAddress()}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });