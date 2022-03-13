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

    function areaAttack(
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
        require(_to[0] > 0 && _to[0] < 31, "wrong cordinates x");
        require(_to[1] > 0 && _to[1] < 31, "wrong cordinates y");
        require(_amount == 450, "450 units needed to attack");
        IERC1155 specials = IERC1155(s.specialsAddress);
        specials.burnFrom(msg.sender, 1);
        IERC20 stamina = IERC20(s.staminaAddress);
        stamina.burnFrom(msg.sender, 200 ether);
        LibCore._checkCordsLongRange(_from, _to); // range to increase?

        // here attack the _to target
        if (s.map[_to[0]][_to[1]].units == 0) {
            LibCore._attackEmpty(_from, _to, _amount / 9);
        } else if (s.map[_to[0]][_to[1]].account == msg.sender) {
            LibCore._moveUnits(_from, _to, _amount / 9);
        } else {
            //here remove enemy from the territory before the attack and leave just 1 unit
            /* s.map[_to[0]][_to[1]].units = 1;
            LibCore._attack(_from, _to, _amount); */
            /* s.map[_to[0]][_to[1]].units = 0; */
            LibCore._attack(_from, _to, _amount / 9);
        }

        // automatically attack every tail around the target
        uint256[2] memory toAttackLater;
        toAttackLater[0] = _to[0] - 1;
        toAttackLater[1] = _to[1] - 1;
        //high-left corner
        if (s.map[_to[0] - 1][_to[1] - 1].units == 0) {
            LibCore._attackEmpty(_from, toAttackLater, _amount / 9);
        } else if (s.map[_to[0] - 1][_to[1] - 1].account == msg.sender) {
            LibCore._moveUnits(_from, toAttackLater, _amount / 9);
        } else {
            LibCore._attack(_from, toAttackLater , _amount / 9);
        }
        // high
        toAttackLater[0] = _to[0];
        toAttackLater[1] = _to[1] - 1;
        if (s.map[_to[0]][_to[1] - 1].units == 0) {
            LibCore._attackEmpty(_from, toAttackLater, _amount / 9);
        } else if (s.map[_to[0]][_to[1] - 1].account == msg.sender) {
            LibCore._moveUnits(_from, toAttackLater, _amount / 9);
        } else {
            LibCore._attack(_from, toAttackLater , _amount / 9);
        }
        //high-right corner
        toAttackLater[0] = _to[0] + 1;
        toAttackLater[1] = _to[1] - 1;
        if (s.map[_to[0] + 1][_to[1] - 1].units == 0) {
            LibCore._attackEmpty(_from, toAttackLater, _amount / 9);
        } else if (s.map[_to[0] + 1][_to[1] - 1].account == msg.sender) {
            LibCore._moveUnits(_from, toAttackLater, _amount / 9);
        } else {
            LibCore._attack(_from, toAttackLater , _amount / 9);
        }
        //left
        toAttackLater[0] = _to[0] - 1;
        toAttackLater[1] = _to[1];
        if (s.map[_to[0] - 1][_to[1]].units == 0) {
            LibCore._attackEmpty(_from, toAttackLater, _amount / 9);
        } else if (s.map[_to[0] - 1][_to[1]].account == msg.sender) {
            LibCore._moveUnits(_from, toAttackLater, _amount / 9);
        } else {
            LibCore._attack(_from, toAttackLater , _amount / 9);
        }
        //right
        toAttackLater[0] = _to[0] + 1;
        toAttackLater[1] = _to[1];
        if (s.map[_to[0] + 1][_to[1]].units == 0) {
            LibCore._attackEmpty(_from, toAttackLater, _amount / 9);
        } else if (s.map[_to[0] + 1][_to[1]].account == msg.sender) {
            LibCore._moveUnits(_from, toAttackLater, _amount / 9);
        } else {
            LibCore._attack(_from, toAttackLater , _amount / 9);
        }
        //bottom-left corner
        toAttackLater[0] = _to[0] - 1;
        toAttackLater[1] = _to[1] + 1;
        if (s.map[_to[0] - 1][_to[1] + 1].units == 0) {
            console.log("SPECIAL", _amount / 9);
            LibCore._attackEmpty(_from, toAttackLater, _amount / 9);
        } else if (s.map[_to[0] - 1][_to[1] + 1].account == msg.sender) {
            LibCore._moveUnits(_from, toAttackLater, _amount / 9);
        } else {
            LibCore._attack(_from, toAttackLater, _amount / 9);
        }
        //bottom
        toAttackLater[0] = _to[0];
        toAttackLater[1] = _to[1] + 1;
        if (s.map[_to[0]][_to[1] + 1].units == 0) {
            LibCore._attackEmpty(_from, toAttackLater, _amount / 9);
        } else if (s.map[_to[0]][_to[1] + 1].account == msg.sender) {
            LibCore._moveUnits(_from, toAttackLater, _amount / 9);
        } else {
            LibCore._attack(_from, toAttackLater, _amount / 9);
        }
        //bottom-right corner
        toAttackLater[0] = _to[0] + 1;
        toAttackLater[1] = _to[1] + 1;
        if (s.map[_to[0] + 1][_to[1] + 1].units == 0) {
            LibCore._attackEmpty(_from, toAttackLater, _amount / 9);
        } else if (s.map[_to[0] + 1][_to[1] + 1].account == msg.sender) {
            LibCore._moveUnits(_from, toAttackLater, _amount / 9);
        } else {
            LibCore._attack(_from, toAttackLater, _amount / 9);
        }
    }
}
