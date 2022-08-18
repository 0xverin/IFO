const hre = require("hardhat");

async function main() {
    var WETH9;
    var USDT;
    var UniswapV2Factory;
    var UniswapV2Router02;
    var SmartDisPatchInitializable;
    var DayOfRightsClub;
    var BlockhashMgr;
    var DayOfRightsClubPackage;
    var DayOfRightsReferral;
    var IFO;
    var PartnerReward;

    [deployer, ...users] = await ethers.getSigners();

    const WETH9Instance = await ethers.getContractFactory("WETH9");
    WETH9 = await WETH9Instance.deploy();
    await WETH9.deployed();

    const USDTInstance = await ethers.getContractFactory("USDT");
    USDT = await USDTInstance.deploy();
    await USDT.deployed();

    const UniswapV2FactoryInstance = await ethers.getContractFactory("UniswapV2Factory");
    UniswapV2Factory = await UniswapV2FactoryInstance.attach("0xc35dadb65012ec5796536bd9864ed8773abc74c4");

    const UniswapV2Router02Instance = await ethers.getContractFactory("UniswapV2Router02");
    UniswapV2Router02 = await UniswapV2Router02Instance.attach("0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506");

    const DORTokenInstance = await ethers.getContractFactory("DORToken");
    DORToken = await DORTokenInstance.deploy(
        "DOR Token",
        "DOR",
        18,
        deployer.address,
        deployer.address,
        USDT.address,
        UniswapV2Factory.address,
        UniswapV2Router02.address,
    );
    await DORToken.deployed();
    console.log(22222222);
    const SmartDisPatchInitializableInstance = await ethers.getContractFactory("SmartDisPatchInitializable");
    SmartDisPatchInitializable = await SmartDisPatchInitializableInstance.deploy();
    await SmartDisPatchInitializable.deployed();

    const DayOfRightsClubInstance = await ethers.getContractFactory("DayOfRightsClub");
    DayOfRightsClub = await DayOfRightsClubInstance.deploy();
    await DayOfRightsClub.deployed();

    const BlockhashMgrInstance = await ethers.getContractFactory("BlockhashMgr");
    BlockhashMgr = await BlockhashMgrInstance.deploy();
    await BlockhashMgr.deployed();

    const DayOfRightsClubPackageInstance = await ethers.getContractFactory("DayOfRightsClubPackage");
    DayOfRightsClubPackage = await DayOfRightsClubPackageInstance.deploy(BlockhashMgr.address, DayOfRightsClub.address);
    await DayOfRightsClubPackage.deployed();

    const DayOfRightsReferralInstance = await ethers.getContractFactory("DayOfRightsReferral");
    DayOfRightsReferral = await DayOfRightsReferralInstance.deploy(
        DayOfRightsClub.address,
        DayOfRightsClubPackage.address,
        deployer.address,
        USDT.address,
        DORToken.address,
    );
    await DayOfRightsReferral.deployed();

    const IFOInstance = await ethers.getContractFactory("IFO");
    IFO = await IFOInstance.deploy(
        deployer.address,
        USDT.address,
        DORToken.address,
        DayOfRightsClubPackage.address,
        DayOfRightsReferral.address,
    );
    await IFO.deployed();

    const PartnerRewardinstance = await ethers.getContractFactory("PartnerReward");
    PartnerReward = await PartnerRewardinstance.deploy(DayOfRightsReferral.address, DORToken.address);
    await PartnerReward.deployed();

    console.log("UniswapV2Factory  :::::", UniswapV2Factory.address);
    console.log("UniswapV2Router02 :::::", UniswapV2Router02.address);
    console.log("DORToken          :::::", DORToken.address);
    console.log("SmartDisPatchInitializable :::::", SmartDisPatchInitializable.address);
    console.log("DayOfRightsClub :::::", DayOfRightsClub.address);
    console.log("BlockhashMgr :::::", BlockhashMgr.address);
    console.log("DayOfRightsClubPackage :::::", DayOfRightsClubPackage.address);
    console.log("DayOfRightsReferral :::::", DayOfRightsReferral.address);
    console.log("IFO :::::", IFO.address);
    console.log("PartnerReward :::::", PartnerReward.address);

    console.log("--------------------deployed compelete------------------------");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
