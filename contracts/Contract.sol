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

    /**
     * Remove liquidity from the pool
     * User burns their LP tokens and receives ETH + tokens back
     *
     * @param _amountLP - Number of LP tokens to burn
     * @return _amountInEth - ETH returned to user
     *
     * Example:
     *   Pool has: 10 ETH + 100,000 tokens, 10 LP tokens exist
     *   User has: 2 LP tokens (20% of pool)
     *   User burns 2 LP tokens → Gets 2 ETH + 20,000 tokens (20% of pool)
     */
    function removeLiquidity(uint256 _amountLP) public returns (uint256) {
        // Must burn at least some LP tokens
        require(
            _amountLP > 0,
            "Amount of liquidity to remove must be greater than 0"
        );

        // Get current reserves
        uint _reservedEth = address(this).balance; // ETH in pool
        uint _totalSupply = totalSupply(); // Total LP tokens in existence

        // --------------------------------------------------------
        // Calculate user's share of the pool
        // Formula: (pool reserves × LP tokens burned) / total LP supply
        // --------------------------------------------------------

        // ETH to return = (pool ETH × LP tokens) / total LP supply
        uint _amountInEth = (_reservedEth * _amountLP) / _totalSupply;

        // Tokens to return = (pool tokens × LP tokens) / total LP supply
        uint _amountInTokens = (getTokensInContract() * _amountLP) /
            _totalSupply;

        // Burn user's LP tokens (destroy them)
        _burn(msg.sender, _amountLP);

        // Send ETH back to user
        payable(msg.sender).transfer(_amountInEth);

        // Send tokens back to user
        ERC20Base(token).transfer(msg.sender, _amountInTokens);

        return _amountInEth;
    }

    /**
     * ============================================================
     * AMM PRICE FORMULA (Automated Market Maker)
     * ============================================================
     *
     * This uses the "Constant Product Formula": x * y = k
     * Where x = ETH reserve, y = token reserve, k = constant
     *
     * Formula: outputAmount = (inputAmount × outputReserve) / (inputReserve + inputAmount)
     *
     * Example:
     *   Pool: 10 ETH + 100,000 tokens
     *   User swaps 1 ETH
     *   Output = (1 × 100,000) / (10 + 1) = 100,000 / 11 = ~9,090 tokens
     *
     * Notice: User sends 1 ETH to contract and gets 9,090 tokens, not 10,000!
     * This is "slippage" - the price moves as you trade.
     * Bigger trades = more slippage = worse price.

     * This is just a simple supply and demand curve where:
     * When user buys a lot of tokens:
     * → Tokens become scarce in the pool
     * → Price goes up (supply & demand)
     *
     * When user sells a lot of tokens:
     * → Tokens become abundant in the pool
     * → Price goes down
     * ============================================================
     */
    function getAmountOfTokens(
        uint256 inputAmount, // Amount user is swapping (ETH or tokens)
        uint256 inputReserve, // Reserve of the input asset in pool
        uint256 outputReserve // Reserve of the output asset in pool
    ) public pure returns (uint256) {
        // Pool must have both assets
        require(inputReserve > 0 && outputReserve > 0, "Invalid Reserves");

        // Fee calculation (currently disabled - 0% fee)
        // To enable 1% fee: inputAmountWithFee = inputAmount * 99
        // This means only 99% of input counts toward the swap
        // uint256 inputAmountWithFee = inputAmount * 99;  // 1% fee
        uint256 inputAmountWithFee = inputAmount; // 0% fee (no fee)

        // --------------------------------------------------------
        // AMM Formula: output = (input × outputReserve) / (inputReserve + input)
        //
        // We multiply by 100 in denominator to handle the fee math
        // (when fee is enabled, input is multiplied by 99)
        // --------------------------------------------------------
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

        unchecked {
            return numerator / denominator;
        }
    }

    /**
     * Swap ETH → Tokens
     * User sends ETH, receives "67" tokens
     *
     * Example:
     *   Pool: 10 ETH + 100,000 tokens
     *   User sends 1 ETH
     *   User receives ~9,090 tokens (price impact/slippage)
     */
    function swapEthTotoken() public payable {
        // Get current token balance in pool
        uint256 _reservedTokens = getTokensInContract();

        // Calculate how many tokens user will receive
        // Note: address(this).balance already INCLUDES msg.value
        // So we need to subtract msg.value for the "before" state
        uint256 _tokensBought = getAmountOfTokens(
            msg.value, // ETH user is swapping
            address(this).balance - msg.value, // ETH reserve BEFORE swap
            _reservedTokens // Token reserve
        );

        // Send tokens to user
        ERC20Base(token).transfer(msg.sender, _tokensBought);
    }

    /**
     * Swap Tokens → ETH
     * User sends "67" tokens, receives ETH
     *
     * Example:
     *   Pool: 10 ETH + 100,000 tokens
     *   User sends 10,000 tokens
     *   User receives ~0.9 ETH (price impact/slippage)
     */
    function swapTokenToEth(uint256 _tokensSold) public {
        // Get current token balance in pool
        uint256 _reservedTokens = getTokensInContract();

        // Calculate how much ETH user will receive
        uint256 ethBought = getAmountOfTokens(
            _tokensSold, // Tokens user is swapping
            _reservedTokens, // Token reserve
            address(this).balance // ETH reserve
        );

        // Transfer tokens FROM user TO this contract
        ERC20Base(token).transferFrom(msg.sender, address(this), _tokensSold);

        // Send ETH to user
        payable(msg.sender).transfer(ethBought);
    }
}
