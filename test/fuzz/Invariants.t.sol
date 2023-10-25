// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
 * What are our invariants?
 * 1.- El total supply de la stable coin DSC siempre debe ser menor que el valor total del collateral.
 * 2.- Las funciones getter nunca deben revert -> evergreen invariant
 */

contract OpenInvariantsTest is StdInvariant, Test {
    DeployDSC deployer;
    HelperConfig config;
    DSCEngine dsce;
    DecentralizedStableCoin dsc;

    address weth;
    address wbtc;

    function setUp() external {
        deployer = new DeployDSC();
        /*
         * La función run recibe como parámetros...
         *  function run() external returns (DecentralizedStableCoin, DSCEngine, HelperConfig) {...
         */
        (dsc, dsce, config) = deployer.run();
        targetContract(address(dsce));

        // Para invariant_protocolMustHaveMoreValueThanTotalSupply()
        // Nos traemos las addreses de weth y btc y se calcula la suma de los balances en el protocolo.
        (,, weth, wbtc,) = config.activeNetworkConfig();
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
        /*
         * 1.- get the value of all tyhe collateral in the protocol
         * 2.- compare it to all the debt
		 */
        
        // 1.- Se obtienen las cantidades en el protocolo
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dsce));
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(dsce));

        // Hay que comparar los valores en USDC de weth y wbtc no la cantidad en si
        // Tenemos funciones get para ello en el contrato
        uint256 wethValue = dsce._getUsdValue(weth, totalWethDeposited);
        uint256 wbtcValue = dsce._getUsdValue(wbtc, totalWbtcDeposited);

        console.log("weth value:   ", wethValue);
        console.log("wbtc value:   ", wbtcValue);
        console.log("total supply: ", totalSupply);

        // 2.- finalmente se crea la comparativa para que ejecute el invariant
        assert(wethValue + wbtcValue >= totalSupply);
    }
}
