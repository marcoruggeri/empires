// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Gold is ERC20, Ownable {
    address public gameDiamond;
    address public specialsAddress;

    constructor(address _gameDiamond, address _specialsAddress)
        ERC20("Gold", "GLD")
    {
        gameDiamond = _gameDiamond;
        specialsAddress = _specialsAddress;
    }

    function setAddresses(address _gameDiamond, address _specialsAddress)
        external
        onlyOwner
    {
        gameDiamond = _gameDiamond;
        specialsAddress = _specialsAddress;
    }

    function mint(address _account, uint256 _amount) external {
        require(msg.sender == gameDiamond, "Gold: only gameDiamond");
        _mint(_account, _amount);
    }

    function burnFrom(address _account, uint256 _amount) external {
        require(
            msg.sender == gameDiamond || msg.sender == specialsAddress,
            "Gold: only gameDiamond or specialsAddress"
        );
        _burn(_account, _amount);
    }
}
