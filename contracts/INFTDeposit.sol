// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title NFTBridge
 */
interface INFTDeposit {

    function withdrawERC721(
        address _nft, 
        address _to, 
        uint256 _tokenId
    )
        external;

    function withdrawERC1155(
        address _nft, 
        address _to, 
        uint256 _tokenId, 
        uint256 _amount
    ) 
        external;
}
