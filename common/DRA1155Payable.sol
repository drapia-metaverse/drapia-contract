pragma solidity ^0.8.0;

import "../@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./DRA1155Permit.sol";

abstract contract DRA1155Payable is DRA1155Permit, AccessControlEnumerable {
    using SafeERC20 for IERC20;

    struct ChannelData {
        address orderSigner;
        address cashier;
        mapping(uint256 => bool) usedInvoices;
    }

    mapping(uint256 => ChannelData) public paymentChannels;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 public immutable _PAYMENT_TYPEHASH =
    keccak256("Payment(uint256 channelId,uint256 invoiceNo,uint256 deadline,uint256[] nftItems,uint256[] ftItems,uint256[] ftAmounts)");

    bytes32 public immutable _WITHDRAW_TOKEN_TYPEHASH =
    keccak256("Withdraw(uint256 channelId,uint256 invoiceNo,uint256 deadline,IERC20 tokenContract,address recipient,uint256 amount)");

    bytes32 public immutable _WITHDRAW_ITEM_TYPEHASH =
    keccak256("Withdraw(uint256 channelId,uint256 invoiceNo,uint256 deadline,DRA1155 itemContract,address recipient,uint256[] nftItems,uint256[] ftItems,uint256[] ftAmounts)");

    event PaymentChannelChanged(uint256 indexed channelId, address oldOrderSigner, address oldCashier, address indexed newOrderSigner, address indexed newCashier);

    event Payment(uint256 indexed channelId, uint256 indexed invoiceNo, address indexed sender, address recipient, uint256[] nftItems, uint256[] ftItems, uint256[] ftAmounts);

    event TokenWithdrawal(uint256 indexed channelId, uint256 indexed invoiceNo, IERC20 tokenContract, address sender, address indexed recipient, uint256 amount);

    event ItemWithdrawal(uint256 indexed channelId, uint256 indexed invoiceNo, DRA1155 itemContract, address sender, address indexed recipient, uint256[] nftItems, uint256[] ftItems, uint256[] ftAmounts);

    bytes32 public constant PAYMENT_MANAGER_ROLE = keccak256("PAYMENT_MANAGER_ROLE");

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(string memory name, string memory symbol, string memory uri) DRA1155(name, symbol, uri) DRA1155Permit(name) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAYMENT_MANAGER_ROLE, _msgSender());
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, DRA1155) returns (bool) {
        return AccessControlEnumerable.supportsInterface(interfaceId) || DRA1155.supportsInterface(interfaceId);
    }

    function setPaymentChannel(uint256 channelId, address newOrderSigner, address newCashier) external onlyRole(PAYMENT_MANAGER_ROLE) {
        require(channelId >= 0, "DRA1155Payable: channelId is negative");
        require((newOrderSigner != address(0) && newCashier != address(0))
            || (newOrderSigner == address(0) && newCashier == address(0)), "DRA1155Payable: newOrderSigner is address(0) while newCashier is not, and vice versa");
        ChannelData storage paymentChannel = paymentChannels[channelId];
        address oldOrderSigner = paymentChannel.orderSigner;
        address oldCashier = paymentChannel.cashier;
        paymentChannel.orderSigner = newOrderSigner;
        paymentChannel.cashier = newCashier;
        emit PaymentChannelChanged(channelId, oldOrderSigner, oldCashier, newOrderSigner, newCashier);
    }

    function paymentFrom(uint256 channelId, uint256 invoiceNo, uint256 deadline, address sender, uint256[] memory nftItems, uint256[] memory ftItems, uint256[] memory ftAmounts, bytes memory signature) external {
        require(block.timestamp <= deadline, "DRA1155Payable: expired deadline");
        ChannelData storage paymentChannel = paymentChannels[channelId];
        address orderSigner = paymentChannel.orderSigner;
        address cashier = paymentChannel.cashier;
        require(orderSigner != address(0) && cashier != address(0), "DRA1155Payable: invalid channelId");
        require(!paymentChannel.usedInvoices[invoiceNo], "DRA1155Payable: order already paid");
        bytes32 structHash = keccak256(abi.encode(_PAYMENT_TYPEHASH, channelId, invoiceNo, deadline, nftItems, ftItems, ftAmounts));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, signature);
        require(signer == orderSigner, "DRA1155Payable: invalid signature");

        paymentChannel.usedInvoices[invoiceNo] = true;
        safeBatchTransferFrom(sender, cashier, nftItems, "");
        if (ftItems.length > 0) {
            safeBatchTransferFrom(sender, cashier, ftItems, ftAmounts, "");
        }
        emit Payment(channelId, invoiceNo, sender, cashier, nftItems, ftItems, ftAmounts);
    }

    function withdraw(uint256 channelId, uint256 invoiceNo, uint256 deadline, IERC20 tokenContract, address recipient, uint256 amount, bytes memory signature) external {
        require(block.timestamp <= deadline, "DRA1155Payable: expired deadline");
        ChannelData storage paymentChannel = paymentChannels[channelId];
        address orderSigner = paymentChannel.orderSigner;
        address cashier = paymentChannel.cashier;
        require(orderSigner != address(0) && cashier != address(0), "DRA1155Payable: invalid channelId");
        require(!paymentChannel.usedInvoices[invoiceNo], "DRA1155Payable: order already paid");
        bytes32 structHash = keccak256(abi.encode(_WITHDRAW_TOKEN_TYPEHASH, channelId, invoiceNo, deadline, tokenContract, recipient, amount));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, signature);
        require(signer == orderSigner, "DRA1155Payable: invalid signature");

        paymentChannel.usedInvoices[invoiceNo] = true;
        tokenContract.safeTransferFrom(cashier, recipient, amount);
        emit TokenWithdrawal(channelId, invoiceNo, tokenContract, cashier, recipient, amount);
    }

    function withdrawOrMint(uint256 channelId, uint256 invoiceNo, uint256 deadline, address recipient, uint256[] memory nftItems, uint256[] memory ftItems, uint256[] memory ftAmounts, bytes memory signature) external {
        require(block.timestamp <= deadline, "DRA1155Payable: expired deadline");
        ChannelData storage paymentChannel = paymentChannels[channelId];
        address orderSigner = paymentChannel.orderSigner;
        address cashier = paymentChannel.cashier;
        require(orderSigner != address(0) && cashier != address(0), "DRA1155Payable: invalid channelId");
        require(!paymentChannel.usedInvoices[invoiceNo], "DRA1155Payable: order already paid");
        bytes32 structHash = keccak256(abi.encode(_WITHDRAW_ITEM_TYPEHASH, channelId, invoiceNo, deadline, this, recipient, nftItems, ftItems, ftAmounts));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, signature);
        require(signer == orderSigner, "DRA1155Payable: invalid signature");

        paymentChannel.usedInvoices[invoiceNo] = true;
        _safeBatchTransferOrMint(signer, cashier, recipient, nftItems);
        _safeBatchTransferOrMint(signer, cashier, recipient, ftItems, ftAmounts);
        emit ItemWithdrawal(channelId, invoiceNo, this, cashier, recipient, nftItems, ftItems, ftAmounts);
    }

    function _safeBatchTransferOrMint(address signer, address cashier, address recipient, uint256[] memory nftItems) internal {
        if (nftItems.length == 0) {
            return;
        }
        _checkRole(MINTER_ROLE, signer);
        require(
            cashier == signer || isApprovedForAll(cashier, signer) || cashier == address(this),
            "DRA1155Payable: signer is not owner nor approved to transfer or mint"
        );
        uint256 tokenId;
        for (uint256 i = 0; i < nftItems.length; ++i) {
            tokenId = nftItems[i];
            if (!_exists(tokenId)) {
                _safeMint(recipient, tokenId, "");
            } else {
                require(cashier == ERC721.ownerOf(tokenId), "DRA1155Payable: cashier is not owner of nftItems");
                _safeTransfer(cashier, recipient, tokenId, "");
            }
        }
    }

    function _safeBatchTransferOrMint(address signer, address cashier, address recipient, uint256[] memory ftItems, uint256[] memory ftAmounts) internal {
        require(ftItems.length == ftAmounts.length, "DRA1155Payable: ftItems and ftAmounts length mismatch");
        if (ftItems.length == 0) {
            return;
        }
        _checkRole(MINTER_ROLE, signer);
        require(
            cashier == signer || isApprovedForAll(cashier, signer) || cashier == address(this),
            "DRA1155Payable: signer is not owner nor approved to transfer or mint"
        );
        uint256 ftBalance;
        for (uint256 i = 0; i < ftItems.length; ++i) {
            ftBalance = balanceOf(cashier, ftItems[i]);
            if (ftBalance < ftAmounts[i]) {
                _mint(cashier, ftItems[i], 1000 * ftAmounts[i], "");
            }
        }
        _safeBatchTransferFrom(cashier, recipient, ftItems, ftAmounts, "");
    }

    function isSettled(uint256 channelId, uint256 invoiceNo) external view returns (bool) {
        return paymentChannels[channelId].usedInvoices[invoiceNo];
    }
}
