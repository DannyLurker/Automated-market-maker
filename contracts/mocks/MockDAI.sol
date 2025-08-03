// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract TokenArchitecture is ERC20, ERC20Pausable, AccessControl, ERC20Permit {
    // Role definitions
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    // Treasury untuk decentralization
    address public treasury;

    // Events
    event TreasuryUpdated(
        address indexed oldTreasury,
        address indexed newTreasury
    );
    event TokensMinted(
        address indexed to,
        uint256 amount,
        address indexed minter
    );
    event TokensBurned(
        address indexed from,
        uint256 amount,
        address indexed burner
    );
    event TokensDistributed(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    constructor(
        address _treasury
    ) ERC20("MockDai", "MDAI") ERC20Permit("MockDai") {
        require(_treasury != address(0), "Treasury cannot be zero address");
        treasury = _treasury;

        // Initial supply ke treasury untuk decentralization
        uint256 initialSupply = 100_000_000 * 10 ** decimals();
        _mint(treasury, initialSupply);

        // Setup roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Deployer sebagai admin
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(DISTRIBUTOR_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);

        // Grant distributor role ke treasury juga
        _grantRole(DISTRIBUTOR_ROLE, treasury);

        emit TokensMinted(treasury, initialSupply, msg.sender);
    }

    // ====================== Core Token Function ======================

    function mint(
        address to,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) whenNotPaused {
        require(to != address(0), "Can't mint to zero address");
        _mint(to, amount);
        emit TokensMinted(to, amount, msg.sender);
    }

    function burn(uint256 amount) external whenNotPaused {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount, msg.sender);
    }

    function burnForm(
        address from,
        uint256 amount
    ) external onlyRole(BURNER_ROLE) whenNotPaused {
        _spendAllowance(from, msg.sender, amount);
        _burn(from, amount);
        emit TokensBurned(from, amount, msg.sender);
    }

    // ============ DISTRIBUTION FUNCTIONS ============

    function distributeFromTreasury(
        address to,
        uint256 amount
    ) external onlyRole(DISTRIBUTOR_ROLE) whenNotPaused {
        require(
            balanceOf(treasury) >= amount,
            "Insuffiecient treasury balance"
        );

        _transfer(treasury, to, amount);
        emit TokensDistributed(treasury, to, amount);
    }

    function batchDistribute(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyRole(DISTRIBUTOR_ROLE) whenNotPaused {
        require(recipients.length == amounts.length, "Array length missmatch");
        require(recipients.length > 0, "Empty Array");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        require(
            balanceOf(treasury) > totalAmount,
            "Insuffiecient treasury balance"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] != address(0) && amounts[i] > 0) {
                _transfer(treasury, recipients[i], amounts[i]);
                emit TokensDistributed(treasury, recipients[i], amounts[i]);
            }
        }
    }

    // ============ PERMIT FUNCTIONS ============

    function permitAndTransfer(
        address owner,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external whenNotPaused {
        // Execute permit
        permit(owner, msg.sender, amount, deadline, v, r, s);

        // Execute transfer
        transferFrom(owner, to, amount);
    }

    function permitAndTransferFrom(
        address owner,
        address spender,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external whenNotPaused {
        // Execute permit
        permit(owner, spender, amount, deadline, v, r, s);

        // Execute transfer from spender
        require(msg.sender == spender, "Only approved spender can execute");
        transferFrom(owner, to, amount);
    }

    // ============ ADMIN FUNCTIONS ============

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function updateTreasury(
        address newTreasury
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newTreasury != address(0), "Treasury can't be zero address");
        address oldTreasury = treasury;
        treasury = newTreasury;

        _revokeRole(DISTRIBUTOR_ROLE, oldTreasury);
        _grantRole(DISTRIBUTOR_ROLE, treasury);

        emit TreasuryUpdated(oldTreasury, newTreasury);
    }

    // ============ OVERRIDE FUNCTIONS ============

    function transfer(
        address to,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        return super.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        return super.transferFrom(from, to, amount);
    }

    // The following functions are overrides required by Solidity.
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Pausable) whenNotPaused {
        //NOTE: Tidak perlu modifier tambahan ataupun require untuk membatasi akses karena sudah ada modifier internal
        super._update(from, to, value);
    }

    // ============ VIEW FUNCTIONS ============
    function getTreasuryBalance() external view returns (uint256) {
        return balanceOf(treasury);
    }

    function hasPermitSupport() external pure returns (bool) {
        return true;
    }

    // Check if address has specific role
    function hasRole(
        bytes32 role,
        address account
    ) public view override returns (bool) {
        return super.hasRole(role, account);
    }

    // Get all roles for debugging
    function getUserRoles(
        address account
    ) external view returns (bool[] memory) {
        bool[] memory roles = new bool[](5);
        roles[0] = hasRole(DEFAULT_ADMIN_ROLE, account);
        roles[1] = hasRole(MINTER_ROLE, account);
        roles[2] = hasRole(PAUSER_ROLE, account);
        roles[3] = hasRole(DISTRIBUTOR_ROLE, account);
        roles[4] = hasRole(BURNER_ROLE, account);
        return roles;
    }
}
