// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "hardhat/console.sol";
import "../interfaces/IChallengePool.sol";
import "../interfaces/IEvaluator.sol";

import "../utils/helpers.sol";

contract AssetPriceBounded is IEvaluator, Helpers {
    string public constant IN = "in";
    string public constant OUT = "out";
    constructor(
        address _dataProvider
    ) IEvaluator(_dataProvider) Ownable(msg.sender) {}

    function decodeAndAskProvider(
        IChallengePool.ChallengeEvent calldata _challengeEvent
    ) external override returns (bool) {
        (string memory assetSymbol, , , ) = abi.decode(
            _challengeEvent.eventParam,
            (string, uint256, uint256, string)
        );

        bool success = dataProvider().requestData(
            abi.encode(assetSymbol, _challengeEvent.maturity)
        );
        return success;
    }

    function decodeAndAnswer(
        IChallengePool.ChallengeEvent calldata _challengeEvent
    ) external override returns (IChallengePool.Prediction) {
        (
            string memory assetSymbol,
            uint256 priceLowerBound,
            uint256 priceUpperBound,
            string memory outcome
        ) = abi.decode(
                _challengeEvent.eventParam,
                (string, uint256, uint256, string)
            );
        bytes memory encodedAssetSymbol = abi.encode(
            assetSymbol,
            _challengeEvent.maturity
        );
        if (!dataProvider().hasData(encodedAssetSymbol)) {
            return IChallengePool.Prediction.zero;
        }
        uint256 assetPrice = abi.decode(
            dataProvider().getData(encodedAssetSymbol),
            (uint256)
        );

        if (compareStrings(outcome, IN)) {
            if (
                assetPrice >= priceLowerBound && assetPrice <= priceUpperBound
            ) {
                return IChallengePool.Prediction.yes;
            }
        } else if (compareStrings(outcome, OUT)) {
            if (assetPrice < priceLowerBound || assetPrice > priceUpperBound) {
                return IChallengePool.Prediction.yes;
            }
        } else {
            return IChallengePool.Prediction.zero;
        }
        return IChallengePool.Prediction.no;
    }
}
