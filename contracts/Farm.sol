pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./Ownable.sol";



contract FarmDAG is Ownable {
	using SafeMath for uint256;

	/* Struct stores information about one address ought to send an asset to another address.*/
	struct Package {
		address from;
		address to;
		string asset;
		uint amount;
	}

	/* Stores number of overall demand for each asset. */
	mapping(string => uint) demandAssetsCount;
	/* Stores number of overall afford for each asset. */
	mapping(string => uint) affordAssetsCount;

	/* Strores amount of assets's demand for each address. */
	mapping(string => mapping (address => uint)) demandAssets;
	/* Strores amount of assets's afford for each address. */
	mapping(string => mapping (address => uint)) affordAssets;

	/* Array of farmers who made a request last week. */
	mapping(string => address[])  farmersByAssets;
	/* Flags of farmers who made a request last week.*/
	mapping(string => mapping(address => bool)) farmersInluded;
	/* Array of assets that need to be allocated this week. */
	string[] public assets;
	/* Flags of assets that need to be allocated this week. */
	mapping(string => bool) assetsIncluded;

	/* Stores result connections between farmers. */
	Package[] public dagLinks;

	/* Time limit of the last. */
	uint public timeBound;

	/* Stores index of the last farmer iterared in _linkFrom or _linkTo functions. */
	uint lastFarmerIndex;
	/* Stores index of the last asset iterated in calculateWeek function. */
	uint lastAssetIndex;

	/* Emits when farmer offers afford. */
	event AffordSet(address farmer, string asset, uint amount);
	/* Emits when farmer asks for demand. */
	event DemandSet(address farmer, string asset, uint amount);

	constructor () public {

	}
	
	/**
  	* @dev sets amount of demand of specific asset for sender.
  	* @param _assetKey string representation of asset.
  	* @param _amount amount to demand.
  	*/
	function setAssetDemand(string _assetKey, uint256 _amount) public {
		require (now < timeBound);
		require (affordAssets[_assetKey][msg.sender] == 0);

		if(!farmersInluded[_assetKey][msg.sender] && _amount != 0){
			farmersInluded[_assetKey][msg.sender] = true;
			farmersByAssets[_assetKey].push(msg.sender);
		}
		if(!assetsIncluded[_assetKey]) {
			assetsIncluded[_assetKey] = true;
			assets.push(_assetKey);
		}

		demandAssetsCount[_assetKey] = demandAssetsCount[_assetKey].sub(demandAssets[_assetKey][msg.sender]).add(_amount);
		demandAssets[_assetKey][msg.sender] = _amount;
		emit DemandSet(msg.sender, _assetKey, _amount);
	}

	/**
  	* @dev sets amount of afford of specific asset for sender.
  	* @param _assetKey string representation of asset.
  	* @param _amount amount to afford.
  	*/
	function setAssetAfford(string _assetKey, uint256 _amount) public {
		require (now < timeBound);
		require (demandAssets[_assetKey][msg.sender] == 0);

		if(!farmersInluded[_assetKey][msg.sender]){
			farmersInluded[_assetKey][msg.sender] = true;
			farmersByAssets[_assetKey].push(msg.sender);
		}

		if(!assetsIncluded[_assetKey]) {
			assetsIncluded[_assetKey] = true;
			assets.push(_assetKey);
		}

		affordAssetsCount[_assetKey] = affordAssetsCount[_assetKey].sub(affordAssets[_assetKey][msg.sender]).add(_amount);
		affordAssets[_assetKey][msg.sender] = _amount;
		emit AffordSet(msg.sender, _assetKey, _amount);
	}


	/**
  	* @dev starts new week. During new week farmers can set their affors and demands per assets.
  	* All the data from previuse week is deleted.
  	* @param _timeBound farmers should make their requests until the time limit.
  	*/
	function startNewWeek(uint _timeBound) onlyOwner public {
		require (_timeBound > now);
		_clearAllData();
		lastAssetIndex = 0;
		timeBound = _timeBound;
	}

	/**
  	* @dev creates asynchronous graph that distributes assets between farmers. Optimazed for several requests.
  	* @param _assetsProcceed amount of assets to calculate during one function call.
  	*/
	function calculateWeek(uint _assetsProcceed) onlyOwner public {
		require (timeBound < now);
		uint assetsToProcceed = lastAssetIndex.add(_assetsProcceed);
		if (assets.length < _assetsProcceed) {
			_assetsProcceed = assets.length;
		}

		for(uint assetIndex = lastAssetIndex; assetIndex < assetsToProcceed; assetIndex++) {
			string storage currentAsset = assets[assetIndex];
			lastFarmerIndex = 0;

			if(affordAssetsCount[currentAsset] > demandAssetsCount[currentAsset]) {
				_linkSurplusAsset(currentAsset);
			} else {
				_linkDeficitAsset(currentAsset);
			}
		}

	}

	/**
  	* @dev counts distribution for asset, if afford is greater then demand.
  	* @param _currentAsset the asset for what distribution is calculated.
  	*/
	function _linkSurplusAsset(string _currentAsset) internal {
		uint unreceivedCount = demandAssetsCount[_currentAsset];
		uint denominator = affordAssetsCount[_currentAsset];
		uint numerator = demandAssetsCount[_currentAsset];

		address[] memory sortedFarmers = _getSortedFarmersByAsset(_currentAsset, false);
		uint farmerIndex;
		uint amountToDeliver;
		for(farmerIndex = 0; farmerIndex < sortedFarmers.length &&
			unreceivedCount != 0; farmerIndex++) {
			if(affordAssets[_currentAsset][sortedFarmers[farmerIndex]] == 0) {
				break;
			}
			amountToDeliver = affordAssets[_currentAsset][sortedFarmers[farmerIndex]].mul(numerator).div(denominator);
			if (amountToDeliver == 0) {
				amountToDeliver = 1;
			}
			_linkFrom(sortedFarmers[farmerIndex], _currentAsset, amountToDeliver);
			unreceivedCount = unreceivedCount.sub(amountToDeliver);
			affordAssets[_currentAsset][sortedFarmers[farmerIndex]] = affordAssets[_currentAsset][sortedFarmers[farmerIndex]].sub(amountToDeliver);
		}

		// Cicle to distribute remainders
		for(; unreceivedCount > 0; farmerIndex--){
			if(affordAssets[_currentAsset][sortedFarmers[farmerIndex]] == 0) {
				continue;
			}
			amountToDeliver = 1;
			_linkFrom(sortedFarmers[farmerIndex], _currentAsset, amountToDeliver);
			unreceivedCount = unreceivedCount.sub(amountToDeliver);
			affordAssets[_currentAsset][sortedFarmers[farmerIndex]] = affordAssets[_currentAsset][sortedFarmers[farmerIndex]].sub(amountToDeliver);
		}
		delete sortedFarmers;
	}

	/**
  	* @dev counts distribution for asset, if demand is greater then afford.
  	* @param _currentAsset the asset for what distribution is calculated.
  	*/
	function _linkDeficitAsset (string _currentAsset) internal {
		uint unallocatedCount = affordAssetsCount[_currentAsset];
		uint denominator = demandAssetsCount[_currentAsset];
		uint numerator = affordAssetsCount[_currentAsset];


		address[] memory sortedFarmers = _getSortedFarmersByAsset(_currentAsset, true);
		uint farmerIndex;
		uint amountToDeliver;
		for(farmerIndex = 0; farmerIndex < sortedFarmers.length && 
			unallocatedCount != 0;
			 farmerIndex++) {

			if(demandAssets[_currentAsset][sortedFarmers[farmerIndex]] == 0) {
				break;
			}
			amountToDeliver = demandAssets[_currentAsset][sortedFarmers[farmerIndex]].mul(numerator).div(denominator);
			if(amountToDeliver == 0) {
				amountToDeliver = 1;
			}
			_linkTo(sortedFarmers[farmerIndex], _currentAsset, amountToDeliver);
			unallocatedCount = unallocatedCount.sub(amountToDeliver);
			demandAssets[_currentAsset][sortedFarmers[farmerIndex]] = demandAssets[_currentAsset][sortedFarmers[farmerIndex]].sub(amountToDeliver);
		}
		// Cicle to distribute remainders
		for(; unallocatedCount > 0; farmerIndex--){
			if(demandAssets[_currentAsset][sortedFarmers[farmerIndex]] == 0) {
				continue;
			}
			amountToDeliver = 1;
			_linkTo(sortedFarmers[farmerIndex], _currentAsset, amountToDeliver);
			unallocatedCount = unallocatedCount.sub(amountToDeliver);
			demandAssets[_currentAsset][sortedFarmers[farmerIndex]] = demandAssets[_currentAsset][sortedFarmers[farmerIndex]].sub(amountToDeliver);
		}
		delete sortedFarmers;
	}

	/**
  	* @dev creates new array of farmers in memory and sorts it by afford or demand of chosen asset.
  	* @param _asset a asset on which sorting takes place.
  	* @param _byDemand flag to choose sort by demand or afford of the asset.
  	*/
	function _getSortedFarmersByAsset(string _asset, bool _byDemand) public view returns(address[]) {
		address[] memory farmersBuff = farmersByAssets[_asset];
		for(uint i = 0; i < farmersBuff.length - 1; i ++){
			for(uint j = 0; j < farmersBuff.length - i - 1; j++){
				if((_byDemand && demandAssets[_asset][farmersBuff[j]] < demandAssets[_asset][farmersBuff[j + 1]]) ||
					(!_byDemand && affordAssets[_asset][farmersBuff[j]] < affordAssets[_asset][farmersBuff[j + 1]])) {
					address tmp = farmersBuff[j];
					farmersBuff[j] = farmersBuff[j + 1];
					farmersBuff[j + 1] = tmp;
				}
			}
		}
		return farmersBuff;
	}
	
	/**
  	* @dev creates new package(s) that are sent to the chosen farmer.
  	* @param _farmer farmer packages sends to.
  	* @param _currentAsset asset of the packages.
  	* @param _amount amount of asset farmer should receive.
  	*/
	function _linkTo(address _farmer, string _currentAsset, uint _amount) internal {
		for(; _amount != 0; lastFarmerIndex++) {
			if(lastFarmerIndex == farmersByAssets[_currentAsset].length) {
				lastFarmerIndex = 0;
			}
			address currentFarmer = farmersByAssets[_currentAsset][lastFarmerIndex];
			if(affordAssets[_currentAsset][currentFarmer] == 0) {
				continue;
			}

			uint packageAmount;
			if(affordAssets[_currentAsset][currentFarmer] < _amount) {
				_amount = _amount.sub(affordAssets[_currentAsset][currentFarmer]);
				packageAmount = affordAssets[_currentAsset][currentFarmer];
				affordAssets[_currentAsset][currentFarmer] = 0;
			} else {
				affordAssets[_currentAsset][currentFarmer] = affordAssets[_currentAsset][currentFarmer].sub(_amount);
				packageAmount = _amount;
				_amount = 0;
			}
			dagLinks.push(Package(currentFarmer, _farmer, _currentAsset, packageAmount));
			if (_amount == 0) {
				break;
			} 
		}
	}

	/**
  	* @dev creates new package(s) that are sent from the chosen farmer.
  	* @param _farmer farmer packages sends from.
  	* @param _currentAsset asset of the packages.
  	* @param _amount amount of asset farmer should spend.
  	*/
	function _linkFrom(address _farmer, string _currentAsset, uint _amount) internal {
		for(; _amount != 0; lastFarmerIndex++) {
			if(lastFarmerIndex == farmersByAssets[_currentAsset].length) {
				lastFarmerIndex = 0;
			}
			address currentFarmer = farmersByAssets[_currentAsset][lastFarmerIndex];
			if(demandAssets[_currentAsset][currentFarmer] == 0) {
				continue;
			}

			uint packageAmount;
			if(demandAssets[_currentAsset][currentFarmer] < _amount) {
				_amount = _amount.sub(demandAssets[_currentAsset][currentFarmer]);
				packageAmount = demandAssets[_currentAsset][currentFarmer];
				demandAssets[_currentAsset][currentFarmer] = 0;
			} else {
				demandAssets[_currentAsset][currentFarmer] = demandAssets[_currentAsset][currentFarmer].sub(_amount);
				packageAmount = _amount;
				_amount = 0;
			}

			dagLinks.push(Package(_farmer, currentFarmer, _currentAsset, packageAmount));
			if (_amount == 0) {
				break;
			} 
		}
		
	}

	/**
  	* @dev clears all data created from last week distribution calculation.
  	*/
	function _clearAllData() internal {
		
		for(uint i = 0; i < assets.length; i++) {
			delete assetsIncluded[assets[i]];
			delete demandAssetsCount[assets[i]];
			delete affordAssetsCount[assets[i]];
			for(uint j = 0; j < farmersByAssets[assets[i]].length; j++) {
				delete demandAssets[assets[i]][farmersByAssets[assets[i]][j]];
				delete affordAssets[assets[i]][farmersByAssets[assets[i]][j]];
				delete farmersInluded[assets[i]][farmersByAssets[assets[i]][j]];
			}
			delete farmersByAssets[assets[i]];
		}
		delete assets;
		delete dagLinks;
	}
	

	
	
	


}