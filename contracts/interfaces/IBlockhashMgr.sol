// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IBlockhashMgr {
    function request(uint256 blockNumber) external;

    function getBlockhash(uint256 blockNumber) external returns(bytes32);
}
