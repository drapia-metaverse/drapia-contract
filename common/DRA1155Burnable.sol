pragma solidity ^0.8.0;

import "./DRA1155.sol";

/**
 * @dev Extension of {DRA1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 */
abstract contract DRA1155Burnable is DRA1155 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "DRA1155Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "DRA1155Burnable: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "DRA1155Burnable: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}
