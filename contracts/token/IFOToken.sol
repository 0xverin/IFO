// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IDayOfRightsClub.sol";
import "../interfaces/IReferral.sol";
import "../interfaces/IFactory.sol";
import "../interfaces/IRouter.sol";
import "hardhat/console.sol";

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract SmartVault {
    IERC20 public usdtToken;
    IERC20 public dorToken;

    function initialize(IERC20 _usdtToken, IERC20 _dorToken) external {
        require(address(usdtToken) == address(0), "has been initialized");
        usdtToken = _usdtToken;
        dorToken = _dorToken;

        usdtToken.approve(address(dorToken), uint256(-1));
    }

    function approve() external {
        usdtToken.approve(address(dorToken), uint256(-1));
    }
}

contract IFOToken is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint256 public constant BASE_RATIO = 10**18;
    uint256 public immutable rewardEndTime;
    mapping(address => bool) private minner;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public rewardBlacklist;
    uint256 public nftPoolFeePercent = (2 * BASE_RATIO) / 100;

    IERC20 public usdtToken;
    address public nftPool;
    address public liquidity;
    bool public canTransfer;

    event AddWhitelist(address account);
    event DelWhitelist(address account);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _usdtToken,
        IFactory _factory
    ) ERC20(_name, _symbol) {
        _setupDecimals(_decimals);
        usdtToken = IERC20(_usdtToken);
        liquidity = _factory.createPair(_usdtToken, address(this));
        rewardEndTime = block.timestamp.add(730 days);
        setRewardBlacklist(liquidity, true);
        setRewardBlacklist(address(this), true);
    }

    function setNFTPoolFeePercent(uint256 percent) external onlyOwner {
        nftPoolFeePercent = percent;
    }

    function setMinner(address _minner, bool enable) external onlyOwner {
        minner[_minner] = enable;
    }

    function isMinner(address account) public view returns (bool) {
        return minner[account];
    }

    modifier onlyMinner() {
        require(isMinner(msg.sender), "caller is not minter");
        _;
    }

    function setNFTPool(address _nftPool) external onlyOwner {
        nftPool = _nftPool;
    }

    function addWhitelist(address _addr) external onlyOwner {
        whitelist[_addr] = true;
        emit AddWhitelist(_addr);
    }

    function delWhitelist(address _addr) external onlyOwner {
        delete whitelist[_addr];
        emit DelWhitelist(_addr);
    }

    function mint(address to, uint256 value) external onlyMinner {
        _mint(to, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (!whitelist[from] && !whitelist[to]) {
            amount = calculateFee(from, amount);
        }
        super._transfer(from, to, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(
            canTransfer || whitelist[sender] || whitelist[recipient],
            "can not transfer"
        );

        return super.transferFrom(sender, recipient, amount);
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        require(
            canTransfer || whitelist[recipient] || whitelist[_msgSender()],
            "can not transfer"
        );
        return super.transfer(recipient, amount);
    }

    function calculateFee(address from, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 realAmount = amount;
        address account = from;
        uint256 nftFee = amount.mul(nftPoolFeePercent).div(BASE_RATIO);
        if (nftPool != address(0) && nftFee > 0) {
            realAmount = realAmount.sub(nftFee);
            super._transfer(account, nftPool, nftFee);
        }

        return realAmount;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function setCanTransfer(bool enable) external onlyOwner {
        canTransfer = enable;
    }

    function setRewardBlacklist(address account, bool enable) public onlyOwner {
        rewardBlacklist[account] = enable;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {}
}
