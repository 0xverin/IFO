// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../core/SafeOwnable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IDayOfRightsClubPackage.sol";
import "../interfaces/IDORToken.sol";
import "../interfaces/IReferral.sol";
import "hardhat/console.sol";

contract IFO is SafeOwnable {
    using SafeERC20 for IERC20;

    IDayOfRightsClubPackage public dayOfRightsClubPackage;

    IERC20 public USDTToken;
    IDORToken public DORToken;
    IReferral public referral;
    address public vault;
    bool public isAllowCollect;
    mapping(uint256 => uint256) public packagePrice;
    mapping(uint256 => uint256) public packageRewardToken;
    mapping(address => uint256) public pendingReward;
    mapping(address => mapping(uint256 => bool)) public isOperated;

    event NewVault(address oldVault, address newVault);
    event Shop(address account, uint256 _type);
    event NewPackageReward(uint256 _type, uint256 reward);
    event NewPackagePrice(uint256 _type, uint256 price);
    event Collect(address account, uint256 reward);

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

    function setPackagePrice(uint256 _type, uint256 _price) external onlyOwner {
        packagePrice[_type] = _price;
        emit NewPackagePrice(_type, _price);
    }

    function setPackageRewardToken(uint256 _type, uint256 _reward)
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

    function shop(uint256 _type) external {
        require(!isOperated[msg.sender][_type], "limit one purchase per type");
        require(packagePrice[_type] > 0, "no such type");
        isOperated[msg.sender][_type] = true;
        USDTToken.safeTransferFrom(msg.sender, vault, packagePrice[_type]);
        uint256 rewardToken = packageRewardToken[_type];

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
        uint256 pending = pendingReward[msg.sender];
        DORToken.mint(msg.sender, pending);
        pendingReward[msg.sender] = 0;
        emit Collect(msg.sender, pending);
    }
}
