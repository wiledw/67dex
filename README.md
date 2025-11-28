# 67 DEX

In this project, I created my own Token, DEXLiquidity Pool. 
<img width="868" height="198" alt="step1" src="https://github.com/user-attachments/assets/2b1d305d-9a05-42bf-99ff-3a81f11b2403" />
<img width="1236" height="210" alt="image" src="https://github.com/user-attachments/assets/e958ee35-e2cc-4e7a-bbdb-afce07fd6388" />

Warning: This code is not audited. Use at your own risk.\

A decentralized exchange (DEX) smart contract built on Ethereum using Solidity.

---

## Overview

This DEX allows users to:

- **Swap ETH ↔ Tokens** — Trade ETH for tokens and vice versa
- **Add Liquidity** — Provide ETH + tokens to the pool and earn LP tokens
- **Remove Liquidity** — Burn LP tokens to withdraw your share of the pool

### How It Works

The DEX uses an **Automated Market Maker (AMM)** with the constant product formula:

```
x × y = k

x = ETH reserve
y = Token reserve
k = constant (stays the same)
```

---

## Contract Functions

| Function | Description |
|----------|-------------|
| `addLiquidity()` | Add ETH + tokens to the pool, receive LP tokens |
| `removeLiquidity()` | Burn LP tokens, receive ETH + tokens back |
| `swapEthToToken()` | Swap ETH for tokens |
| `swapTokenToEth()` | Swap tokens for ETH |
| `getAmountOfTokens()` | Calculate output amount for a swap |
| `getTokensInContract()` | Get token balance in the pool |

---

## Getting Started

### Prerequisites

- Node.js (v16+)
- Yarn or npm

### Installation

```bash
# Install dependencies
yarn install
# or
npm install
```

### Build

Compile the contract:

```bash
npx thirdweb build
```

### Deploy

Deploy the contract to any EVM chain:

```bash
npx thirdweb deploy
```

This will open a browser where you can select the network and configure deployment.

---

## Full Tutorial: Create Token → Deploy DEX → Add Liquidity

### Step 1: Create Your Token on Thirdweb

1. Go to [thirdweb.com/explore](https://thirdweb.com/explore)
2. Search for **"Token"** or **"TokenERC20"**
3. Click **Deploy Now**
4. Fill in the details:
   - **Name**: Your token name (e.g., "67")
   - **Symbol**: Token symbol (e.g., "67")
   - **Admin**: Your wallet address
5. Select your network (e.g., Ethereum, zkSync)
6. Click **Deploy** and confirm in MetaMask
7. **Save your token contract address!** (e.g., `0x1234...abcd`)

### Step 2: Mint Tokens to Your Wallet

1. Go to your token contract on thirdweb dashboard
2. Click **"Tokens"** in the sidebar
3. Click **"+ Mint"**
4. Enter the amount (e.g., `1000000` for 1 million tokens)
5. Click **Mint** and confirm in MetaMask
6. You now have tokens in your wallet!

### Step 3: Deploy the DEX Contract

1. In your project folder, run:

```bash
npx thirdweb build
npx thirdweb deploy
```

2. A browser window opens. Fill in the constructor parameters:
   - **_token**: Your token contract address from Step 1 (e.g., `0x1234...abcd`)
   - **_defaultAdmin**: Your wallet address
   - **_name**: LP token name (e.g., "67 DEX LP")
   - **_symbol**: LP token symbol (e.g., "67LP")

3. Select your network (same as your token!)
4. Click **Deploy** and confirm in MetaMask
5. **Save your DEX contract address!** (e.g., `0xDEX...5678`)

### Step 4: Approve DEX to Spend Your Tokens

Before adding liquidity, you must allow the DEX to transfer your tokens.

1. Go to your **TOKEN contract** on thirdweb dashboard
2. Click **"Write"** tab
3. Find **`approve`** function
4. Enter:
   - **spender**: Your DEX contract address (from Step 3)
   - **amount**: `1000000000000000000000000` (1 million tokens with 18 decimals)
5. Click **Execute** and confirm in MetaMask

### Step 5: Add Liquidity to the DEX

Now add your tokens + ETH to create the liquidity pool.

1. Go to your **DEX contract** on thirdweb dashboard
2. Click **"Write"** tab
3. Find **`addLiquidity`** function
4. Enter:
   - **Amount**: Number of tokens (with 18 decimals)
     - Example: `100000000000000000000000` = 100,000 tokens
   - **Native Token Value**: ETH to add
     - Example: `0.1` = 0.1 ETH
5. Click **Execute** and confirm in MetaMask

### Step 6: Verify It Worked

1. Go to your DEX contract → **"Read"** tab
2. Call **`balanceOf`** with your wallet address
   - Should show your LP tokens (not 0!)
3. Call **`getTokensInContract`**
   - Should show tokens in the pool
4. Check the contract's ETH balance on block explorer

### Summary

```
Step 1: Create token on thirdweb           → Get TOKEN_ADDRESS
Step 2: Mint tokens to your wallet         → You have tokens
Step 3: Deploy DEX with npx thirdweb deploy → Get DEX_ADDRESS
Step 4: Approve DEX to spend tokens        → TOKEN.approve(DEX_ADDRESS, amount)
Step 5: Add liquidity                      → DEX.addLiquidity(tokens) + send ETH
Step 6: Verify LP balance > 0              → Success!
```

### Common Mistakes

| Problem | Solution |
|---------|----------|
| LP balance is 0 | You didn't send ETH (Native Token Value was 0) |
| Transaction failed | You didn't approve the DEX first |
| Wrong network | Make sure token and DEX are on the same network |
| Not enough gas | Get more ETH for gas fees |

---

## Project Structure

```
dexcontract/
├── contracts/
│   └── Contract.sol    # Main DEX contract
├── scripts/
│   └── verify/         # Verification scripts
├── hardhat.config.js   # Hardhat configuration
└── package.json
```

---

## Key Concepts

### LP Tokens
When you add liquidity, you receive LP (Liquidity Provider) tokens. These represent your share of the pool.

### Slippage
Larger trades have more price impact. The AMM formula ensures prices adjust based on supply and demand.

### Reserves
The pool holds both ETH and tokens. The ratio between them determines the price.

---
