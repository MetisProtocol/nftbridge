// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './wrap/ERC721Mock.sol';
import './wrap/ERC1155Mock.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

interface L1NFTBridge{
    function configNFT(address localNFT, address destNFT, uint256 originNFTChainId, uint32 destGasLimit) external payable;
}

contract BridgeFactory is Ownable{
    mapping(address => address) public getPair;

    address public bridge;

    event TokenTargetCreated(address indexed tokenSrc, address indexed tokenTag, address opt);

    // constructor(address _bridge) public {
    //     bridge = _bridge;
    // }

    function setbridge(address _bridge) external onlyOwner{
        require(_bridge != address(0),'Bridge: ZERO_ADDRESS');
        bridge = _bridge;
    }

    function create721Pair(
        address _tokenSrc,
        string memory _name,
        string memory _symbol,
        string memory _baseURI) 
        external returns (ERC721Mock tokenTag){
        require(_tokenSrc != address(0), 'Bridge: ZERO_ADDRESS');
        require(getPair[_tokenSrc] == address(0), 'Bridge: PAIR_EXISTS');
        tokenTag = new ERC721Mock(_name,_symbol,_baseURI,msg.sender,bridge);
        getPair[_tokenSrc] = address(tokenTag);
        emit TokenTargetCreated(_tokenSrc,address(tokenTag),msg.sender);
    }

    function create1155Pair(
        address _tokenSrc,
        string memory _baseURI) 
        external returns (ERC1155Mock tokenTag){        
        require(_tokenSrc != address(0), 'Bridge: ZERO_ADDRESS');
        require(getPair[_tokenSrc] == address(0), 'Bridge: PAIR_EXISTS');
        tokenTag = new ERC1155Mock(_baseURI,msg.sender,bridge);
        getPair[_tokenSrc] = address(tokenTag);
        emit TokenTargetCreated(_tokenSrc,address(tokenTag),msg.sender);
    }

    function bindAddress(
        address _tokenSrc,
        address _tokenTag) 
        external{
        require(_tokenSrc != address(0), 'Bridge: ZERO_ADDRESS');
        require(_tokenTag != address(0), 'Bridge: ZERO_ADDRESS');
        require(getPair[_tokenSrc] == address(0), 'Bridge: PAIR_EXISTS');
        getPair[_tokenSrc] = _tokenTag;
        emit TokenTargetCreated(_tokenSrc,_tokenTag,msg.sender);
    }

    function setPair(
        address _tokenSrc,
        address _tokenTag) 
        external onlyOwner {
        require(_tokenSrc != address(0), 'Bridge: ZERO_ADDRESS');
        require(_tokenTag != address(0), 'Bridge: ZERO_ADDRESS');
        require(getPair[_tokenSrc] != address(0), 'Bridge: PAIR_NOT_EXISTS');
        getPair[_tokenSrc] = _tokenTag;
        emit TokenTargetCreated(_tokenSrc,_tokenTag,msg.sender);
    }

    function setNft(
        address localNFT, 
        address destNFT, 
        uint256 originNFTChainId, 
        uint32 destGasLimit) 
        external payable {
        require(bridge != address(0),"Bridge:Bridge address is zero");
        require(localNFT != address(0),"Bridge:localNFT address is zero");
        require(destNFT != address(0),"Bridge:destNFT address is zero");
        L1NFTBridge(bridge).configNFT{value:msg.value}(localNFT,destNFT,originNFTChainId,destGasLimit);
    }
}