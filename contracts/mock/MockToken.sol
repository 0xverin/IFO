// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract MockToken is ERC20 {
    uint8 _decmails;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_) {
        _decmails = decimals_;
    }

    function mint(address to_, uint256 amount_) external {
        _mint(to_, amount_);
    }

    function decimals() public view override returns (uint8) {
        return _decmails;
    }
}
