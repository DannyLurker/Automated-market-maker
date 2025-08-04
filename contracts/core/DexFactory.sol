// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./DexPair.sol";

contract DexFactory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event CreatePair(address tokenA, address tokenB, address pair);

    function createPair(
        address _tokenA,
        address _tokenB
    ) external returns (address pair) {
        require(_tokenA != _tokenB, "Identical tokens not allowed");
        require(
            _tokenA != address(0) || _tokenB != address(0),
            "Zero address not allowed"
        );

        // Kalau pair nya itu ada yang zero address berarti masih belum ada, tapi kalau udah ada, dia tidak akan mengembalikan zero address yang dimana 0xff123.. == 0x0000: false, code akan langsung berhenti

        // Kalau 0x000.. == 0x000...: true, dia bakal lanjut eksekusi code yang di bawah

        require(getPair[_tokenA][_tokenB] == address(0), "Pair already exists");

        // Buat 1 pair contract baru
        //NOTE: Tidak perlu melakukan deklarasi type lagi dikarena sudah di tentukan name variablenya returns
        pair = address(new DexPair());

        //Initialize pair
        DexPair(pair).initialize(_tokenA, _tokenB);

        // Simpan ke mapping
        getPair[_tokenA][_tokenB] = pair;
        getPair[_tokenB][_tokenA] = pair;
        emit CreatePair(_tokenA, _tokenB, pair);

        // Simpan ke array
        allPairs.push(pair);

        return pair;
    }
}
