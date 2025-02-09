// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./RWANft.sol";
import "./RWAToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RWADao is Ownable {
    RWANft public immutable NFT_CONTRACT;
    RWAToken public immutable TOKEN_CONTRACT;
    uint256 public tokenPrice;
    uint256 public constant FEE_PERCENTAGE = 300; // 3%

    struct ApprovedSale {
        address seller;
        uint256 amount;
        uint256 timestamp;
    }

    ApprovedSale[] public approvedSales;
    mapping(address => uint256) public sellerToAvailableTokens;

    event DaoCreated(address nftAddress, address tokenAddress);
    event TokensApprovedForSale(address seller, uint256 amount);
    event TokensPurchased(address seller, address buyer, uint256 amount, uint256 price);

    constructor(
        string memory nftName,
        string memory nftSymbol,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 initialSupply,
        uint256 initialTokenPrice,
        address initialOwnerAddress
    ) Ownable(msg.sender) {
        require(initialOwnerAddress != address(0), "Invalid initial owner address");
        require(initialTokenPrice > 0, "Price must be greater than 0");
        require(initialSupply > 0, "Supply must be greater than 0");

        // Create NFT contract and mint first NFT
        NFT_CONTRACT = new RWANft(nftName, nftSymbol);
        NFT_CONTRACT.mintDefaultNft();

        // Create Token contract and mint tokens directly to initial owner
        TOKEN_CONTRACT = new RWAToken(tokenName, tokenSymbol, 0); // Initialize with 0 supply
                
        // Mint tokens directly to initial owner
        TOKEN_CONTRACT.mintToAddress(initialOwnerAddress, initialSupply);

        tokenPrice = initialTokenPrice;
        emit DaoCreated(address(NFT_CONTRACT), address(TOKEN_CONTRACT));
    }

    function approveTokensForSale(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(TOKEN_CONTRACT.balanceOf(msg.sender) >= amount, "Insufficient balance");
        
        uint256 currentlyQueued = sellerToAvailableTokens[msg.sender];
        uint256 totalAfterRequest = currentlyQueued + amount;
        uint256 approved = TOKEN_CONTRACT.allowance(msg.sender, address(this));
        
        require(totalAfterRequest <= approved, 
            string(abi.encodePacked(
                "Total would exceed approval. Currently queued: ",
                toString(currentlyQueued),
                ", Requested: ",
                toString(amount),
                ", Total approval: ",
                toString(approved)
            ))
        );
   
        // Add to sales queue
        approvedSales.push(ApprovedSale({
            seller: msg.sender,
            amount: amount,
            timestamp: block.timestamp
        }));

        sellerToAvailableTokens[msg.sender] += amount;
        emit TokensApprovedForSale(msg.sender, amount);
    }

    function buyTokens(uint256 amount) external payable {
        require(amount > 0, "Amount must be greater than 0");
        require(msg.value == amount * tokenPrice, "Incorrect payment amount");
        
        uint256 remainingToBuy = amount;
        uint256 i = 0;
        
        while (remainingToBuy > 0 && i < approvedSales.length) {
            ApprovedSale storage sale = approvedSales[i];
            if (sale.amount > 0) {
                uint256 buyAmount = remainingToBuy > sale.amount ? sale.amount : remainingToBuy;
                
                // Calculate payment and fee
                uint256 payment = buyAmount * tokenPrice;
                uint256 fee = (payment * FEE_PERCENTAGE) / 10000;
                uint256 sellerPayment = payment - fee;
                
                // Transfer tokens from seller to buyer
                require(TOKEN_CONTRACT.transferFrom(sale.seller, msg.sender, buyAmount), "Token transfer failed");
                
                // Send payment to seller
                payable(sale.seller).transfer(sellerPayment);
                
                // Update records
                sale.amount -= buyAmount;
                sellerToAvailableTokens[sale.seller] -= buyAmount;
                remainingToBuy -= buyAmount;
                
                emit TokensPurchased(sale.seller, msg.sender, buyAmount, buyAmount * tokenPrice);
            }
            i++;
        }
        
        require(remainingToBuy == 0, "Not enough tokens available");
        _cleanupEmptySales();
    }

    function updateTokenPrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Price must be greater than 0");
        tokenPrice = newPrice;
    }

    function getAvailableTokensForSale() external view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < approvedSales.length; i++) {
            total += approvedSales[i].amount;
        }
        return total;
    }

    function _cleanupEmptySales() private {
        uint256 i = 0;
        while (i < approvedSales.length) {
            if (approvedSales[i].amount == 0) {
                approvedSales[i] = approvedSales[approvedSales.length - 1];
                approvedSales.pop();
            } else {
                i++;
            }
        }
    }

    function withdrawFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}