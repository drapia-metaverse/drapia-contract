pragma solidity ^0.8.0;

import "./IDRA1155.sol";
import "../@openzeppelin/contracts/utils/Context.sol";
import "../@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract DRA1155 is Context, IDRA1155, ERC721, ERC1155 {
    constructor(string memory name_, string memory symbol_, string memory uri_) ERC721(name_, symbol_) ERC1155(uri_) {

    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC1155, IERC165) returns (bool) {
        return
        interfaceId == type(IERC1155).interfaceId ||
    interfaceId == type(IERC1155MetadataURI).interfaceId ||
    interfaceId == type(IERC721).interfaceId ||
    interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds,
        bytes memory data
    ) public virtual {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            safeTransferFrom(from, to, tokenIds[i], data);
        }
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721, ERC1155, IDRA1155) {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal override(ERC721, ERC1155) virtual {
        ERC721._setApprovalForAll(owner, operator, approved);
        ERC1155._setApprovalForAll(owner, operator, approved);
        emit ApprovalForAll(owner, operator, approved);
    }

    function isApprovedForAll(address account, address operator) public override(ERC721, ERC1155, IDRA1155) view returns (bool) {
        return ERC721.isApprovedForAll(account, operator) && ERC1155.isApprovedForAll(account, operator);
    }
}
