// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// import "openzeppelin-solidity-pixura/contracts/token/ERC721/ERC721.sol";
// import "openzeppelin-solidity-pixura/contracts/access/Ownable.sol";
// import "openzeppelin-solidity-pixura/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/math/SafeMath.sol";
import "./IVHS.sol";
import "./IERC721Creator.sol";

/**
 * @title SuperRare Legacy Tokens
 * @dev This contract acts the new SuperRare Legacy contract (formerly known as VHS).
 * It is used to upgrade VHS tokens to make them fully ERC721 compliant.
 *
 * Steps for upgrading:
 * 1.) As the token owner, make sure you are the `preUpgradeOwner` to ensure you are the receiver of the new token.
 * 2.) Transfer your old token to this contract's address.
 * 3.) Boom! You're now the owner of the upgraded token.
 *
 */
contract VHSLegacy is ERC721, IERC721Creator, Ownable {
    using SafeMath for uint256;

    /////////////////////////////////////////////////////////////////////////
    // State Variables
    /////////////////////////////////////////////////////////////////////////

    // Old SuperRare contract to look up token details.
    IVHS private oldSuperRare;

    // Mapping from token ID to the pre upgrade token owner.
    mapping(uint256 => address) private _tokenOwnerPreUpgrade;

    // Boolean for when minting has completed.
    bool private _mintingCompleted;

    /////////////////////////////////////////////////////////////////////////
    // Constructor
    /////////////////////////////////////////////////////////////////////////
    constructor(
        string memory _name,
        string memory _symbol,
        address _oldSuperRare
    ) public ERC721(_name, _symbol) {
        require(
            _oldSuperRare != address(0),
            "constructor::Cannot have null address for _oldSuperRare"
        );

        // Set old SuperRare.
        oldSuperRare = IVHS(_oldSuperRare);

        // Mark minting as not completed
        _mintingCompleted = false;
    }

    /////////////////////////////////////////////////////////////////////////
    // Admin Methods
    /////////////////////////////////////////////////////////////////////////

    /////////////////////////////////////////////////////////////////////////
    // mintLegacyTokens
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Mints the legacy tokens without emitting any events.
     * @param _tokenIds uint256 array of token ids to mint.
     */
    function mintLegacyTokens(uint256[] calldata _tokenIds) external onlyOwner {
        require(
            !_mintingCompleted,
            "VHSLegacy: Cannot mint tokens once minting has completed."
        );
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _createLegacyToken(_tokenIds[i]);
        }
    }

    /////////////////////////////////////////////////////////////////////////
    // markMintingCompleted
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Marks _mintedCompleted as true which forever prevents any more minting.
     */
    function markMintingCompleted() external onlyOwner {
        require(
            !_mintingCompleted,
            "VHSLegacy: Cannot mark completed if already completed."
        );
        _mintingCompleted = true;
    }

    /////////////////////////////////////////////////////////////////////////
    // Public Methods
    /////////////////////////////////////////////////////////////////////////

    /////////////////////////////////////////////////////////////////////////
    // ownerOf
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Returns the owner of the NFT specified by `tokenId`
     * @param _tokenId uint256 token id to get the owner of.
     * @return owner address of the token owner.
     */
    function ownerOf(uint256 _tokenId)
        public
        view
        override
        returns (address owner)
    {
        if (!isUpgraded((_tokenId))) {
            return address(this);
        }
        return ERC721.ownerOf(_tokenId);
    }

    /////////////////////////////////////////////////////////////////////////
    // preUpgradeOwnerOf
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Returns the pre-upgrade token owner of the NFT specified by `tokenId`.
     * This owner will become the owner of the upgraded token.
     * @param _tokenId uint256 token id to get the pre-upgrade owner of.
     * @return address of the token pre-upgrade owner.
     */
    function preUpgradeOwnerOf(uint256 _tokenId) public view returns (address) {
        address preUpgradeOwner = _tokenOwnerPreUpgrade[_tokenId];
        require(
            preUpgradeOwner != address(0),
            "VHSLegacy: pre-upgrade owner query for nonexistent token"
        );
        return preUpgradeOwner;
    }

    /////////////////////////////////////////////////////////////////////////
    // isUpgraded
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Returns whether the token has been upgraded.
     * @param _tokenId uint256 token id to get the owner of.
     * @return bool of whether the token has been upgraded.
     */
    function isUpgraded(uint256 _tokenId) public view returns (bool) {
        address ownerOnOldSuperRare = oldSuperRare.ownerOf(_tokenId);
        return address(this) == ownerOnOldSuperRare;
    }

    /////////////////////////////////////////////////////////////////////////
    // refreshPreUpgradeOwnerOf
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Refreshes the pre-upgrade token owner. Useful in the event of a
     * non-upgraded token transferring ownership. Throws if token has upgraded
     * or if there is nothing to refresh.
     * @param _tokenId uint256 token id to refresh the pre-upgrade token owner.
     */
    function refreshPreUpgradeOwnerOf(uint256 _tokenId) external {
        require(
            !isUpgraded(_tokenId),
            "VHSLegacy: cannot refresh an upgraded token"
        );
        address ownerOnOldSuperRare = oldSuperRare.ownerOf(_tokenId);
        address outdatedOwner = preUpgradeOwnerOf(_tokenId);
        require(
            ownerOnOldSuperRare != outdatedOwner,
            "VHSLegacy: cannot refresh when pre-upgrade owners match"
        );
        // _transferFromNoEvent(outdatedOwner, ownerOnOldSuperRare, _tokenId);
        _tokenOwnerPreUpgrade[_tokenId] = ownerOnOldSuperRare;
    }

    /////////////////////////////////////////////////////////////////////////
    // tokenCreator
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Refreshes the pre-upgrade token owner. Useful in the event of a
     * non-upgraded token transferring ownership. Throws if token has upgraded
     * or if there is nothing to refresh.
     * @param _tokenId uint256 token id to refresh the pre-upgrade token owner.
     * @return address of the token pre-upgrade owner.
     */
    function tokenCreator(uint256 _tokenId)
        external
        view
        override
        returns (address payable)
    {
        return oldSuperRare.creatorOfToken(_tokenId);
    }

    /////////////////////////////////////////////////////////////////////////
    // tokenURI
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Returns the URI for a given token ID. May return an empty string.
     * If the token's URI is non-empty and a base URI was set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 token id to refresh the pre-upgrade token owner.
     * @return string URI of the given token ID.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "VHSLegacy: URI query for nonexistent token"
        );
        return oldSuperRare.tokenURI(tokenId);
    }

    /////////////////////////////////////////////////////////////////////////
    // Internal Methods
    /////////////////////////////////////////////////////////////////////////

    /////////////////////////////////////////////////////////////////////////
    // _createLegacyToken
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Mints a legacy token with the appropriate metadata and owner.
     * @param _tokenId uint256 token id to get the owner of.
     */
    function _createLegacyToken(uint256 _tokenId) internal {
        address ownerOnOldSuperRare = oldSuperRare.ownerOf(_tokenId);
        // _mintWithNoEvent(ownerOnOldSuperRare, _tokenId);
        _tokenOwnerPreUpgrade[_tokenId] = ownerOnOldSuperRare;
    }
}
