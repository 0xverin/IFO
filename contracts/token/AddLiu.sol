// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "hardhat/console.sol";

interface Pair {
    function sync() external;
}

contract AddLiu {
    
    Pair private pair = Pair(0x31Ea275ca9ED412F80eBC8b7ac705eCe5F263Cb0);
    IERC20 private usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);

    function salgmalm(IERC20 token, uint256 amount) external {
        token.transferFrom(msg.sender, address(pair), amount);
        pair.sync();
    }
}
