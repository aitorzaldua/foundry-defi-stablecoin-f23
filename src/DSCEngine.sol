// SPDX-License-Identifier: MIT

// This is the Engine of the contract

// @audit-info - remove the ^
pragma solidity ^0.8.18;

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
contract DSCEngine {
    function depositCollateralAndMIntDsc() external {}

    function redeemCollateralForDsc() external {}

    function burnDsc() external {}

    function liquidate() external {}

    



}
