// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";

import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";

contract DSCEngineTest is Test {
    //////////////////////////////////
    //  Fase que trae el deploy     //
    /////////////////////////////////

    DeployDSC deployer;
    DSCEngine public dsce;
    DecentralizedStableCoin public dsc;
    HelperConfig public config;

    address public ethUsdPriceFeed;
    address public btcUsdPriceFeed;
    address public weth;
    address public wbtc;
    uint256 public deployerKey;

    function setUp() public {
        deployer = new DeployDSC();

        // dsc y dsce son los contratos que hace el deploy
        (dsc, dsce, config) = deployer.run();
        //(ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc, deployerKey) = config.activeNetworkConfig();
    }

    ///////////////////////////
    //   Comienzan los test  //
    ///////////////////////////

    // Test 01: Funcion _getUsdValue()
    // Recibe un token (weth o wbtc) y una cantidad
    // Retorna el valor en stable DSC que le corresponde segun Chainlink
    function testGetUsdValue() public {}
}
