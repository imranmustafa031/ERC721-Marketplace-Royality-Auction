// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("NFTT", "NFTT") {
        _mint(msg.sender, initialSupply);
    }
    function decimals() public view override virtual returns (uint8){
        return 0;
    }
}