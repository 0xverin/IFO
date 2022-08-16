// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDORToken is IERC20 {
    function mint(address _recipient, uint _value) external;
}
