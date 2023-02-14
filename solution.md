# MyToken.sol
```MyToken``` inherits the ERC20 token standard using OpenZeppelin's base contract. The token's name is set to ```My Token``` and its symbol is set as ```MTK```. Inside the constructor of the contract, 1,000,000 tokens are sent to the deploying address of the contract. 

# PoolTest.t.sol
This contract deploys ```MyToken```. With the tokens received from deployment, ```PoolTest``` creates a liquidity pool on UniswapV2. After creating the pair, ```PoolTest``` adds, removes, and swaps tokens in the liquidity pool.

## PoolTest.setUp()
This function gets called prior to the rest of the test functions. Inside this function, we deploy the ```MyToken``` contract. After checking that the contract was deployed properly, we then use ```vm.prank``` to give our contract weth. After, we create a liquidity pool with ```MTK/WETH```. Finally, we deposit ou initial liquidity in the pair.

## PoolTest.testAddLiquidity()
 This function tests adding a random amount of liquidity to the pool, by taking advantage of foundry’s fuzzing. We use ```_prctIn``` to represent a percentage in basis points. After we decide to take a random percentage of ```weth``` as liquidity, we need to find the corresponding amount of ```mtk``` tokens. To accomplish this, we get the reserves of the pool and call the router’s ```quote()``` function. Then we calculate 99.99% of our values as our minimum acceptable deposit amount, and deposit our tokens into the pool.

## PoolTest.testRemoveLiquidity()
Similarly to our last function, we take advantage of fuzzing to give us a random percent of liquidity to withdraw. We first make our calculation for the ```lp tokens```, then we make the same calculation with ```weth``` and ```mtk```. We specify that the minimum withdrawal amount is 99.99% of our calculation before withdrawing.


## PoolTest.testSwap()
For our swap, we use fuzzing to determine a boolean representing which token we will be swapping. In addition we use fuzzing to get a random percent of that token's balance that will be swapped. After determining which token we will be swapping, we calculate the amount of tokens we plan on swapping. Next we construct a memory array that we pass as a parameter to ```getAmountOuts()```. This gives us an expected amount that we should receive for our swap. Finally, we can execute our swap.
