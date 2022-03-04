// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {LibAppStorage, AppStorage} from "../libraries/AppStorage.sol";
import {IERC20} from "../interfaces/IERC20.sol";

import "hardhat/console.sol";

library LibCore {
    function _moveUnits(
        uint256[2] calldata _from,
        uint256[2] calldata _to,
        uint256 _amount
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.map[_from[0]][_from[1]].units -= _amount;
        s.map[_to[0]][_to[1]].units = _amount;
    }

    function _attackEmpty(
        uint256[2] calldata _from,
        uint256[2] calldata _to,
        uint256 _amount
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.map[_from[0]][_from[1]].units -= _amount;
        s.map[_to[0]][_to[1]].units = _amount;
        s.map[_to[0]][_to[1]].account = msg.sender;
        if (s.map[_to[0]][_to[1]].gold > 0) {
            IERC20 gold = IERC20(s.goldAddress);
            gold.mint(msg.sender, s.map[_to[0]][_to[1]].gold);
        }
    }

    function _attack(
        uint256[2] calldata _from,
        uint256[2] calldata _to,
        uint256 _amount
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 attackPoints = _getRandomNumber(_amount);
        uint256 defendPoints = _getRandomNumber(
            s.map[_to[0]][_to[1]].units * 2
        );
        uint256 attackMinusDefend;
        if (attackPoints > defendPoints) {
            attackMinusDefend = attackPoints - defendPoints;
        }

        if (attackMinusDefend > s.map[_to[0]][_to[1]].units) {
            s.map[_to[0]][_to[1]].account = msg.sender;
            s.map[_to[0]][_to[1]].units = attackPoints - defendPoints;
            s.map[_from[0]][_from[1]].units -= _amount;
        } else if (attackPoints > defendPoints) {
            s.map[_from[0]][_from[1]].units -= attackMinusDefend;
            s.map[_to[0]][_to[1]].units -= attackMinusDefend / 2;
        } else if (defendPoints >= attackPoints) {
            s.map[_from[0]][_from[1]].units -= _amount;
        }
    }

    function _checkCords(uint256[2] calldata _from, uint256[2] calldata _to)
        internal
        pure
    {
        uint256 fromX = _from[0];
        uint256 fromY = _from[1];
        uint256 toX = _to[0];
        uint256 toY = _to[1];
        if (fromX == toX && fromY == toY) {
            revert("CoreFacet: equal from to coords");
        }
        require(
            (fromX == toX || fromX == toX + 1 || fromX == toX - 1) &&
                toX >= 0 &&
                toX < 32,
            "CoreFacet: Invalid x"
        );
        require(
            (fromY == toY || fromY == toY + 1 || fromY == toY - 1) &&
                toY >= 0 &&
                toY < 32,
            "CoreFacet: Invalid y"
        );
    }

    function _getRandomCoords(uint256 _max)
        internal
        view
        returns (uint256[2] memory)
    {
        uint256 x = uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    block.difficulty,
                    block.coinbase,
                    blockhash(block.number - 1)
                )
            )
        );

        uint256 y = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    msg.sender
                )
            )
        );

        x = x % _max;
        y = y % _max;

        uint256[2] memory coords = [x, y];

        return coords;
    }

    function _getRandomNumber(uint256 _max) internal view returns (uint256) {
        uint256 number = uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    block.difficulty,
                    block.coinbase,
                    blockhash(block.number - 1)
                )
            )
        );

        number = number % _max;

        return number;
    }
}
