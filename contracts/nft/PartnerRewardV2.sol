// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "../interfaces/IReferral.sol";
import "../interfaces/IDORToken.sol";
import "hardhat/console.sol";

interface IPartnerReward {
    function isCliamed(address account) external view returns (bool);
}

contract PartnerRewardV2 {
    mapping(address => bool) private _isCliamed;
    IDORToken public dorToken;
    IReferral public referralHandler;
    IPartnerReward private oldPartnerReward;

    constructor(
        IReferral _referralHandler,
        IDORToken _dorToken,
        IPartnerReward _oldPartnerReward
    ) {
        referralHandler = _referralHandler;
        dorToken = _dorToken;
        oldPartnerReward = _oldPartnerReward;
    }

    function cliam() external {
        require(!isCliamed(msg.sender), "received");
        require(referralHandler.isPartner(msg.sender), "only partenr");
        _isCliamed[msg.sender] = true;
        dorToken.mint(msg.sender, 28800 * 1e18);
        address referrer = referralHandler.referrers(msg.sender);
        if (referrer != address(0) && referralHandler.isPartner(referrer)) {
            dorToken.mint(referrer, 2880 * 1e18);
        }
    }

    function isCliamed(address account) public view returns (bool) {
        return oldPartnerReward.isCliamed(account) || _isCliamed[account];
    }
}
