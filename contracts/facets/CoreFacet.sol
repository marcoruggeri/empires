// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {AppStorage, Modifiers, Tile} from "../libraries/AppStorage.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import "../libraries/LibCore.sol";

import "hardhat/console.sol";

contract CoreFacet is Modifiers {
    function register() external {
        require(!s.registered[msg.sender], "CoreFacet: already registered");
        IERC20 stamina = IERC20(s.staminaAddress);
        bool registered;
        while (!registered) {
            uint256[2] memory coords = LibCore._getRandomCoords(31);
            if (s.map[coords[0]][coords[1]].account == address(0)) {
                registered = true;
                s.map[coords[0]][coords[1]].account = msg.sender;
                s.map[coords[0]][coords[1]].units = 10000;
                s.registered[msg.sender] = true;
                s.lastStaminaClaimed[msg.sender] = block.timestamp;
                stamina.mint(msg.sender, 300 ether);
            }
        }
    }

    function claimStamina() external {
        require(s.registered[msg.sender], "CoreFacet: not registered");
        require(
            block.timestamp > s.lastStaminaClaimed[msg.sender] + 24 hours,
            "CoreFacet: 24hr limit"
        );
        s.lastStaminaClaimed[msg.sender] = block.timestamp;
        IERC20 stamina = IERC20(s.staminaAddress);
        stamina.mint(msg.sender, 100 ether);
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
            s.map[_from[0]][_from[1]].units > _amount,
            "CoreFacet: high units"
        );
        IERC20 stamina = IERC20(s.staminaAddress);
        stamina.burnFrom(msg.sender, 10 ether);
        LibCore._checkCords(_from, _to);
        if (s.map[_to[0]][_to[1]].units == 0) {
            LibCore._attackEmpty(_from, _to, _amount);
        } else if (s.map[_to[0]][_to[1]].account == msg.sender) {
            LibCore._moveUnits(_from, _to, _amount);
        } else {
            LibCore._attack(_from, _to, _amount);
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

    function setAddresses(
        address _staminaAddress,
        address _goldAddress,
        address _specialsAddress
    ) external onlyOwner {
        s.staminaAddress = _staminaAddress;
        s.goldAddress = _goldAddress;
        s.specialsAddress = _specialsAddress;
    }

    function initializeMap(Tile[32][32] calldata _startMap) external onlyOwner {
        for (uint256 i; i < 32; i++) {
            for (uint256 j; j < 32; j++) {
                s.map[i][j] = _startMap[i][j];
            }
        }
    }
}
