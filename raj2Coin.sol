//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

//Import openzepplin ERC20 library
import "../github/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

//Contract token raj2Coin
contract Token is ERC20 ("raj2Coin", "RAJ2") {
    //Constructor
    constructor () {
        //call erc20 _mint  
        _mint (msg.sender, 1000000 * (10 ** uint256(decimals())));
    }
}


    