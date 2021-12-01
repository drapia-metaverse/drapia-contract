pragma solidity ^0.8.0;

import "./common/DRA1155.sol";
import "./common/DRA1155PresetMinterPauser.sol";
import "./@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DrapiaItems is DRA1155PresetMinterPauser {
    constructor(string memory name, string memory symbol, string memory uri) DRA1155PresetMinterPauser(name, symbol, uri) {

    }

    function transform(address account, uint256 dmvAmount, uint256 rapiAmount, uint256[] memory nftInputs, uint256[] memory nftOutputs) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to transform");


    }
}
