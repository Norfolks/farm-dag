# Optimized Assets Distribution for farmers

The project is based on smart-contract over Ethereum network,
 allows to make request with an offering or demanding of some asset,
  next the most optimized graph of assets' distribution between users is created according to their offer and demand.

## Pre-requirements to run test

+ nodejs v.8+
+ truffle v.4+ 

## Run test 
To run test use the command:
```bash
truffle test
```

Expected output:
```bash
Using network 'test'.

Compiling ./contracts/Farm.sol...
Compiling ./contracts/Ownable.sol...
Compiling ./contracts/SafeMath.sol...
Compiling ./contracts/farm.sol...
F0 - 0x627306090abab3a6e1400e9345bc60c78a8bef57
F1 - 0xf17f52151ebef6c7334fad080c5704d77216b732
F2 - 0xc5fdf4076b8f3a5357c5e395ab970b5b54098fef
F3 - 0x821aea9a577a9b44299b9c15c88cf3087f3b5544
F4 - 0x0d1d4e623d10f9fba5db95830f7d3839406c6af2
F5 - 0x2932b7a2355d6fecc4b5c0b6bd44cc31df247a2e
F6 - 0x2191ef87e392377ec08e7c08eb105ef5448eced5
F7 - 0x0f4f2ac550a1b4e2280d04c21cea7ebd822934b5
F8 - 0x6330a553fc93768f612722bb8c2ec78ac90b3bbc
F9 - 0x5aeda56215b167893e80b4fe645ba6d5bab767de


  Contract: FarmDAG contract
[ [ 'F1', 'F3', 'carrot', 4 ],
  [ 'F1', 'F4', 'carrot', 1 ],
  [ 'F2', 'F5', 'carrot', 1 ],
  [ 'F2', 'F6', 'carrot', 1 ] ]
    ✓ test afford equal demand (805ms)
[ [ 'F2', 'F3', 'carrot', 4 ],
  [ 'F2', 'F4', 'carrot', 7 ],
  [ 'F2', 'F5', 'carrot', 3 ],
  [ 'F1', 'F5', 'carrot', 3 ],
  [ 'F1', 'F6', 'carrot', 1 ] ]
    ✓ test afford greater then demand (809ms)
[ [ 'F1', 'F5', 'carrot', 4 ],
  [ 'F1', 'F3', 'carrot', 1 ],
  [ 'F2', 'F3', 'carrot', 1 ],
  [ 'F2', 'F4', 'carrot', 1 ] ]
    ✓ test demand greater then afford (698ms)
[ [ 'F1', 'F6', 'carrot', 9 ],
  [ 'F1', 'F3', 'carrot', 3 ],
  [ 'F1', 'F5', 'carrot', 2 ],
  [ 'F1', 'F4', 'carrot', 1 ],
  [ 'F2', 'F5', 'carrot', 1 ],
  [ 'F2', 'F3', 'carrot', 1 ],
  [ 'F1', 'F3', 'potato', 4 ],
  [ 'F1', 'F4', 'potato', 1 ],
  [ 'F2', 'F5', 'potato', 1 ],
  [ 'F2', 'F6', 'potato', 1 ],
  [ 'F1', 'F5', 'tomato', 5 ],
  [ 'F2', 'F5', 'tomato', 2 ],
  [ 'F3', 'F6', 'tomato', 2 ],
  [ 'F3', 'F4', 'tomato', 1 ],
  [ 'F3', 'F6', 'tomato', 1 ] ]
    ✓ test multiple assets per week (1784ms)


  4 passing (4s)
```

## Contract user manual / Flow

Steps to execute contract functions:

+ Contract's owner starts the new week with custom amount of time till farmers can write their offers and demands to the contract. (startNewWeek function)
+ Farmers write their offers and demands for assets. (setAssetDemand, setAssetAfford functions)
+ At the end of week contract's owner starts calculation of optimal distribution. (calculateWeek function)
+ All the data (in format: [from_address, to_address, asset, amount]) about assets distribution is stored in public field - dagLinks.

## Contract issues

There are still some issues and improvements could be applied to the contract:

+ Some of the links between farmers could be repeated with different amounts for the same asset. In that case final result is the addition of the amounts.
+ There are no limits of farmer's number that could cause "out of gas" issue.
+ Algorithm includes sort algorithm inside, it could be done offchain.
+ There are no farmer's or asset's whitelisting. 
+ Storing farmer's addresses could be separated not only by asset's batches, but also by demand and offer, that will optimize linking algorithm.