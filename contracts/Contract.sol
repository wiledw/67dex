// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * ============================================================
 * KEY CONCEPTS: msg vs this
 * ============================================================
 *
 * msg.sender  = The wallet address of the USER calling the function
 * msg.value   = The amount of ETH the USER sent with the transaction
 *
 * address(this) = The address of THIS CONTRACT (the DEX itself)
 * this.balance  = How much ETH this contract holds
 *
 * Example:
 *   User (0x123...) calls addLiquidity() and sends 1 ETH
 *   → msg.sender = 0x123... (user's wallet)
 *   → msg.value = 1 ETH (what user sent)
 *   → address(this) = 0xDEX... (this contract's address)
 * ============================================================
 */

import {ERC20Base} from "@thirdweb-dev/contracts/base/ERC20Base.sol";

contract DEX is ERC20Base {
    // Address of the token being traded (e.g., "67" token)
    address public token;

    /**
     * Constructor: Runs once when the contract is deployed
     * Sets up the DEX with the token address and admin
     */
    constructor(
        address _token, // Address of the token to trade
        address _defaultAdmin, // Admin who controls the contract
        string memory _name, // Name of LP token (e.g., "DEX LP Token")
        string memory _symbol // Symbol of LP token (e.g., "DEXLP")
    ) ERC20Base(_defaultAdmin, _name, _symbol) {
        token = _token; // Store the token address for later use
    }

    /**
     * Returns how many tokens are held by this DEX contract
     */
    function getTokensInContract() public view returns (uint256) {
        // Check the token balance of THIS contract (the DEX)
        return ERC20Base(token).balanceOf(address(this));
    }

    /**
     * Add liquidity to the pool
     * User sends ETH (via msg.value) + tokens (via _amount)
     * Returns: LP tokens minted to the user
     */
    function addLiquidity(uint256 _amount) public payable returns (uint256) {
        uint256 _liquidity; // LP tokens to mint

        // Get current ETH balance of THIS contract (includes the ETH user just sent)
        uint256 balanceInEth = address(this).balance;

        // Get current token balance of THIS contract
        uint256 tokenReserve = getTokensInContract();

        // Reference to the token contract for transfers
        ERC20Base _token = ERC20Base(token);

        // ============================================================
        // CASE 1: First time adding liquidity (empty pool)
        // ============================================================
        if (tokenReserve == 0) {
            // LP tokens = ETH sent (1:1 ratio for first deposit)
            _liquidity = balanceInEth;

            // Transfer tokens FROM user's wallet TO this contract
            _token.transferFrom(msg.sender, address(this), _amount);

            // Mint LP tokens TO the user (proof of their liquidity)
            _mint(msg.sender, _liquidity);
        }
        // ============================================================
        // CASE 2: Pool already has liquidity
        // ============================================================
        else {
            // Calculate ETH that was in pool BEFORE this transaction
            uint256 reserveEth = balanceInEth - msg.value;

            // --------------------------------------------------------
            // RATIO CHECK: Ensure user sends tokens in correct ratio
            // Formula: required tokens = (ETH sent × existing tokens) / existing ETH
            // This prevents price manipulation
            // --------------------------------------------------------
            require(
                _amount >= (msg.value * tokenReserve) / reserveEth,
                "Amount of tokens sent is less than the minimum required"
            );

            // Transfer tokens FROM user's wallet TO this contract
            _token.transferFrom(msg.sender, address(this), _amount);

            // Calculate LP tokens proportional to contribution
            // Formula: LP tokens = (total LP supply × ETH sent) / existing ETH
            unchecked {
                _liquidity = (totalSupply() * msg.value) / reserveEth;
            }

            // Mint LP tokens TO the user
            _mint(msg.sender, _liquidity);
        }

        return _liquidity;
    }
}
