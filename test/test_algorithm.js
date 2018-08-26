var FarmDAG = artifacts.require("FarmDAG");
const utils = require('./utils');


let addrToName = {};
let nameToAddr = {};

let testEqualData = {
    'carrot': {
        'F1': 5,
        'F2': 2,
        'F3': -4,
        'F4': -1,
        'F5': -1,
        'F6': -1,
    }
};

let testSurplusData = {
    'carrot': {
        'F1': 5,
        'F2': 20,
        'F3': -4,
        'F4': -7,
        'F5': -6,
        'F6': -1,
    }
};

let testDeficitData = {
    'carrot': {
        'F1': 5,
        'F2': 2,
        'F3': -4,
        'F4': -1,
        'F5': -8,
    }
};

let testMultipleAssetsData = {
    'carrot': {
        'F1': 15,
        'F2': 2,
        'F3': -4,
        'F4': -1,
        'F5': -3,
        'F6': -10,
    },
    'potato': {
        'F1': 5,
        'F2': 2,
        'F3': -4,
        'F4': -1,
        'F5': -1,
        'F6': -1,
    },
    'tomato': {
        'F1': 5,
        'F2': 2,
        'F3': 4,
        'F4': -1,
        'F5': -9,
        'F6': -3
    }
};


contract('FarmDAG contract', async function (accounts) {
    // Not the best place, but let it be..
    addrToName = {};
    nameToAddr = {};
    for (let i = 0; i < 10; i++) {
        nameToAddr['F' + i] = accounts[i];
        addrToName[accounts[i]] = 'F' + i;
        console.log('F' + i + ' - ' + accounts[i]);
    }

    it("test afford equal demand", async function () {
        let farmDag = await FarmDAG.deployed();
        await farmDag.startNewWeek(utils.getTestRpcTime() + 2);
        await utils.setData(testEqualData, farmDag, nameToAddr);
        utils.increaseTime(3);
        await farmDag.calculateWeek(1);
        let resultPackages = await utils.getPackagesArray(farmDag, addrToName);
        console.log(resultPackages);
        assert.isTrue(utils.checkResults(testEqualData, resultPackages), "Distribution is wrong somewhere.");
    });

    it("test afford greater then demand", async function () {
        let farmDag = await FarmDAG.deployed();
        await farmDag.startNewWeek(utils.getTestRpcTime() + 2);
        await utils.setData(testSurplusData, farmDag, nameToAddr);
        utils.increaseTime(3);
        await farmDag.calculateWeek(1);
        let resultPackages = await utils.getPackagesArray(farmDag, addrToName);
        console.log(resultPackages);
        assert.isTrue(utils.checkResults(testSurplusData, resultPackages), "Distribution is wrong somewhere.");
    });

    it("test demand greater then afford", async function () {
        let farmDag = await FarmDAG.deployed();
        await farmDag.startNewWeek(utils.getTestRpcTime() + 2);
        await utils.setData(testDeficitData, farmDag, nameToAddr);
        utils.increaseTime(3);
        await farmDag.calculateWeek(1);
        let resultPackages = await utils.getPackagesArray(farmDag, addrToName);
        console.log(resultPackages);
        assert.isTrue(utils.checkResults(testDeficitData, resultPackages), "Distribution is wrong somewhere.");
    });

    it("test multiple assets per week", async function () {
        let farmDag = await FarmDAG.deployed();
        await farmDag.startNewWeek(utils.getTestRpcTime() + 2);
        await utils.setData(testMultipleAssetsData, farmDag, nameToAddr);
        utils.increaseTime(2);
        await farmDag.calculateWeek(3);
        let resultPackages = await utils.getPackagesArray(farmDag, addrToName);
        console.log(resultPackages);
        assert.isTrue(utils.checkResults(testMultipleAssetsData, resultPackages), "Distribution is wrong somewhere.");
    });
});