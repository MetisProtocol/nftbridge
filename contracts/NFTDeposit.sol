// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";

contract NFTDeposit is IERC721Receiver, ERC1155Receiver, AccessControl {
    
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    
    event ERC721ReceivedEvent(address indexed operator, address indexed from, uint256 tokenId, bytes data);
    event ERC1155ReceivedEvent(address indexed operator, address indexed from, uint256 id, uint256 value, bytes data);
    event ERC1155BatchReceivedEvent(address indexed operator, address indexed from, uint256[] ids, uint256[] values, bytes data);

    modifier onlyEOA(address _eoa) {
        require(!Address.isContract(_eoa), "Account not EOA");
        _;
    }

    constructor(address _owner, address _withdraw){
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(WITHDRAW_ROLE, _withdraw);
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes memory data) public virtual override returns (bytes4) {
        emit ERC1155ReceivedEvent(operator, from, id, value, data);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] memory ids, uint256[] memory values, bytes memory data) public virtual override returns (bytes4) {
        emit ERC1155BatchReceivedEvent(operator, from, ids, values, data);
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public virtual override returns (bytes4) {
        emit ERC721ReceivedEvent(operator, from, tokenId, data);
        return this.onERC721Received.selector;
    }
    
    function withdrawERC721(address _nft, address _to, uint256 _tokenId) external onlyRole(WITHDRAW_ROLE) onlyEOA(_to) {
        IERC721(_nft).safeTransferFrom(address(this), _to, _tokenId);
    }

    function withdrawERC1155(address _nft, address _to, uint256 _tokenId, uint256 _amount) external onlyRole(WITHDRAW_ROLE) onlyEOA(_to) {
        IERC1155(_nft).safeTransferFrom(address(this), _to, _tokenId, _amount, "");
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155Receiver, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}