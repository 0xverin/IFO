// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IDayOfRightsClub {
    function mint(address _recipient) external;

    function dispatchHandle() external view returns (address);
}
