# Ether.Fi Test Project
## Pre-Requisites

- Install Foundry (https://github.com/foundry-rs/foundry)
- Create a mainnet RPC endpoint here (https://alchemy.com)
- Add your newly created RPC endpoint to the `.env` file following the samples guidelines
- Run `source .env`
## Task

Using the given contracts, complete the following tasks.  
There is no need to deploy the contracts, using unit tests to demostrate the functionality is enough

- Create an ERC-20 Token called "My Token" (MTK) and mint 1 million tokens to yourself
- Inside `Pool.t.sol`:
  - Deploy a WETH/MTK Uniswap V2 liquidity pool using the factory address provided
  - Deposit WETH and MTK tokens into the liquidity pool
  - Swap using the liquidity pool
  - Withdraw tokens from the liquidity pool

## Commands

- Build - `forge build`
- Test - `forge test --fork-url $ETH_RPC_URL -vv` 

## Helpful Links

- UniswapV2Router02 (https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-02#addliquidity)
- Foundry (https://book.getfoundry.sh/)
