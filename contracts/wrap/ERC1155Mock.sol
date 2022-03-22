// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

//https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol
contract ERC1155Mock is ERC1155, AccessControl {
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(string memory _baseUri,
                address owner,
                address minter
                ) ERC1155(_baseUri) {
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(URI_SETTER_ROLE, owner);
        _setupRole(MINTER_ROLE, minter);
    }

    function setURI(string memory _baseUri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(_baseUri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
