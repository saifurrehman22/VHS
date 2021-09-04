// contracts/MyContract.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/access/AccessControl.sol";

/**
 *Submitted for verification at Etherscan.io on 2020-05-11
*/

contract VHS is  ERC721, Ownable {
    using SafeMath for uint256;

    // Mapping from token ID to the creator's address.
    mapping(uint256 => address) private tokenCreators;

    // Counter for creating token IDs
    uint256 private idCounter;  

    // Old SuperRare contract to look up token details.
    // ISuperRare private oldSuperRare;

    // Event indicating metadata was updated.
    event TokenURIUpdated(uint256 indexed _tokenId, string  _uri);

    constructor(
      string memory _name,
      string memory _symbol

    ) public
    ERC721(_name, _symbol)
    {
        
    }


    /**
     * @dev Checks that the token is owned by the sender.
     * @param _tokenId uint256 ID of the token.
     */
    modifier onlyTokenOwner(uint256 _tokenId) {
      address owner = ownerOf(_tokenId);
      require(owner == msg.sender, "must be the owner of the token");
      _;
    }

    /**
     * @dev Checks that the token was created by the sender.
     * @param _tokenId uint256 ID of the token.
     */
    modifier onlyTokenCreator(uint256 _tokenId) {
      address creator = tokenCreator(_tokenId);
      require(creator == msg.sender, "must be the creator of the token");
      _;
    }

    /**
     * @dev Adds a new unique token to the supply.
     * @param _uri string metadata uri associated with the token.
     */
    function addNewToken(string memory _uri , address payable tokenMintFor) onlyOwner public {

      _createToken(_uri, tokenMintFor);
    }

    /**
     * @dev Deletes the token with the provided ID.
     * @param _tokenId uint256 ID of the token.
     */
    function deleteToken(uint256 _tokenId) public onlyTokenOwner(_tokenId) {
      _burn( _tokenId);
    }

    /**
     * @dev Updates the token metadata if the owner is also the
     *      creator.
     * @param _tokenId uint256 ID of the token.
     * @param _uri string metadata URI.
     */
    function updateTokenMetadata(uint256 _tokenId, string memory _uri)
      public
      onlyTokenOwner(_tokenId)
      onlyTokenCreator(_tokenId)
    {
      _setTokenURI(_tokenId, _uri);
      emit TokenURIUpdated(_tokenId, _uri);
    }

    /**
    * @dev Gets the creator of the token.
    * @param _tokenId uint256 ID of the token.
    * @return address of the creator.
    */
    function tokenCreator(uint256 _tokenId) public view returns (address) {
        return tokenCreators[_tokenId];
    }

    /**
     * @dev Internal function for setting the token's creator.
     * @param _tokenId uint256 id of the token.
     * @param _creator address of the creator of the token.
     */
    function _setTokenCreator(uint256 _tokenId, address _creator) internal {
      tokenCreators[_tokenId] = _creator;
    }

    /**
     * @dev Internal function creating a new token.
     * @param _uri string metadata uri associated with the token
     * @param _creator address of the creator of the token.
     */
    function _createToken(string memory _uri, address _creator) internal returns (uint256) {
      uint256 newId = idCounter;
      idCounter++;
      _mint(_creator, newId);
      _setTokenURI(newId, _uri);
      _setTokenCreator(newId, _creator);
      return newId;
    }
}


