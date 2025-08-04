// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract DexPair is ERC20, ReentrancyGuard {
    address public factory;
    address public tokenA;
    address public tokenB;
    uint256 public constant MINIMUM_LIQUIDITY = 1000;

    constructor() ERC20("DexPair LP", "DLP") {
        factory = msg.sender;
    }

    function initialize(address _tokenA, address _tokenB) external {
        require(msg.sender == factory, "DexPair: Forbidden");
        tokenA = _tokenA;
        tokenB = _tokenB;
    }
}
