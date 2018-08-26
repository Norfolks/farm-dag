

function wait(delay) {
    let stop = new Date().getTime() / 1000 + delay;
    while (new Date().getTime() / 1000 < stop) {}
}

let offset = 0;
const increaseTime = function (duration) {
    offset += duration;
    return web3.currentProvider.send({
        jsonrpc: '2.0',
        method: 'evm_increaseTime',
        params: [duration],
        id: 0,
    });
};

function getTestRpcTime() {
    return Math.floor(new Date() / 1000) + offset;
}


function parsePackage(pack, naming = null) {
    if (naming) {
        pack[0] = naming[pack[0]];
        pack[1] = naming[pack[1]];
    }
    pack[3] = parseInt(pack[3].toString(10));
    return pack;
}

async function setData(data, farm, naming) {
    let assetsKeys = Object.keys(data);
    for (let assetIndex = 0; assetIndex < assetsKeys.length; assetIndex++) {
        let assetLedger = data[assetsKeys[assetIndex]];
        let farmKeys = Object.keys(assetLedger);
        for (let farmIndex = 0; farmIndex < farmKeys.length; farmIndex++) {
            if (assetLedger[farmKeys[farmIndex]] > 0) {
                await farm.setAssetAfford(assetsKeys[assetIndex],
                    assetLedger[farmKeys[farmIndex]],
                    {from: naming[farmKeys[farmIndex]]});
            }
            else if (assetLedger[farmKeys[farmIndex]] < 0) {
                await farm.setAssetDemand(assetsKeys[assetIndex],
                    (-1) * assetLedger[farmKeys[farmIndex]],
                    {from: naming[farmKeys[farmIndex]]});
            }
        }
    }
}

function getAmountOrZero(value) {
    if (value == null) return 0;
    return value;
}

function checkResults(data, resultPackages) {
    let assetsKeys = Object.keys(data);
    let resultAsset = {};
    for (let i = 0; i < resultPackages.length; i++) {
        let asset = resultPackages[i][2];
        if (resultAsset[asset] == null) resultAsset[asset] = {};
        resultAsset[asset][resultPackages[i][0]] = getAmountOrZero(resultAsset[asset][resultPackages[i][0]]) + resultPackages[i][3];
        resultAsset[asset][resultPackages[i][1]] = getAmountOrZero(resultAsset[asset][resultPackages[i][1]]) - resultPackages[i][3];
        resultAsset[asset]["totalAmount"] = getAmountOrZero(resultAsset[asset]["totalAmount"]) + resultPackages[i][3];
    }

    let assetAfford = {};
    let assetDemand = {};
    for (let assetIndex = 0; assetIndex < assetsKeys.length; assetIndex++) {
        let assetLedger = data[assetsKeys[assetIndex]];
        let farmKeys = Object.keys(assetLedger);
        assetAfford[assetsKeys[assetIndex]] = 0;
        assetDemand[assetsKeys[assetIndex]] = 0;
        for (let farmIndex = 0; farmIndex < farmKeys.length; farmIndex++) {
            if (assetLedger[farmKeys[farmIndex]] > 0) {
                assetAfford[assetsKeys[assetIndex]] += assetLedger[farmKeys[farmIndex]];
            }
            else if (assetLedger[farmKeys[farmIndex]] < 0) {
                assetDemand[assetsKeys[assetIndex]] += (-1) * assetLedger[farmKeys[farmIndex]];
            }
        }
    }

    // Check Cycle
    for (let assetIndex = 0; assetIndex < assetsKeys.length; assetIndex++) {
        if (resultAsset[assetsKeys[assetIndex]]["totalAmount"] !== assetAfford[assetsKeys[assetIndex]] &&
            resultAsset[assetsKeys[assetIndex]]["totalAmount"] !== assetDemand[assetsKeys[assetIndex]]) return false;

        let assetLedger = data[assetsKeys[assetIndex]];
        let farmKeys = Object.keys(assetLedger);

        let numerator = assetAfford[assetsKeys[assetIndex]];
        let denumerator = assetDemand[assetsKeys[assetIndex]];
        if (numerator > denumerator) {
            let tmp = numerator;
            numerator = denumerator;
            denumerator = tmp;
        }
        for (let farmIndex = 0; farmIndex < farmKeys.length; farmIndex++) {
            let expectedResult = Math.abs(Math.trunc((assetLedger[farmKeys[farmIndex]] * numerator) / denumerator));
            if (resultAsset[assetsKeys[assetIndex]] < expectedResult) {
                return false;
            }
        }
    }
    return true;
}

async function getPackagesArray(farm, naming) {
    let packagesArray = [];
    try {
        let i = 0;
        while (true) {
            packagesArray.push(parsePackage(await farm.dagLinks.call(i), naming));
            i++;
        }
    } catch (e) {
        return packagesArray;
    }

}

// const createTestData(inFarmers, outFarmers, )


module.exports.wait = wait;
module.exports.increaseTime = increaseTime;
module.exports.checkResults = checkResults;
module.exports.getPackagesArray = getPackagesArray;
module.exports.setData = setData;
module.exports.getTestRpcTime = getTestRpcTime;