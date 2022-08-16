// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../core/SafeOwnable.sol";
import "../interfaces/IReferral.sol";
import "../interfaces/IDORToken.sol";
import "../interfaces/IDayOfRightsClubPackage.sol";
import "../interfaces/IDayOfRightsClub.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

abstract contract Referral is IReferral {
    
    mapping(address => address) internal _referrers;
    mapping(address => address[]) internal _recommended;

    function setReferrer(address _referrer) public virtual override {
        require(_referrers[msg.sender] == address(0), "repeat operation");
        require(
            _referrers[_referrer] != address(0),
            "referrer does not have permission"
        );
        _referrers[msg.sender] = _referrer;
        _recommended[_referrer].push(msg.sender);
        emit SetReferrer(msg.sender, _referrer);
    }

    function referrers(address account)
        external
        view
        virtual
        override
        returns (address)
    {
        return _referrers[account];
    }

    function recommended(
        address account,
        uint256 page,
        uint256 size
    ) public view returns (uint256, address[] memory) {
        uint256 len = size;
        if (page * size + size > _recommended[account].length) {
            len = _recommended[account].length % size;
        }
        if (page > _recommended[account].length / size) {
            len = 0;
        }
        address[] memory _fans = new address[](len);
        uint256 startIdx = page * size;
        for (uint256 i = 0; i != size; i++) {
            if (startIdx + i >= _recommended[account].length) {
                break;
            }
            _fans[i] = _recommended[account][startIdx + i];
        }
        return (_recommended[account].length, _fans);
    }
}

contract DayOfRightsReferral is Referral, SafeOwnable {
    using SafeERC20 for IERC20;
    uint public bindReward;
    IERC20 public USDTToken;
    IDORToken public DORToken;
    IDayOfRightsClubPackage public dayOfRightsClubPackage;
    IDayOfRightsClub public dayOfRightsClub;
    address public vault;
    uint public stakeAmount = 288 * 10**18;
    mapping(address => bool) public isCaller;
    mapping(address => uint) public validReferral;
    mapping(address => bool) public isValidUser;
    mapping(address => bool) public isPartnerReward;
    mapping(address => bool) public _isPartner;

    event NewVault(address oldVault, address newVault);
    event UpgradePartner(address account);

    constructor(
        address _dayOfRightsClub,
        address _dayOfRightsClubPackage,
        address _vault,
        address _usdtToken,
        address _dorToken
    ) {
        dayOfRightsClub = IDayOfRightsClub(_dayOfRightsClub);
        dayOfRightsClubPackage = IDayOfRightsClubPackage(
            _dayOfRightsClubPackage
        );
        _referrers[msg.sender] = address(this);
        _recommended[address(this)].push(msg.sender);
        emit SetReferrer(msg.sender, address(this));

        bindReward = 10 * 10**18;
        emit NewVault(vault, _vault);
        vault = _vault;
        USDTToken = IERC20(_usdtToken);
        DORToken = IDORToken(_dorToken);
    }

    function isPartner(address account) public view override returns (bool) {
        return _isPartner[account];
    }

    function setVault(address _vault) external onlyOwner {
        require(_vault != address(0), "vault cannot be zero address");
        emit NewVault(vault, _vault);
        vault = _vault;
    }

    function setBindReward(uint _reward) external onlyOwner {
        bindReward = _reward;
    }

    function setStakeAmount(uint _stakeAmount) external onlyOwner {
        stakeAmount = _stakeAmount;
    }

    function setReferrer(address _referrer) public override {
        super.setReferrer(_referrer);
        if (bindReward > 0) {
            DORToken.mint(msg.sender, bindReward);
        }
    }

    function addValidReferral(address account) external override onlyCaller {
        if (!isValidUser[account]) {
            isValidUser[account] = true;
            address referrer = _referrers[account];
            if (referrer != address(0)) {
                validReferral[referrer] += 1;

                partnerReward(referrer);
            }
        }
    }

    function partnerStake() external {
        require(!_isPartner[msg.sender], "caller is partner");
        USDTToken.safeTransferFrom(msg.sender, vault, stakeAmount);
        _isPartner[msg.sender] = true;
        address referrer = _referrers[msg.sender];
        if (referrer != address(0) && _isPartner[referrer]) {
            dayOfRightsClubPackage.mint(referrer, 4);
        }
        emit UpgradePartner(msg.sender);

        partnerReward(msg.sender);
    }

    function partnerReward(address account) internal {
        if (
            _isPartner[account] &&
            validReferral[account] >= 10 &&
            !isPartnerReward[account]
        ) {
            isPartnerReward[account] = true;

            dayOfRightsClub.mint(account);
            dayOfRightsClubPackage.mint(account, 4);
        }
    }

    function setCaller(address _account, bool _enable) external onlyOwner {
        isCaller[_account] = _enable;
    }

    modifier onlyCaller() {
        require(isCaller[msg.sender], "only caller can do this action");
        _;
    }
}
