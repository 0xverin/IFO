// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../core/SafeOwnable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IDayOfRightsClubPackage.sol";
import "../interfaces/IDORToken.sol";
import "../interfaces/IReferral.sol";

contract IFO is SafeOwnable {
    using SafeERC20 for IERC20;

    IDayOfRightsClubPackage public dayOfRightsClubPackage;
    
    IERC20 public USDTToken;
    IDORToken public DORToken;
    IReferral public referral;
    address public vault;
    bool public isAllowCollect;
    mapping(uint => uint) public packagePrice;
    mapping(uint => uint) public packageRewardToken;
    mapping(address => uint) public pendingReward;
    mapping(address => mapping(uint => bool)) public isOperated;

    event NewVault(address oldVault, address newVault);
    event Shop(address account, uint _type);
    event NewPackageReward(uint _type, uint reward);
    event NewPackagePrice(uint _type, uint price);
    event Collect(address account, uint reward);

    constructor(
        address _vault,
        address _USDTToken,
        address _DORToken,
        address _dayOfRightsClubPackage,
        address _referral
    ) {
        emit NewVault(vault, _vault);
        vault = _vault;

        packagePrice[1] = 28 * 10**18;
        packagePrice[2] = 58 * 10**18;
        packagePrice[3] = 88 * 10**18;

        packageRewardToken[1] = 28 * 10**18 * 100;
        packageRewardToken[2] = 58 * 10**18 * 100;
        packageRewardToken[3] = 88 * 10**18 * 100;

        USDTToken = IERC20(_USDTToken);
        DORToken = IDORToken(_DORToken);
        dayOfRightsClubPackage = IDayOfRightsClubPackage(
            _dayOfRightsClubPackage
        );
        referral = IReferral(_referral);
    }

    function allowCollectReward() external onlyOwner {
        isAllowCollect = true;
    }

    function prohibitCollectReward() external onlyOwner {
        isAllowCollect = false;
    }

    function setPackagePrice(uint _type, uint _price) external onlyOwner {
        packagePrice[_type] = _price;
        emit NewPackagePrice(_type, _price);
    }

    function setPackageRewardToken(uint _type, uint _reward)
        external
        onlyOwner
    {
        packageRewardToken[_type] = _reward;
        emit NewPackageReward(_type, _reward);
    }

    function setVault(address _vault) external onlyOwner {
        require(_vault != address(0), "vault cannot be zero address");
        emit NewVault(vault, _vault);
        vault = _vault;
    }

    function shop(uint _type) external {
        require(!isOperated[msg.sender][_type], "limit one purchase per type");
        require(packagePrice[_type] > 0, "no such type");
        isOperated[msg.sender][_type] = true;
        USDTToken.safeTransferFrom(msg.sender, vault, packagePrice[_type]);
        uint rewardToken = packageRewardToken[_type];
        pendingReward[msg.sender] = pendingReward[msg.sender] + rewardToken;
        dayOfRightsClubPackage.mint(msg.sender, _type);
        referral.addValidReferral(msg.sender);

        address referrer = referral.referrers(msg.sender);
        if (referral.isPartner(referrer)) {
            pendingReward[referrer] =
                pendingReward[referrer] +
                ((rewardToken * 10) / 100);
        }
        emit Shop(msg.sender, _type);
    }

    function collect() external {
        require(isAllowCollect, "Receive not yet developed");
        uint pending = pendingReward[msg.sender];
        DORToken.mint(msg.sender, pending);
        pendingReward[msg.sender] = 0;
        emit Collect(msg.sender, pending);
    }
}
