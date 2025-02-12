// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RWAToken is ERC20, Ownable {
    // Mapping for instant holder verification (acts as a set)
    mapping(address => bool) private isActiveHolder;
    
    // Array to store holder addresses for iteration
    address[] private holdersList;

    // Mapping to store indices of holders in the array for O(1) removal
    mapping(address => uint256) public holderIndices;
    
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) Ownable(msg.sender) {
    }

    function mint(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        _mint(msg.sender, amount);
        _addHolder(msg.sender);
    }

    function mintToAddress(address buyerAddress, uint256 amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        _mint(buyerAddress, amount);
        _addHolder(buyerAddress);
    }

    function getBalance(address account) public view returns (uint256) {
        return balanceOf(account);
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply();
    }

    /**
     * @dev Returns array of all current token holders
     */
    function getHolders() public view returns (address[] memory) {
        return holdersList;
    }

    /**
     * @dev Returns if an address is a current token holder
     */
    function isHolder(address account) public view returns (bool) {
        return isActiveHolder[account];
    }

    /**
     * @dev Returns number of current token holders
     */
    function getHoldersCount() public view returns (uint256) {
        return holdersList.length;
    }

    /**
     * @dev Override _update to track active holders
     */
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // Call parent implementation first
        super._update(from, to, amount);

        // Handle new holder
        if (!isActiveHolder[to] && balanceOf(to) > 0) {
            _addHolder(to);
        }

        // Handle removed holder
        if (isActiveHolder[from] && balanceOf(from) == 0) {
            _removeHolder(from);
        }
    }

    /**
     * @dev Add new holder to the set - O(1) operation
     */
    function _addHolder(address holder) private {
        if (!isActiveHolder[holder] && holder != address(0)) {
            isActiveHolder[holder] = true;
            holderIndices[holder] = holdersList.length; // Store the index
            holdersList.push(holder);
        }
    }

    /**
     * @dev Remove holder from the set - O(1) operation
     * Uses stored indices for efficient removal
     */
    function _removeHolder(address holder) private {
        if (isActiveHolder[holder]) {
            // Get stored index of the holder to remove
            uint256 indexToRemove = holderIndices[holder];
            uint256 lastIndex = holdersList.length - 1;

            // If this is not the last element, move the last element to this position
            if (indexToRemove != lastIndex) {
                address lastHolder = holdersList[lastIndex];
                holdersList[indexToRemove] = lastHolder;
                holderIndices[lastHolder] = indexToRemove; // Update the index mapping
            }

            // Remove the last element
            holdersList.pop();
            
            // Clean up storage
            delete isActiveHolder[holder];
            delete holderIndices[holder];
        }
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}