// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title CommonEvent
 */
interface CommonEvent {
  
  event EVENT_SET(
        address indexed _deposit,
        address indexed _bridge
    );

    event CONFIT_NFT(
        address indexed _localNFT,
        address indexed _destNFT,
        uint256 _chainID
    );
    
    event DEPOSIT_TO(
        address _nft,
        address _from,
        address _to,
        uint256 _tokenID,
        uint256 _amount,
        uint8 nftStandard
    );
    
    event FINALIZE_DEPOSIT(
        address _nft,
        address _from,
        address _to,
        uint256 _tokenID,
        uint256 _amount,
        uint8 nftStandard
    );

    event DEPOSIT_FAILED(
        address _nft,
        address _from,
        address _to,
        uint256 _tokenID,
        uint256 _amount,
        uint8 nftStandard
    );


    event ROLLBACK(
        address _nft,
        address _from,
        address _to,
        uint256 _tokenID,
        uint256 _amount,
        uint8 nftStandard
    );
}