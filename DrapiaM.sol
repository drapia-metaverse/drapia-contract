pragma solidity ^0.8.0;

import "./@openzeppelin/contracts/access/Ownable.sol";
import "./@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./common/DRA20Payable.sol";
import "./common/DRA20Withdrawable.sol";
import "./common/DRA1155Withdrawable.sol";

contract DrapiaM is DRA20Payable, ERC20Burnable, DRA20Withdrawable, DRA1155Withdrawable {
    uint256 public constant TOTAL_SUPPLY = 500_000_000 * 10 ** 18;

    constructor(string memory name, string memory symbol, address owner) public DRA20Payable(name, symbol, owner) {
        _mint(owner, TOTAL_SUPPLY);
    }
}
