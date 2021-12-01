pragma solidity ^0.8.0;

import "../@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IDRA1155 is IERC721, IERC1155 {
    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setApprovalForAll(address operator, bool approved) external override(IERC721, IERC1155);

    function isApprovedForAll(address account, address operator) external override(IERC721, IERC1155) view returns (bool);
}
