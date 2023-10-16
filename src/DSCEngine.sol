// SPDX-License-Identifier: MIT

// This is the Engine of the contract

// @audit-info - remove the ^
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

contract DSCEngine is ReentrancyGuard {
    /////////////////////////
    //   Errors           //
    ///////////////////////

    error DSCEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenNotAllowed(address token);
    error DSCEngine__TransferFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactorValue);
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorOk();
    error DSCEngine__HealthFactorNotImproved();
    //error revertIfHealthFactorIsBroken(address sender);

    ///////////////////////////////
    //   State Variables        //
    /////////////////////////////

    /// @info - Why token linked to an address priceFeed?
    // because is linked to a Chainlink feed that give the exact price.
    /// @dev Mapping of token address to price feed address
    mapping(address token => address priceFeed) private s_priceFeeds; // tokenToPriceFeed
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    /// @dev Amount of DSC minted by user
    mapping(address user => uint256 amount) private s_DSCMinted;

    /// @dev If we know exactly how many tokens we have, we could make this immutable!
    address[] private s_collateralTokens;

    DecentralizedStableCoin private immutable i_dsc;

    uint256 private constant LIQUIDATION_THRESHOLD = 50; // This means you need to be 200% over-collateralized
    uint256 private constant LIQUIDATION_BONUS = 10; // This means you get assets at a 10% discount when liquidating
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant FEED_PRECISION = 1e8;

    ///////////////////
    // Events        //
    ///////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

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
        address[] memory tokenAddresses, // las addresses de los tokens aceptados para el swap
        address[] memory priceFeedAddresses, // el precio de esos tokens
        address dscAddress // la address del token
    ) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
        }
        // @dev - Every token inside the s_priceFeeds is allowed
        // @dev - the rest are not.
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    ////////////////////////////////
    //   External Functions        //
    ////////////////////////////////
    function depositCollateralAndMintDsc() external {}

    /*
     * @dev - 1rst function (entrance)
     * @param - tokenCollateralAddress: The address of the token to deposit as collateral
     * @param - amountCollateral: The amount of collateral deposit
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function redeemCollateralForDsc() external {}

    function redeemCollateral() external {}

    /*
     * @dev - 2nd function. The user, after deposit, is authorised to mint
     * @param amountDscToMint: The amount of DSC you want to mint
     * You can only mint DSC if you hav enough collateral
     * @notice - they must have more collateral value than minimun threshold
     */
    function mintDsc(uint256 amountDscToMint) public moreThanZero(amountDscToMint) nonReentrant {
        s_DSCMinted[msg.sender] += amountDscToMint;
        // if they minted too much
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender, amountDscToMint);

        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    function burnDsc() external {}

    // @info - this function is to keep the collateral value
    // over the DSC value
    function liquidate() external {}

    function getHealtFactor() external view {}

    //////////////////////////////
    // Private & Internal View & Pure Functions
    //////////////////////////////
    // @dev remember use _ like _function() for internals

    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = s_DSCMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }

    /*
     * Returns how close to liquidation a user is
     * If a user goes below 1, then tey get liquidated
     */
    function _healthFactor(address user) private view returns (uint256) {
        // We need total DSC minted
        // We need total collateral value
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
        return _calculateHealthFactor(totalDscMinted, collateralValueInUsd);
    }

    function _calculateHealthFactor(uint256 totalDscMinted, uint256 collateralValueInUsd)
        internal
        pure
        returns (uint256)
    {
        // MIN_HEALTH_FACTOR = 1

        // health factor of 75
        // $150 ETH / 100 DSC = 1.5
        // 150 * 50 = 7500 / 100 = (75 / 100) < 1

        // health factor of 500
        // $1000 ETH / 100 DSC =
        // 1000 * 50 = 50000 / 100 = (500 / 100) > 1
        if (totalDscMinted == 0) return type(uint256).max;
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / 100;
        return (collateralAdjustedForThreshold * 1e18) / totalDscMinted;
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        // 1- check health factor:
        // https://docs.aave.com/risk/asset-risk/risk-parameters#health-factor
        // revert if they don´t
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreaksHealthFactor(userHealthFactor);
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    // External & Public View & Pure Functions
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    function _getUsdValue(address token, uint256 amount) public view returns (uint256) {
        // @dev we are using chainlink for the token value
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        // 1 ETH = 1000 USD
        // The returned value from Chainlink will be 1000 * 1e8
        // Most USD pairs have 8 decimals, so we will just pretend they all do
        // We want to have everything in terms of WEI, so we add 10 zeros at the end
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;
    }

    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        // loop throught each collateral token, get the amount they have deposited,
        // and map it to the price, to get the USD value
        for (uint256 index = 0; index < s_collateralTokens.length; index++) {
            address token = s_collateralTokens[index];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += _getUsdValue(token, amount);
        }
        return totalCollateralValueInUsd;
    }
}
