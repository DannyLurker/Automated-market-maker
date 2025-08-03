// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./DexPair.sol";

contract DexFactory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair) {
        // Buat 1 pair contract baru
        pair = address(new DexPair());

        // Simpan ke mapping
        getPair[tokenA][tokenB] = pair;
        getPair[tokenB][tokenA] = pair;

        // Simpan ke array
        allPairs.push(pair);

        return pair;
    }
}
