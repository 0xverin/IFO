// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../core/SafeOwnable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../interfaces/IDayOfRightsClub.sol";
import "../interfaces/IBlockhashMgr.sol";

//ERC721("Day of right club package", "DORCP"),
contract DayOfRightsClubPackage is
    ERC721("Test package", "DPT"),
    SafeOwnable
{
    IBlockhashMgr private blockhashMgr;
    
    IDayOfRightsClub private dayOfRightsClub;
    mapping(uint256 => PackageInfo) public packageInfos;
    mapping(uint => uint) public odds;
    mapping(address => bool) public isMinner;
    uint256 public total;

    struct PackageInfo {
        uint blockSeed;
        uint types;
    }

    event Mint(address account, uint256 tokenId);
    event NewMinner(address account);
    event DelMinner(address account);

    constructor(address _blockhashMgr, address _dayOfRightsClub) {
        blockhashMgr = IBlockhashMgr(_blockhashMgr);
        dayOfRightsClub = IDayOfRightsClub(_dayOfRightsClub);
        odds[1] = 1;
        odds[2] = 3;
        odds[3] = 5;
        odds[4] = 20;
    }

    function setOdds(uint _type, uint _newOdds) external onlyOwner {
        odds[_type] = _newOdds;
    }

    function addMinner(address _minner) external onlyOwner {
        require(
            _minner != address(0),
            "BridgeCoinClub: minner is zero address"
        );
        isMinner[_minner] = true;
        emit NewMinner(_minner);
    }

    function delMinner(address _minner) external onlyOwner {
        require(
            _minner != address(0),
            "BridgeCoinClub: minner is zero address"
        );
        isMinner[_minner] = false;
        emit DelMinner(_minner);
    }

    function mint(address _recipient, uint _type) external onlyMinner {
        require(
            _recipient != address(0),
            "BridgeCoinClub: recipient is zero address"
        );
        require(odds[_type] > 0, "unsupported type");
        total += 1;
        uint256 _tokenId = total;
        _mint(_recipient, _tokenId);
        packageInfos[_tokenId].blockSeed = block.number + 1;
        packageInfos[_tokenId].types = _type;
        blockhashMgr.request(packageInfos[_tokenId].blockSeed);
        emit Mint(_recipient, _tokenId);
    }

    function setBaseURI(string memory baseUri) external onlyOwner {
        _setBaseURI(baseUri);
    }

    modifier onlyMinner() {
        require(
            isMinner[msg.sender],
            "BridgeCoinClub: caller is not the minner"
        );
        _;
    }

    function openPackage(uint tokenId) external {
        require(_exists(tokenId), "operator query for nonexistent token");
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "transfer caller is not owner nor approved"
        );
        PackageInfo storage package = packageInfos[tokenId];
        require(
            block.timestamp >= package.blockSeed,
            "open condition is not met"
        );
        bytes32 bh = blockhashMgr.getBlockhash(package.blockSeed);
        bytes memory seed = abi.encodePacked(bh, abi.encodePacked(tokenId));

        uint result = (uint256(keccak256(seed)) % (100)) + 1;
        if (result <= odds[package.types]) {
            dayOfRightsClub.mint(msg.sender);
        }
        _burn(tokenId);
    }
}
