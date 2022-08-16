// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IReferral {

    event SetReferrer(address account,address referrer);

    function setReferrer(address referrer) external;

    function referrers(address account) external view returns(address);

    function isPartner(address account) external view returns(bool);

    function addValidReferral(address account) external;
}
