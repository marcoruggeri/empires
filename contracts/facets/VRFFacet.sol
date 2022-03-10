// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "../libraries/AppStorage.sol";
import "./CoreFacet.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract VRFFacet is Modifiers {
    event Register(address _account, uint256[2] _coords);

    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    require(msg.sender == s.vrfCoordinator, "Only VRFCoordinator can fulfill");
    address account = s.vrfRequestIdToAccount[requestId];
    _register(account, randomWords);
    }

    function _register(address account, uint256[] memory randomWords) internal {
        IERC20 stamina = IERC20(s.staminaAddress);
        bool registered;
        uint256 x;
        uint256 y;

        for (uint256 i; i < 3; i++) {
            x = (randomWords[i] % 31);
            y = (randomWords[i + 1] % 31);
            if (s.map[x][y].account == address(0)) {
                registered = true;
                s.map[x][y].account = account;
                s.map[x][y].units = 200;
                s.map[x][y].gold = 0;
                s.registered[account] = true;
                s.lastStaminaClaimed[account] = block.timestamp;
                stamina.mint(account, 200 ether);
                emit Register(account, [x, y]);
                break;
            }
        }

        if(!registered) {
            (bool success,) = account.call{value: 5 ether} ("");
            require(success);
        }
    }

    function setConfig(RequestConfig calldata _requestConfig) external onlyOwner {
        s.requestConfig = RequestConfig(
            _requestConfig.subId,
            _requestConfig.callbackGasLimit,
            _requestConfig.requestConfirmations,
            _requestConfig.numWords,
            _requestConfig.keyHash
        );
    }

    function subscribe() external onlyOwner {
        address[] memory consumers = new address[](1);
        consumers[0] = address(this);
        s.requestConfig.subId = VRFCoordinatorV2Interface(s.vrfCoordinator).createSubscription();
        VRFCoordinatorV2Interface(s.vrfCoordinator).addConsumer(s.requestConfig.subId, consumers[0]);
    }

    function setVrfAddresses(address _vrfCoordinator, address _linkAddress) external onlyOwner {
        s.vrfCoordinator = _vrfCoordinator;
        s.linkAddress = _linkAddress;
    }

    // Assumes this contract owns link
    function topUpSubscription(uint256 amount) external {
        LinkTokenInterface(s.linkAddress).transferAndCall(s.vrfCoordinator, amount, abi.encode(s.requestConfig.subId));
    }
}