// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface iOVM_GasPriceOracle{
    function minErc20BridgeCost() view external returns(uint256);
}
