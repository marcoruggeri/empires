// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {LibDiamond} from "./LibDiamond.sol";

struct Tile {
    address account;
    uint256 units;
    uint256 gold;
    uint256 lastSuperDefender;
}

struct AppStorage {
    Tile[32][32] map;
    mapping(address => bool) registered;
    address staminaAddress;
    address goldAddress;
    address specialsAddress;
    address linkAddress;
    bytes32 keyHash;
    uint256 fee;
    mapping(address => uint256) lastStaminaClaimed;
    // x => y => last timestamp
    mapping(uint256 => mapping(uint256 => uint256)) lastGoldClaimed;
    mapping(bytes32 => address) vrfRequestIdToAccount;
    mapping(address => bool) registrationStarted;
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
