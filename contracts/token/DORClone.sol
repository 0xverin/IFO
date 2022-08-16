// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../core/SafeOwnable.sol";
import "../nft/PartnerReward.sol";
import "../interfaces/IDORToken.sol";
import "../referral/DayOfRightsReferral.sol";
import "hardhat/console.sol";

contract DORClone is SafeOwnable {
    IDORToken public oldDOR;
    IDORToken public newDOR;
    PartnerReward public partnerReward;
    DayOfRightsReferral public referralHandler;
    mapping(address => bool) public isClone;

    constructor(
        IDORToken _oldDOR,
        IDORToken _newDOR,
        PartnerReward _partnerReward,
        DayOfRightsReferral _referralHandler
    ) {
        oldDOR = _oldDOR;
        newDOR = _newDOR;
        partnerReward = _partnerReward;
        referralHandler = _referralHandler;
    }

    event Clone(address indexed account, uint256 indexed amount);

    function dorClone() external {
        uint256 amount = dorAmount(msg.sender);
        isClone[msg.sender] = true;
        if (amount > 0) {
            newDOR.mint(msg.sender, amount);
            emit Clone(msg.sender, amount);
        }
    }

    function dorAmount(address account) public view returns (uint256) {
        if (isClone[account]) {
            return 0;
        }
        uint256 amount = oldDOR.balanceOf(account);
        bool isCliamed = partnerReward.isCliamed(account);
        bool isPartner = referralHandler.isPartner(account);
        if (isCliamed && !isPartner) {
            return 0;
        } else {
            (, address[] memory addrs) = referralHandler.recommended(
                account,
                0,
                200
            );
            for (uint256 i = 0; i != addrs.length; i++) {
                isCliamed = partnerReward.isCliamed(addrs[i]);
                isPartner = referralHandler.isPartner(addrs[i]);
                if (isCliamed && !isPartner) {
                    if (amount > 2880 * 10**18) {
                        amount -= 2880 * 10**18;
                    }
                }
            }
            return amount;
        }
    }
}
