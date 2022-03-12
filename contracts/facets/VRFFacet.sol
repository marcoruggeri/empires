// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "../libraries/AppStorage.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import "./CoreFacet.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract VRFFacet is Modifiers, VRFConsumerBase {
    event Register(address _account, uint256[2] _coords);

    constructor()
        VRFConsumerBase(
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB // LINK Token
        )
    {}

    /**
     * Requests randomness
     */

    function getRandomNumber(address _account)
        public
        returns (bytes32 requestId)
    {
        require(
            IERC20(s.linkAddress).balanceOf(address(this)) >= s.fee,
            "Not enough LINK - fill contract with faucet"
        );
        requestId = requestRandomness(s.keyHash, s.fee);
        s.vrfRequestIdToAccount[requestId] = _account;
        s.registrationStarted[_account] = true;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        address account = s.vrfRequestIdToAccount[requestId];
        _register(account, randomness);
    }

    function register() external {
        require(
            !s.registrationStarted[msg.sender],
            "CoreFacet: already registered"
        );
        getRandomNumber(msg.sender);
    }

    function _register(address account, uint256 randomness) internal {
        IERC20 stamina = IERC20(s.staminaAddress);
        bool registered;
        uint256[] memory randomWords = expand(randomness, 6);
        uint256 x;
        uint256 y;

        for (uint256 i; i < 3; i++) {
            x = (randomWords[i] % 31);
            y = (randomWords[i + 1] % 31);
            if (s.map[x][y].account == address(0)) {
                s.registered[account] = true;
                s.map[x][y].account = account;
                s.map[x][y].units = 200;
                s.map[x][y].gold = 0;
                s.registered[account] = true;
                s.lastStaminaClaimed[account] = block.timestamp;
                registered = true;
                stamina.mint(account, 250 ether);
                emit Register(account, [x, y]);
                break;
            }
        }
        if (!registered) {
            s.registered[account] = false;
        }
    }

    function setVrf(
        address _linkAddress,
        bytes32 _keyHash,
        uint256 _fee
    ) external onlyOwner {
        s.linkAddress = _linkAddress;
        s.keyHash = _keyHash;
        s.fee = _fee;
    }

    function expand(uint256 randomValue, uint256 n)
        internal
        pure
        returns (uint256[] memory expandedValues)
    {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }
}
