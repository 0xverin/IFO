const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");
const { MaxUint256 } = require("@ethersproject/constants");
function expandTo18Decimals(value) {
    return BigNumber.from(value).mul(BigNumber.from(10).pow(18));
}
describe("DayOfRightsReferral", function () {
    var DORToken;
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
    var BASEToken;

    it("init params", async function () {
        [deployer, ...users] = await ethers.getSigners();
    });

    it("deploy", async function () {
        const WETH9Instance = await ethers.getContractFactory("WETH9");
        WETH9 = await WETH9Instance.deploy();

        const BASETokenInstance = await ethers.getContractFactory("BASEToken");
        BASEToken = await BASETokenInstance.deploy();

        const USDTInstance = await ethers.getContractFactory("USDT");
        USDT = await USDTInstance.deploy();

        const UniswapV2FactoryInstance = await ethers.getContractFactory("UniswapV2Factory");
        UniswapV2Factory = await UniswapV2FactoryInstance.deploy(deployer.address);

        const UniswapV2Router02Instance = await ethers.getContractFactory("UniswapV2Router02");
        UniswapV2Router02 = await UniswapV2Router02Instance.deploy(UniswapV2Factory.address, WETH9.address);

        const DORTokenInstance = await ethers.getContractFactory("DORToken");
        DORToken = await DORTokenInstance.deploy(
            "DOR Token",
            "DOR",
            18,
            users[4].address,
            users[4].address,
            USDT.address,
            UniswapV2Factory.address,
            UniswapV2Router02.address,
        );

        const SmartDisPatchInitializableInstance = await ethers.getContractFactory("SmartDisPatchInitializable");
        SmartDisPatchInitializable = await SmartDisPatchInitializableInstance.deploy();

        const DayOfRightsClubInstance = await ethers.getContractFactory("DayOfRightsClub");
        DayOfRightsClub = await DayOfRightsClubInstance.deploy();

        const BlockhashMgrInstance = await ethers.getContractFactory("BlockhashMgr");
        BlockhashMgr = await BlockhashMgrInstance.deploy();

        const DayOfRightsClubPackageInstance = await ethers.getContractFactory("DayOfRightsClubPackage");
        DayOfRightsClubPackage = await DayOfRightsClubPackageInstance.deploy(
            BlockhashMgr.address,
            DayOfRightsClub.address,
        );

        const DayOfRightsReferralInstance = await ethers.getContractFactory("DayOfRightsReferral");
        DayOfRightsReferral = await DayOfRightsReferralInstance.deploy(
            DayOfRightsClub.address,
            DayOfRightsClubPackage.address,
            users[4].address,
            USDT.address,
            DORToken.address,
        );

        const IFOInstance = await ethers.getContractFactory("IFO");
        IFO = await IFOInstance.deploy(
            users[4].address,
            USDT.address,
            DORToken.address,
            DayOfRightsClubPackage.address,
            DayOfRightsReferral.address,
        );

        const PartnerRewardinstance = await ethers.getContractFactory("PartnerReward");
        PartnerReward = await PartnerRewardinstance.deploy(DayOfRightsReferral.address, DORToken.address);

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
    });
    it("approve", async function () {
        await USDT.approve(IFO.address, MaxUint256);
        await USDT.approve(DayOfRightsReferral.address, MaxUint256);
        await USDT.approve(UniswapV2Router02.address, MaxUint256);
        await DORToken.approve(UniswapV2Router02.address, MaxUint256);

        for (let index = 0; index < 10; index++) {
            await USDT.transfer(users[index].address, expandTo18Decimals(1000));
            await USDT.connect(users[index]).approve(IFO.address, MaxUint256);
        }
    });

    it("setup", async function () {
        await DORToken.setMinner(IFO.address, true);
        await DORToken.setMinner(DayOfRightsReferral.address, true);
        await DayOfRightsClubPackage.addMinner(IFO.address);
        await DayOfRightsClubPackage.addMinner(DayOfRightsReferral.address);
        await DayOfRightsClub.addMinner(DayOfRightsReferral.address);
        await BlockhashMgr.setCaller(DayOfRightsClubPackage.address, true);
        await DayOfRightsReferral.setCaller(IFO.address, true);

        //collect start
        await IFO.allowCollectReward();
    });
    it("addLiquidity", async function () {
        // console.log(await UniswapV2Factory.INIT_CODE_PAIR_HASH());
        await IFO.shop(1);
        await IFO.collect();
        await DORToken.setCanTransfer(true);
        await UniswapV2Router02.addLiquidity(
            USDT.address,
            DORToken.address,
            expandTo18Decimals(10),
            expandTo18Decimals(10),
            expandTo18Decimals(1),
            expandTo18Decimals(1),
            deployer.address,
            Math.floor(Date.now() / 1000) + 100,
        );
    });

    it("query before", async function () {
        console.log(await DayOfRightsClubPackage.totalSupply());
        console.log(await DayOfRightsClub.totalSupply());
        console.log(await DORToken.balanceOf(deployer.address));
    });
    it("setReferrer test", async function () {
        await DayOfRightsReferral.partnerStake();
        for (let index = 0; index < 10; index++) {
            await DayOfRightsReferral.connect(users[index]).setReferrer(deployer.address);
        }
    });
    it("function test", async function () {
        for (let index = 0; index < 10; index++) {
            await IFO.connect(users[index]).shop(1);
        }
    });

    it("query after", async function () {
        console.log(await DayOfRightsClubPackage.totalSupply());
        console.log(await DayOfRightsClub.totalSupply());
        console.log(await DORToken.balanceOf(deployer.address));
    });
});
