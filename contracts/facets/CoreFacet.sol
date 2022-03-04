// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {AppStorage, Modifiers, Tile} from "../libraries/AppStorage.sol";
import {IStamina} from "../interfaces/IStamina.sol";

import "hardhat/console.sol";

contract CoreFacet is Modifiers {
    function register() external {
        require(!s.registered[msg.sender], "CoreFacet: already registered");
        IStamina stamina = IStamina(s.stamina);
        bool registered;
        while (!registered) {
            uint256[2] memory coords = _getRandomCoords(31);
            if (s.map[coords[0]][coords[1]].account == address(0)) {
                s.map[coords[0]][coords[1]].account = msg.sender;
                s.map[coords[0]][coords[1]].troops = 10000;
                s.registered[msg.sender] = true;
                registered = true;
                stamina.mint(msg.sender, 1000 ether);
            }
        }
    }

    function attack(
        uint256[2] calldata _from,
        uint256[2] calldata _to,
        uint256 _amount
    ) external {
        require(
            s.map[_from[0]][_from[1]].account == msg.sender,
            "CoreFacet: not owner"
        );
        require(
            s.map[_from[0]][_from[1]].troops > _amount,
            "CoreFacet: high troops"
        );
        IStamina stamina = IStamina(s.stamina);
        stamina.burnFrom(msg.sender, 10 ether);
        _checkCords(_from, _to);
        if (s.map[_to[0]][_to[1]].troops == 0) {
            _attackEmpty(_from, _to, _amount);
        } else if (s.map[_to[0]][_to[1]].account == msg.sender) {
            _moveTroops(_from, _to, _amount);
        } else {
            _attack(_from, _to, _amount);
        }
    }

    function getMap() external view returns (Tile[32][32] memory) {
        return s.map;
    }

    function getTile(uint256[2] calldata _coords)
        external
        view
        returns (Tile memory)
    {
        return s.map[_coords[0]][_coords[1]];
    }

    function _moveTroops(
        uint256[2] calldata _from,
        uint256[2] calldata _to,
        uint256 _amount
    ) internal {
        s.map[_from[0]][_from[1]].troops -= _amount;
        s.map[_to[0]][_to[1]].troops = _amount;
    }

    function _attackEmpty(
        uint256[2] calldata _from,
        uint256[2] calldata _to,
        uint256 _amount
    ) internal {
        s.map[_from[0]][_from[1]].troops -= _amount;
        s.map[_to[0]][_to[1]].troops = _amount;
        s.map[_to[0]][_to[1]].account = msg.sender;
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
        uint256 attackMinusDefend;
        if (attackPoints > defendPoints) {
            attackMinusDefend = attackPoints - defendPoints;
        }

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

    function setStaminaAddress(address _stamina) external onlyOwner {
        s.stamina = _stamina;
    }
}
