// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {LibDiamond} from "./LibDiamond.sol";

struct Tile {
    address account;
    uint256 units;
    uint256 gold;
}

struct AppStorage {
    Tile[32][32] map;
    mapping(address => bool) registered;
    address staminaAddress;
    address goldAddress;
    address specialsAddress;
    mapping(address => uint256) lastStaminaClaimed;
    // x => y => last timestamp
    mapping(uint256 => mapping(uint256 => uint256)) lastGoldClaimed;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage internal s;

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }
}
