// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title NFTBridge
 */
interface IStandarERC1155 {
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;
}