// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/MyToken.sol";
import "../src/interfaces/IUniFactory.sol";
import "../src/interfaces/IUniRouter.sol";

contract PoolTest is Test {

    address uniRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address uniFactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address pairAddress;
    address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address myToken;
    address wethWhale = 0xF04a5cC80B1E94C69B48f5ee68a08CD2F09A7c3E;
    

    function setUp() public {

        // save gas by storing storage variables as stack variable
        address _factory = uniFactoryAddress;
        address _router = uniRouterAddress;
        address _weth = weth;
        

        // Deploy MyToken.sol
        uint256 totalSupply = 1000000;
        address _mtk = address(new MyToken(totalSupply)); 

        // store MTK address in storage
        myToken = _mtk;

        // TEST: recieve mtk tokens
        assertEq(IERC20(_mtk).balanceOf(address(this)), totalSupply);


        // send weth to this contract
        vm.prank(wethWhale);
        IERC20(_weth).transfer(address(this), 100 ether);
        

        // Create MTK/WETH Liquidity Pool
        address _pairAddress = IUniFactory(_factory).createPair(_mtk, _weth);

        // casts pair address to uint256
        // checks if pair address is greater than 0
        // this verifies pair created by checking pair address != 0
        uint256 pairAddressUint;
        assembly {
            pairAddressUint := _pairAddress
        }
        
        // TEST: pair created
        assertGt( pairAddressUint, 0 );


        // stores stack variable to storage
        pairAddress = _pairAddress;
        

        // gest half of balance for both tokens
        uint256 wethLiquidity = IERC20(_weth).balanceOf(address(this)) / 2;
        uint256 mtkLiquidity = IERC20(_mtk).balanceOf(address(this)) / 2;

        // approve router to use tokens
        IERC20(_weth).approve(_router, wethLiquidity);
        IERC20(_mtk).approve(_router, mtkLiquidity); 

        // adds initial liquidity to pair (half of both balances)
        IUniRouter(_router).addLiquidity(
            address(_mtk),
            address(_weth),
            mtkLiquidity,
            wethLiquidity,
            mtkLiquidity,
            wethLiquidity,
            address(this),
            block.timestamp + 300 // 5 minutes
        );

        // TEST: liquidity added to pair
        assertEq( IERC20(_weth).balanceOf(_pairAddress), wethLiquidity );
        assertEq( IERC20(_mtk).balanceOf(_pairAddress), mtkLiquidity );

    }


    function testAddLiquidity(uint16 _prctAdd) public {

        // verify _prctAdd is valid bip above 1% and below 100%
        vm.assume(_prctAdd > 1000);
        vm.assume(_prctAdd <= 10000);


        // save gas by storing storage variables as stack variable
        address _weth = weth;
        address _mtk = myToken;
        address _router = uniRouterAddress;
        address _pairAddress = pairAddress;

        
        // uses random perentage of tokens to add liquidity
        uint256 amountInWeth = IERC20(_weth).balanceOf(address(this)) * _prctAdd / 10000;
        

        // get reserves of pair
        uint256 reserveWeth = IERC20(_weth).balanceOf(_pairAddress);
        uint256 reserveMtk = IERC20(_mtk).balanceOf(_pairAddress);

        // calculate amount of mtk token to add to keep pair price balanced
        uint256 amountInMtk = IUniRouter(_router).quote(amountInWeth, reserveWeth, reserveMtk);

        // approve router to use tokens
        IERC20(_weth).approve(uniRouterAddress, amountInWeth);
        IERC20(_mtk).approve(uniRouterAddress, amountInMtk); 

        // gives .01% margin for slipage
        uint256 minWeth = amountInWeth * 9999 / 10000;
        uint256 minMtk = amountInMtk * 9999 / 10000;


        // adds liquidity to pair
        (uint256 mtkAdded, uint256 wethAdded, ) = IUniRouter(_router).addLiquidity(
            _mtk,
            _weth,
            amountInMtk,
            amountInWeth,
            minMtk,
            minWeth,
            address(this),
            block.timestamp + 300 // 5 minutes
        );


        // TEST: proper amount of tokens depsoited
        uint256 maxDelta = 0.0001 ether;
        assertApproxEqRel(mtkAdded, amountInMtk, maxDelta);
        assertApproxEqRel(wethAdded, amountInWeth, maxDelta);

    }



    function testRemoveLiquidity(uint16 _prctOut) public {
        
        // verify _prctOut is valid bip above 1% and below 100%
        vm.assume(_prctOut > 1000);
        vm.assume(_prctOut <= 10000);

        
        // store storage variables as stack variables to save gas
        address _mtk = myToken;
        address _weth = weth;
        address _router = uniRouterAddress;
        address _pairAddress = pairAddress;


        // uses random perentage of LP tokens to remove liquidity
        uint256 liqToRemove = IERC20(_pairAddress).balanceOf(address(this)) * _prctOut / 10000;

        // gets corresponding amount of mtk and weth tokens
        uint256 mtkAmount = IERC20(_mtk).balanceOf(_pairAddress) * _prctOut / 10000;
        uint256 wethAmount = IERC20(_weth).balanceOf(_pairAddress) * _prctOut / 10000;


        // gives .01% margin for slipage
        uint256 minMtk = mtkAmount * 9999 / 10000;
        uint256 minWeth = wethAmount * 9999 / 10000;


        // aprove router to spend lp tokens
        IERC20(_pairAddress).approve(_router, liqToRemove);
        

        // remove liquidity from pair
        (uint256 mtkIn, uint256 wethIn) = IUniRouter(_router).removeLiquidity(
            _mtk,
            _weth, 
            liqToRemove, 
            minMtk, 
            minWeth, 
            address(this), 
            block.timestamp + 300
        );

        // TEST: proper amount of tokens removed
        uint256 maxDelta = 0.0001 ether;
        assertApproxEqRel(mtkAmount, mtkIn, maxDelta);
        assertApproxEqRel(wethAmount, wethIn, maxDelta);

    }


   
    function testSwap(bool _isMtk, uint16 _prctIn) public {

        // verify _prctIn is valid bip above 1% and below 100%
        vm.assume(_prctIn > 1000);
        vm.assume(_prctIn <= 10000);

        
        // store storage variables as stack variables to save gas
        address tokenIn;
        address tokenOut;
        address _router = uniRouterAddress;


        // checks which token we are swapping
        if (_isMtk == true) {
            tokenIn = myToken;
            tokenOut = weth;
        } else {
            tokenIn = weth;
            tokenOut = myToken;
           
        }

        // gets start balance for both tokens
        uint256 startBalanceTokenIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 startBalanceTokenOut = IERC20(tokenOut).balanceOf(address(this));


        // uses random perentage of tokens to trade
        uint256 _amountIn =  startBalanceTokenIn * _prctIn / 10000;

        
        // constructs memory array for swap
        address[] memory _path = new address[](2);
        _path[0] = tokenIn;
        _path[1] = tokenOut;

        // quotes min amount out for swap
        uint256[] memory prices = IUniRouter(_router).getAmountsOut(_amountIn, _path);

        // If we were not using fuzzing and wanted a realistic trade, add this line of code to prevent losing too much value on trade
        // require(_amountIn * 8500 / 10000 <= prices[1], "SWAP: Trade slippage above 15%");
        
        // approve router to swap tokens
        IERC20(tokenIn).approve(_router, _amountIn);

        // executes swap
        uint256[] memory tradeVals = IUniRouter(_router).swapExactTokensForTokens(_amountIn, prices[1], _path, address(this), block.timestamp + 300);

        // get end balances for tokens
        uint256 endBalanceTokenIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 endBalanceTokenOut = IERC20(tokenOut).balanceOf(address(this));

        // TEST: expected swap amount
        assertGe( tradeVals[1], prices[1] );
        assertEq( tradeVals[0], _amountIn );
        assertEq(endBalanceTokenIn , startBalanceTokenIn - tradeVals[0] );
        assertEq(endBalanceTokenOut , startBalanceTokenOut + tradeVals[1] );
        
    }

}
