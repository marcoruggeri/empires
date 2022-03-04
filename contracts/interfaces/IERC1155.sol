// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IERC1155 {
    function burnFrom(address _account, uint256 _id) external;
}
