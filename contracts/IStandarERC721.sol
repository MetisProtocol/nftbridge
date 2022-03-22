// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title NFTBridge
 */
interface IStandarERC721 {
    function mint(address _to, uint256 _tokenId) external;
}