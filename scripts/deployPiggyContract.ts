import { ethers } from "hardhat";

async function deployPiggyContract() {
    const PiggyFactory = await ethers.getContractFactory("PiggyBankFactory");

    console.log("Deploying PiggyBankFactory Contract...");

    const deployedContract = await PiggyFactory.deploy();
    await deployedContract.waitForDeployment();

    console.log(`PiggyBankFactory Contract deployed at: ${deployedContract.target}`);
    return deployedContract;
}

deployPiggyContract()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
});

export default deployPiggyContract;