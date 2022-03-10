// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {AppStorage, Modifiers, Tile} from "../libraries/AppStorage.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IERC1155} from "../interfaces/IERC1155.sol";
import "../libraries/LibCore.sol";

import "hardhat/console.sol";

contract SpecialsFacet is Modifiers {
    event LongRange(
        uint256[2] _from,
        uint256[2] _to,
        uint256 _attackUnits,
        uint256 _defendUnits
    );

    function longRange(
        uint256[2] calldata _from,
        uint256[2] calldata _to,
        uint256 _amount
    ) external {
        require(
            s.map[_from[0]][_from[1]].account == msg.sender,
            "CoreFacet: not owner"
        );
        require(
            s.map[_from[0]][_from[1]].units > _amount,
            "CoreFacet: high units"
        );
        IERC1155 specials = IERC1155(s.specialsAddress);
        specials.burnFrom(msg.sender, 0);
        IERC20 stamina = IERC20(s.staminaAddress);
        stamina.burnFrom(msg.sender, 50 ether);
        LibCore._checkCordsLongRange(_from, _to);
        if (s.map[_to[0]][_to[1]].units == 0) {
            LibCore._attackEmpty(_from, _to, _amount);
        } else if (s.map[_to[0]][_to[1]].account == msg.sender) {
            LibCore._moveUnits(_from, _to, _amount);
        } else {
            LibCore._attack(_from, _to, _amount);
        }
        emit LongRange(_from, _to, _amount, s.map[_to[0]][_to[1]].units);
    }
}
