// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TokenArchitecture is
    ERC20,
    ERC20Pausable,
    AccessControl,
    ERC20Permit,
    Ownable
{
    //Deklarasi ERC20: Membuat token dengan nama "MockUSDT" dan inisial "MSD"

    //Deklarasi ERC20Permit: Tujuan dari ERC20Permit("Danny Token") di constructor adalah untuk menyetel nama token ke dalam DOMAIN_SEPARATOR, agar tanda tangan permit() hanya valid untuk kontrak dan chain tertentu, mencegah penyalahgunaan (replay attack), memastikan tanda tangan dapat diverifikasi dengan benar, serta dengan permit kita bisa mengizinkan orang lain memakai token kita tanpa harus menggunakan approve lalu transferform, jadinya hanya 1 transaksi saja

    // Untuk awal awal kita bisa gunakan sistem intialOwner dan ketika contract sudah stabil baru kita renounce atau pun serahkan ke contract sepenuhnya

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(
        address initialOwner
    ) ERC20("MockUSDT", "MSD") ERC20Permit("MockUSDT") Ownable(initialOwner) {
        uint256 totalSupply = 100_000_000 * 10 ** decimals();
        _mint(address(this), totalSupply);
        _grantRole(MINTER_ROLE, initialOwner);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // The following functions are overrides required by Solidity.
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }
}
