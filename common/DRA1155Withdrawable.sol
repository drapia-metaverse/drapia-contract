pragma solidity ^0.8.0;

import "../@openzeppelin/contracts/access/Ownable.sol";
import "../@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

abstract contract DRA1155Withdrawable is Ownable {

    event ERC721Withdrawal(IERC721 nft, address recipient, uint256 tokenId);

    event ERC1155Withdrawal(IERC1155 nft, address recipient, uint256 tokenId, uint256 amount);

    /**
     * @notice Withdraws any nft ERC721 in the contract.
     */
    function withdrawERC721(IERC721 nft, address recipient, uint256 tokenId) external onlyOwner {
        nft.safeTransferFrom(address(this), recipient, tokenId);
        emit ERC721Withdrawal(nft, recipient, tokenId);
    }

    /**
     * @notice Withdraws any nft ERC1155 in the contract.
     */
    function withdrawERC1155(IERC1155 nft, address recipient, uint256 tokenId, uint256 amount, bytes calldata data) external onlyOwner {
        nft.safeTransferFrom(address(this), recipient, tokenId, amount, data);
        emit ERC1155Withdrawal(nft, recipient, tokenId, amount);
    }
}
