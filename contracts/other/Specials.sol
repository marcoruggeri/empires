// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "../interfaces/IERC20.sol";

contract Specials is ERC1155, Ownable {
    address public gameDiamond;
    address public goldAddress;
    // id => price
    mapping(uint256 => uint256) public prices;

    constructor(address _gameDiamond, address _goldAddress) ERC1155("") {
        gameDiamond = _gameDiamond;
        goldAddress = _goldAddress;
    }

    function mint(uint256 _id, uint256 _amount) external {
        IERC20 gold = IERC20(goldAddress);
        gold.burnFrom(msg.sender, prices[_id] * _amount);
        _mint(msg.sender, _id, _amount, "");
    }

    function burnFrom(address _account, uint256 _id) external {
        require(msg.sender == gameDiamond, "Specials: only gameDiamond");
        _burn(_account, _id, 1);
    }

    function addSpecial(uint256 _id, uint256 _price) external onlyOwner {
        prices[_id] = _price;
    }
}
