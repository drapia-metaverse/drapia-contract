pragma solidity ^0.8.0;

import "../@openzeppelin/contracts/access/Ownable.sol";
import "../@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract DRA20Payable is ERC20, ERC20Permit, Ownable {
    address private drapiaCashier;

    mapping(uint256 => address) private businessCashiers;

    bool private useDrapiaCashier;

    mapping(uint256 => mapping(uint256 => bool)) usedInvoices;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PAYMENT_TYPEHASH =
    keccak256("Payment(uint256 channelId, uint256 invoiceNo, uint256 amount, uint256 deadline)");

    event DrapiaCashierChanged(address indexed previousDrapiaCashier, address indexed newDrapiaCashier);

    event BusinessCashierChanged(uint256 indexed channelId, address indexed previousBusinessCashier, address indexed newBusinessCashier);

    event UseDrapiaCashier(bool useDrapiaCashier);

    event Payment(uint256 indexed channelId, uint256 indexed invoiceNo, address indexed sender, address recipient, uint256 amount);

    constructor(string memory name, string memory symbol, address owner) ERC20(name, symbol) ERC20Permit(name) {
        drapiaCashier = owner;
        transferOwnership(owner);
    }

    function setUseDrapiaCashier(bool _useDrapiaCashier) external onlyOwner {
        useDrapiaCashier = _useDrapiaCashier;
        emit UseDrapiaCashier(_useDrapiaCashier);
    }

    function setDrapiaCashier(address newDrapiaCashier) external onlyOwner {
        require(newDrapiaCashier != address(0), "DRA20Payable: new drapiaCashier is the zero address");
        address oldDrapiaCashier = drapiaCashier;
        drapiaCashier = newDrapiaCashier;
        emit DrapiaCashierChanged(oldDrapiaCashier, newDrapiaCashier);
    }

    function setBusinessCashier(uint256 channelId, address newBusinessCashier) external onlyOwner {
        require(channelId > 0, "DRA20Payable: channelId is zero");
        address oldBusinessCashier = businessCashiers[channelId];
        businessCashiers[channelId] = newBusinessCashier;
        emit BusinessCashierChanged(channelId, oldBusinessCashier, newBusinessCashier);
    }

    function payment(uint256 channelId, uint256 invoiceNo, uint256 amount, uint256 deadline, bytes memory signature) external {
        require(block.timestamp <= deadline, "DRA20Payable: expired deadline");
        require(!usedInvoices[channelId][invoiceNo], "DRA20Payable: order already paid");
        address orderSigner;
        if (channelId == 0) {
            orderSigner = drapiaCashier;
        } else {
            orderSigner = businessCashiers[channelId];
            require(orderSigner != address(0), "DRA20Payable: invalid channelId");
        }
        bytes32 structHash = keccak256(abi.encode(_PAYMENT_TYPEHASH, channelId, invoiceNo, amount, deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, signature);

        require(signer == orderSigner, "DRA20Payable: invalid signature");
        address cashier = orderSigner;
        if (useDrapiaCashier) {
            cashier = drapiaCashier;
        }
        usedInvoices[channelId][invoiceNo] = true;
        _transfer(msg.sender, cashier, amount);
        emit Payment(channelId, invoiceNo, msg.sender, cashier, amount);
    }
}
