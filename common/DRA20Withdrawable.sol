pragma solidity ^0.8.0;

import "../@openzeppelin/contracts/access/Ownable.sol";
import "../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract DRA20Withdrawable is Ownable {
    using SafeERC20 for IERC20;

    event ERC20Withdrawal(IERC20 token, address recipient, uint256 amount);

    /**
     * @notice Withdraws any tokens ERC20 in the contract.
     */
    function withdrawERC20(IERC20 token, address recipient, uint256 amount) external onlyOwner {
        token.safeTransfer(recipient, amount);
        emit ERC20Withdrawal(token, recipient, amount);
    }
}
