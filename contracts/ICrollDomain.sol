// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title ICrollDomain
 */
interface ICrollDomain {
    function finalizeDeposit(address _nft, address _from, address _to, uint256 _id, uint256 _amount, uint8 nftStandard) external;
}