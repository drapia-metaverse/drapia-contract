pragma solidity ^0.8.0;

import "./@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./common/DRA20Payable.sol";
import "./common/DRAWithdrawable.sol";

contract DrapiaM is DRA20Payable, ERC20Burnable, DRAWithdrawable {
    uint256 public constant TOTAL_SUPPLY = 500_000_000 * 10 ** 18;

    constructor(string memory name, string memory symbol) public DRA20Payable(name, symbol) {
        _mint(_msgSender(), TOTAL_SUPPLY);
    }
}
