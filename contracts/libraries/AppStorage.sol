// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {LibDiamond} from "./LibDiamond.sol";

struct Tile {
    address account;
    uint256 troops;
}

struct AppStorage {
    Tile[256][256] map;
    mapping(address => bool) registered;
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
