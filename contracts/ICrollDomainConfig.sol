// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title ICrollDomainConfig
 */
interface ICrollDomainConfig {
    function configNFT(address L1NFT, address L2NFT, uint256 originNFTChainId) external;
}