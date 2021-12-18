//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

//Import openzepplin-contracts ERC20 library from github
import "./node_modules/openzeppelin-contracts/token/ERC20/ERC20.sol";


//Contract token raj2Coin
contract Token is ERC20 ("raj2Coin", "RAJ2") {
    address internal admin; // Address of the Admin
    address internal treasurer; // Address of the Treasurer
    address internal salesManager; // Address of the sales manager

    //Constructor
    constructor () {
        admin = msg.sender; 
    }
    
    //Function to set the treasurer
    function setAdmin(address _treasurer) public onlyAdmin {
        treasurer = _treasurer;
    }

    //Function to set the sales manager
    function setSalesManager(address _salesManager) public onlyAdmin {
        salesManager = _salesManager;
    }
    
    //Function to mint tokens on a Promotional basis
    //If the _amount is greater than 10,000 then you get 5% extra
    function mintPromotion (address _to, uint256 _amount) public onlySalesManager {
        require(_amount > 0);

        if (_amount > 10000) {
            _amount = _amount + (_amount * 5 / 100);
        }
        _mint(_to, _amount);
    }

    //Function to transfer tokens to another address
    function transfer(address payable _from, address _to, uint _value) public onlyTreasurer returns (bool success)  {
        require(_value > 0);
        if (balanceOf(_from) >= _value) {
            _transfer(_from, _to, _value);
            return true;
        }
    }


    modifier onlyAdmin {
        require( msg.sender == admin );
        _;
    }
    modifier onlySalesManager {
        require( msg.sender == salesManager );
        _;
    }
    modifier onlyTreasurer {
        require( msg.sender == treasurer );
        _;
    }
}


    