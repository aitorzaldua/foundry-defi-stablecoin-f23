// SPDX-License-Identifier: MIT

// This is the Engine of the contract

// @audit-info - remove the ^
pragma solidity ^0.8.18;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*
* @title DSCEngine
* @author Aitor Zaldua
*
* The system is designed to be as minimal as possible,
  and have the tokens maintain a 1 token == $1 peg
* This stablecoin has the properties:
* - Exogeneous Collateral
* - Dollar Pegged
* - Algoritmically Stable
*
* It is similar to DAI if DAI has no governance, no fees,
* and was only backed ny wETH and wBTC.
*
* Our DSC system should always be "overcollateralized". At no point, should the value of
  all collateral <= the $ backed value of all the DSC.
*
* @notice THis contract is the core of the system. It habdles all the logic for
  mining and redeeming DSC, as well as depositing & withdrawing collateral.
* @notice THis contract is very Loosely based on the MakerDAO DSS (DAI) system.
*/

contract DSCEngine is ReentrancyGuard{
    /////////////////////////
    //   Errors           //
    ///////////////////////

    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
    error DSCEngine__TokenNotAllowed(address token);

    ///////////////////////////////
    //   State Variables        //
    /////////////////////////////
    DecentralizedStableCoin private immutable i_dsc;

    // @info - Why token linked to an address priceFeed?
    // because is linked to a Chainlink feed that give the exact price.
    mapping(address token => address priceFeed) private s_priceFeeds; // tokenToPriceFeed

    /////////////////////////
    //   Modifiers        //
    ///////////////////////
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine__TokenNotAllowed(token);
        }
        _;
    }

    /////////////////////////
    //   Functions        //
    ///////////////////////
    constructor(
        address[] memory tokenAddresses,
        address[] memory priceFeedAddresses,
        address dscAddress
    ) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
        }
        // @dev - Every token inside the s_priceFeeds is allowed
        // @dev - the rest are not.
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            //s_collateralTokens.push(tokenAddresses[i]);
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    ////////////////////////////////
    //   External Functions        //
    ////////////////////////////////
    function depositCollateralAndMintDsc() external {}

    /*
     * @param - tokenCollateralAddress: The address of the token to deposit as collateral
     * @param - amountCollateral: The amount of collateral deposit
     */
    function depositCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    ) external moreThanZero(amountCollateral) isAllowedToken(tokenCollateralAddress) nonReentrant {}

    function redeemCollateralForDsc() external {}

    function redeemCollateral() external {}

    function mintDSC() external {}

    function burnDsc() external {}

    // @info - this function is to keep the collateral value
    // over the DSC value
    function liquidate() external {}

    function getHealtFactor() external view {}
}
