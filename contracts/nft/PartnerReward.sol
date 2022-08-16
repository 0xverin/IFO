// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "../interfaces/IReferral.sol";
import "../interfaces/IDORToken.sol";
import "../interfaces/IReferral.sol";
import "hardhat/console.sol";

contract PartnerReward {
    mapping(address => bool) public isCliamed;
    IDORToken public dorToken;
    IReferral public referralHandler;

    constructor(IReferral _referralHandler, IDORToken _dorToken) {
        referralHandler = _referralHandler;
        dorToken = _dorToken;
    }

    function cliam() external {
        require(!isCliamed[msg.sender], "received");
        isCliamed[msg.sender] = true;
        dorToken.mint(msg.sender, 28800 * 1e18);
        address referrer = referralHandler.referrers(msg.sender);
        if (referrer != address(0) && referralHandler.isPartner(referrer)) {
            dorToken.mint(referrer, 2880 * 1e18);
        }
    }
}