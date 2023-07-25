// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

import{DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";


/********************************************
 * ********** NOTAS ************************
 * 
 * Para hacer el deploy de DSCEngine se necesitan 3 datos según su constructor
 *      address[] memory tokenAddresses, // las addresses de los tokens aceptados para el swap
        address[] memory priceFeedAddresses, // el precio de esos tokens
        address dscAddress // la address del token
 * La address del token es dsc (ya hecho el deploy en run())
 * Para las otras dos se necesita un HelperConfig.s.sol
 * 
 * 
 */

contract DeployDSC is Script {

    // Valores para el constructor de DSCEngine
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;
    function run() external returns (DecentralizedStableCoin, DSCEngine, HelperConfig) {
        // Hemos creado un HelperConfig, un mock.sol que crea todos los datos para 
        // DSCEngine.sol en lugar de traerlos de Chainlink
        HelperConfig config = new HelperConfig();

        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc, uint256 deployerKey) = config.activeNetworkConfig();


        // Ahora alimentamos las variables del constructor de DSCEngine
        // con los datos que hemos creado y traido del HelperConfig.sol
        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];


        // Hacemos el deploy
        vm.startBroadcast(deployerKey);
        DecentralizedStableCoin dsc = new DecentralizedStableCoin();
        DSCEngine engine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));

        // el owner del token es el SCD
        dsc.transferOwnership(address(engine));
        vm.stopBroadcast();
        return (dsc, engine, config);
    }
}