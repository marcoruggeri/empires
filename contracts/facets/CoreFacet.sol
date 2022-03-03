// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {AppStorage, Modifiers, Tile} from "../libraries/AppStorage.sol";

contract CoreFacet is Modifiers {
    function register() external {
        require(!s.registered[msg.sender], "already registered");
        uint256[2] memory coords = _getRandomCoords(256);
        s.map[coords[0]][coords[1]].account = msg.sender;
        s.map[coords[0]][coords[1]].troops = 10000;
    }

    function attack(
        uint256[2] calldata _from,
        uint256[2] calldata _to,
        uint256 _amount
    ) external {
        require(s.map[_from[0]][_from[1]].account == msg.sender, "not owner");
        require(
            s.map[_from[0]][_from[1]].troops > _amount,
            "amount higher than troops"
        );
        _checkCords(_from, _to);
        if (s.map[_to[0]][_to[1]].troops == 0) {
            _attackEmpty(_from, _to, _amount);
        } else {
            _attack(_from, _to, _amount);
        }
    }

    function getMap() external view returns (Tile[256][256] memory) {
        return s.map;
    }

    function _attackEmpty(
        uint256[2] calldata _from,
        uint256[2] calldata _to,
        uint256 _amount
    ) internal {
        s.map[_from[0]][_from[1]].troops -= _amount;
        s.map[_to[0]][_to[1]].troops = _amount;
    }

    function _attack(
        uint256[2] calldata _from,
        uint256[2] calldata _to,
        uint256 _amount
    ) internal {
        uint256 attackPoints = _getRandomNumber(_amount);
        uint256 defendPoints = _getRandomNumber(
            s.map[_to[0]][_to[1]].troops * 2
        );
        uint256 attackMinusDefend = attackPoints - defendPoints;

        if (attackMinusDefend > s.map[_to[0]][_to[1]].troops) {
            s.map[_to[0]][_to[1]].account = msg.sender;
            s.map[_to[0]][_to[1]].troops = attackPoints - defendPoints;
            s.map[_from[0]][_from[1]].troops -= _amount;
        } else if (attackPoints > defendPoints) {
            s.map[_from[0]][_from[1]].troops -= attackMinusDefend;
            s.map[_to[0]][_to[1]].troops -= attackMinusDefend / 2;
        } else if (defendPoints >= attackPoints) {
            s.map[_from[0]][_from[1]].troops -= _amount;
        }
    }

    function _checkCords(uint256[2] calldata _from, uint256[2] calldata _to)
        private
        pure
    {
        uint256 fromX = _from[0];
        uint256 fromY = _from[1];
        uint256 toX = _to[0];
        uint256 toY = _to[1];
        require(
            (fromX == toX || fromX == toX + 1 || toX == toX - 1) &&
                toX >= 0 &&
                toX <= 256,
            "Invalid x"
        );
        require(
            (fromY == toY || fromY == toY + 1 || toY == toY - 1) &&
                toY >= 0 &&
                toY <= 256,
            "Invalid y"
        );
    }

    function _getRandomCoords(uint256 _max)
        private
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

    function _getRandomNumber(uint256 _max) private view returns (uint256) {
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
