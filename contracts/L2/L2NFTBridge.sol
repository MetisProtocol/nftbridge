// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IStandarERC721 } from "../IStandarERC721.sol";
import { IStandarERC1155 } from "../IStandarERC1155.sol";

import { CrossDomainEnabled } from "../gateway/CrossDomainEnabled.sol";

import { Lib_PredeployAddresses } from "../gateway/Lib_PredeployAddresses.sol";
import { iOVM_GasPriceOracle } from "../gateway/iOVM_GasPriceOracle.sol";

import { ICrollDomain } from "../ICrollDomain.sol";

import { CommonEvent } from "../CommonEvent.sol";

import { INFTDeposit } from "../INFTDeposit.sol";

contract L2NFTBridge is AccessControl, CrossDomainEnabled, CommonEvent {
    
    // rollback
    bytes32 public constant ROLLBACK_ROLE = keccak256("ROLLBACK_ROLE");

    // L1 bridge
    address public destNFTBridge;
    
    // L2 nft deposit
    address public localNFTDeposit;

    // get current chainid
    function getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
    
    // nft supported
    enum nftenum {
        ERC721,
        ERC1155
    }
    
    // L2 nft => L1 nft
    mapping(address => address) public clone;
    
    // L2 nft => is the original
    mapping(address => bool) public isOrigin;
    
    // L2 nft => L2 nft id => is deposited
    mapping(address => mapping( uint256 => bool )) public isDeposit;
    
    // L2 nft => L2 nft id => deposit user
    mapping(address => mapping( uint256 => address )) public depositUser;

    modifier onlyEOA() {
        require(!Address.isContract(msg.sender), "Account not EOA");
        _;
    }

    constructor(address _owner, address _rollback, address _localMessenger) CrossDomainEnabled(_localMessenger) {
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(ROLLBACK_ROLE, _rollback);
    }

    /** config 
     * 
     * @param _localNFTDeposit L2 deposit
     * @param _destNFTBridge L1 bridge
     */
    function set(address _localNFTDeposit, address _destNFTBridge) public onlyRole(DEFAULT_ADMIN_ROLE) {
        
        require(destNFTBridge == address(0), "Already configured.");

        localNFTDeposit = _localNFTDeposit;
        destNFTBridge = _destNFTBridge;

        emit EVENT_SET(localNFTDeposit, destNFTBridge);
    }
    
    /** L1 bridge role config nft clone
     * 
     * @param localNFT nft on this chain
     * @param destNFT nft on L1
     * @param originNFTChainId origin NFT ChainId 
     */
    function configNFT(address destNFT, address localNFT, uint256 originNFTChainId) external virtual onlyFromCrossDomainAccount(destNFTBridge) {
        clone[localNFT] = destNFT;
        uint256 localChainId = getChainID();
        
        isOrigin[localNFT] = false;
        if(localChainId == originNFTChainId){
            isOrigin[localNFT] = true;
        }

        emit CONFIT_NFT(localNFT, destNFT, originNFTChainId);
    }
    
    /** deposit nft into L2 deposit
     * 
     * @param localNFT nft on this chain
     * @param destTo owns nft on L1
     * @param id nft id  
     * @param nftStandard nft type
     * @param destGas L1 gas
     */
    function depositTo(address localNFT, address destTo, uint256 id,  nftenum nftStandard, uint32 destGas) external payable onlyEOA() {
       
        require(clone[localNFT] != address(0), "NFT not config.");

        require(isDeposit[localNFT][id] == false, "Don't redeposit.");

        uint256 minL1Gas = iOVM_GasPriceOracle(Lib_PredeployAddresses.OVM_GASPRICE_ORACLE).minErc20BridgeCost();

        require (msg.value >= minL1Gas, string(abi.encodePacked("insufficient depositTo fee supplied. need at least ", uint2str(minL1Gas))));

        uint256 amount = 0;
       
        if(nftenum.ERC721 == nftStandard) {
            IERC721(localNFT).safeTransferFrom(msg.sender, localNFTDeposit, id);
        }
       
        if(nftenum.ERC1155 == nftStandard) {
            amount = IERC1155(localNFT).balanceOf(msg.sender, id);
            require(amount == 1, "Not an NFT token.");
            IERC1155(localNFT).safeTransferFrom(msg.sender, localNFTDeposit, id, amount, "");
        }
       
        _depositStatus(localNFT, id, msg.sender, true);

        address destNFT = clone[localNFT];

        _messenger(destNFT, msg.sender, destTo, id, amount, uint8(nftStandard), destGas);

        emit DEPOSIT_TO(destNFT, msg.sender, destTo, id, amount, uint8(nftStandard));
    }

    function _depositStatus(address _nft, uint256 _id, address _user, bool _isDeposit) internal {
        isDeposit[_nft][_id] = _isDeposit;
        depositUser[_nft][_id] = _user;
    }

    /** deposit messenger
     * 
     * @param destNFT nft on L1
     * @param from msg.sender
     * @param destTo owns nft on L1
     * @param id nft id  
     * @param amount amount
     * @param nftStandard nft type
     * @param destGas L1 gas
     */
    function _messenger(address destNFT, address from, address destTo, uint256 id, uint256 amount, uint8 nftStandard, uint32 destGas) internal {

        bytes memory message = abi.encodeWithSelector(
            ICrollDomain.finalizeDeposit.selector,
            destNFT,
            from,
            destTo,
            id,
            amount,
            nftStandard
        );
        
        sendCrossDomainMessage(
            destNFTBridge,
            destGas,
            message,
            msg.value
        );
    }

    /** clone nft
     *
     * @param  _localNFT nft
     * @param  _destFrom  owns nft on l2 
     * @param  _localTo give to
     * @param  id nft id
     * @param  _amount nft amount
     * @param  nftStandard nft type
     */
    function finalizeDeposit(address _localNFT, address _destFrom, address _localTo, uint256 id, uint256 _amount, nftenum nftStandard) external virtual onlyFromCrossDomainAccount(destNFTBridge) {
        
        if(nftenum.ERC721 == nftStandard) {
            if(isDeposit[_localNFT][id]){
                INFTDeposit(localNFTDeposit).withdrawERC721(_localNFT, _localTo, id);
            }else{
                if(isOrigin[_localNFT]){
                    // What happened
                    emit DEPOSIT_FAILED(_localNFT, _destFrom, _localTo, id, _amount, uint8(nftStandard));
                }else{
                    IStandarERC721(_localNFT).mint(_localTo, id);
                }
            }
        }

        if(nftenum.ERC1155 == nftStandard) {
            if(isDeposit[_localNFT][id]){
                INFTDeposit(localNFTDeposit).withdrawERC1155(_localNFT, _localTo, id, _amount);
            }else{
                 if(isOrigin[_localNFT]){
                    // What happened
                    emit DEPOSIT_FAILED(_localNFT, _destFrom, _localTo, id, _amount, uint8(nftStandard));
                }else{
                    IStandarERC1155(_localNFT).mint(_localTo, id, _amount, "");
                }
            }
        }

        _depositStatus(_localNFT, id, address(0), false);

        emit FINALIZE_DEPOSIT(_localNFT, _destFrom, _localTo, id, _amount, uint8(nftStandard));
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /** hack rollback
     * 
     * @param nftStandard nft type
     * @param _localNFT nft
     * @param ids tokenid
     */
    function rollback(nftenum nftStandard, address _localNFT, uint256[] memory ids) public onlyRole(ROLLBACK_ROLE) {
        
        for( uint256 index; index < ids.length; index++ ){
            
            uint256 id = ids[index];

            address _depositUser = depositUser[_localNFT][id];

            require(isDeposit[_localNFT][id], "Not Deposited");
            
            require(_depositUser != address(0), "user can not be zero address.");
            
            uint256 amount = 0;
            
            if(nftenum.ERC721 == nftStandard) {
                INFTDeposit(localNFTDeposit).withdrawERC721(_localNFT, _depositUser, id);
            }else{
                amount = 1;
                INFTDeposit(localNFTDeposit).withdrawERC1155(_localNFT, _depositUser, id, amount);
            }
    
            _depositStatus(_localNFT, id, address(0), false);

            emit ROLLBACK(_localNFT, localNFTDeposit, _depositUser, id, amount, uint8(nftStandard));
        }
    }
}
