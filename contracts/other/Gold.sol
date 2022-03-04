// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Gold is ERC20, Ownable {
    address public gameDiamond;

    constructor(address _gameDiamond) ERC20("Gold", "GLD") {
        gameDiamond = _gameDiamond;
    }

    function setGameDiamond(address _gameDiamond) external onlyOwner {
        gameDiamond = _gameDiamond;
    }

    function mint(address _account, uint256 _amount) external {
        require(msg.sender == gameDiamond, "Gold: only gameDiamond");
        _mint(_account, _amount);
    }

    function burnFrom(address _account, uint256 _amount) external {
        require(msg.sender == gameDiamond, "Gold: only gameDiamond");
        _burn(_account, _amount);
    }
}
