// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract DexPair is ERC20, ReentrancyGuard {
    address public factory;
    address public tokenA;
    address public tokenB;
    struct Reserves {
        uint112 reserveTokenA;
        uint112 reserveTokenB;
    }
    Reserves public reserves;
    uint256 public constant MINIMUM_LIQUIDITY = 1000;
    bool private _functionInitializedExcuted = false;

    event SyncBalances(uint112 _reserveTokenA, uint112 _reserveTokenB);
    event LiquidityAdded(
        address sender,
        uint256 amountTokenA,
        uint256 amountTokenB,
        uint256 liquidity
    );
    event WithdrawLiquidity(
        address user,
        uint256 liquidityToken,
        uint256 tokenA,
        uint256 tokenB
    );

    //NOTE: DLP token mewakilkan kepemilikan likuiditas di pool.
    //NOTE: Mengapa DLP token tidak menentukan totalSupply nya ? Karena supply DLP token itu hanya akan terbentuk jika ada likuiditas yang masuk.
    constructor() ERC20("DexPair LP", "DLP") {
        factory = msg.sender;
        reserves.reserveTokenA = 0;
        reserves.reserveTokenB = 0;
    }

    function initialize(address _tokenA, address _tokenB) external {
        require(
            !_functionInitializedExcuted,
            "This function can only be able called once."
        );
        require(msg.sender == factory, "DexPair: Forbidden");
        tokenA = _tokenA;
        tokenB = _tokenB;

        _functionInitializedExcuted = true;
    }

    function _update(uint256 balanceA, uint256 balanceB) private {
        reserves.reserveTokenA = uint112(balanceA);
        reserves.reserveTokenB = uint112(balanceB);

        emit SyncBalances(reserves.reserveTokenA, reserves.reserveTokenB);
    }

    function mintLiquidity(
        uint256 _amountTokenA,
        uint256 _amountTokenB
    ) external nonReentrant returns (uint256 liquidity) {
        require(_amountTokenA > 0 && _amountTokenB > 0, "Invalid amounts");

        if (totalSupply() == 0) {
            liquidity = Math.sqrt(_amountTokenA * _amountTokenB);
            require(liquidity > MINIMUM_LIQUIDITY, "Insufficient liquidity");
            liquidity = liquidity - MINIMUM_LIQUIDITY;
        } else {
            liquidity = Math.min(
                (_amountTokenA * totalSupply()) / reserves.reserveTokenA,
                (_amountTokenB * totalSupply()) / reserves.reserveTokenB
            );
        }

        require(liquidity > 0, "Insufficient liquidity minted");

        IERC20(tokenA).transferFrom(msg.sender, address(this), _amountTokenA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), _amountTokenB);

        if (totalSupply() == 0) {
            _mint(address(0), MINIMUM_LIQUIDITY);
        }

        _mint(msg.sender, liquidity);

        uint256 balanceTokenA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceTokenB = IERC20(tokenB).balanceOf(address(this));

        _update(balanceTokenA, balanceTokenB);
        emit LiquidityAdded(
            msg.sender,
            _amountTokenA,
            _amountTokenB,
            liquidity
        );
    }

    function withdraw(
        uint256 liquidityToken
    )
        external
        nonReentrant
        returns (uint256 _amountTokenA, uint256 _amountTokenB)
    {
        require(liquidityToken > 0, "Invalid liquidity token value");
        require(
            balanceOf(msg.sender) >= liquidityToken,
            "Insufficient LP token balance"
        );
        require(totalSupply() > 0, "No liquidity exists");

        uint256 balanceTokenA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceTokenB = IERC20(tokenB).balanceOf(address(this));

        _amountTokenA = (liquidityToken * balanceTokenA) / totalSupply();
        _amountTokenB = (liquidityToken * balanceTokenB) / totalSupply();

        require(
            _amountTokenA > 0 && _amountTokenB > 0,
            "Insufficient liquidity burned"
        );

        _burn(msg.sender, liquidityToken);

        IERC20(tokenA).transfer(msg.sender, _amountTokenA);
        IERC20(tokenB).transfer(msg.sender, _amountTokenB);

        uint256 newBalanceA = IERC20(tokenA).balanceOf(address(this));
        uint256 newBalanceB = IERC20(tokenB).balanceOf(address(this));
        _update(uint112(newBalanceA), uint112(newBalanceB));

        emit WithdrawLiquidity(
            msg.sender,
            liquidityToken,
            _amountTokenA,
            _amountTokenB
        );
    }
}
