// SPDX-License-Identifier: MIT

pragma solidity ^0.4.24;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    // assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    // assert(c >= a);
    return c;
  }
}

contract Ownable {

  //Contract creator/admin is the Treasurer initially. 
  //They can transfer the Treasurership later; who can transfer the Treasurership later; etc.
  address public treasurer;
  address public salesManager;


  event TreasurershipTransferred(address indexed previousTreasurer, address indexed newTreasurer);
  event SalesManagerTransferred(address indexed previousSalesManager, address indexed newSalesManager);

  /**
   * @dev Throws if called by any account other than the treasurer.
   */
  modifier onlyTreasurer() {
    require(msg.sender == treasurer);
    _;
  }
  /**
   * @dev Throws if called by any account other than the treasurer.
   */
  modifier onlySalesManager() {
    require(msg.sender == salesManager);
    _;
  }

  /**
   * @dev Allows the current treasurer to transfer control of the contract to a newTreasurer.
   * @param newTreasurer The address to transfer treasurership to.
   */
  function transferTreasurership(address newTreasurer) public onlyTreasurer {
    require(newTreasurer != address(0));
    emit TreasurershipTransferred(treasurer, newTreasurer);
    treasurer = newTreasurer;
  }

  /**
   * @dev Allows the current SalesManager to transfer control of the contract to a newSalesManager.
   * @param newSalesManager The address to transfer SalesManager to.
   */
  // function transferSalesManager(address newSalesManager) public onlySalesManager {
  function transferSalesManager(address newSalesManager) public  {
    require(newSalesManager != address(0));
    emit SalesManagerTransferred(salesManager, newSalesManager);
    salesManager = newSalesManager;
  }

}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the treasurer to pause, triggers stopped state
   */
  function pause() onlyTreasurer whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the treasurer to unpause, returns to normal state
   */
  function unpause() onlyTreasurer whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address treasurer, address secondSignee) public view returns (uint256);
  function secondSigneeTransfer(address from, address to, uint256 value) public returns (bool);
  function firstSigneeApprove(address secondSignee, uint256 value) public returns (bool);
  event Approval(address indexed treasurer, address indexed secondSignee, uint256 value);
}


contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) internal allowed;
	mapping(address => bool) tokenBlacklist;
	event Blacklist(address indexed blackListed, bool value);


  mapping(address => uint256) balances;


  function transfer(address _to, uint256 _value) public returns (bool) {
    require(tokenBlacklist[msg.sender] == false);
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }


  function balanceOf(address _treasurer) public view returns (uint256 balance) {
    return balances[_treasurer];
  }

  function secondSigneeTransfer(address _from, address _to, uint256 _value) public returns (bool) {
    require(tokenBlacklist[msg.sender] == false);
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }


  function firstSigneeApprove(address _secondSignee, uint256 _value)  public  returns (bool) {
    allowed[msg.sender][_secondSignee] = _value;
    emit Approval(msg.sender, _secondSignee, _value);
    return true;
  }


  function allowance(address _treasurer, address _secondSignee) public view  returns (uint256) {
    return allowed[_treasurer][_secondSignee];
  }


  function increaseApproval(address _secondSignee, uint _addedValue) public  returns (bool) {
    allowed[msg.sender][_secondSignee] = allowed[msg.sender][_secondSignee].add(_addedValue);
    emit Approval(msg.sender, _secondSignee, allowed[msg.sender][_secondSignee]);
    return true;
  }

  function decreaseApproval(address _secondSignee, uint _subtractedValue) public  returns (bool) {
    uint oldValue = allowed[msg.sender][_secondSignee];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_secondSignee] = 0;
    } else {
      allowed[msg.sender][_secondSignee] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _secondSignee, allowed[msg.sender][_secondSignee]);
    return true;
  }
  


  function _blackList(address _address, bool _isBlackListed) internal returns (bool) {
	require(tokenBlacklist[_address] != _isBlackListed);
	tokenBlacklist[_address] = _isBlackListed;
	emit Blacklist(_address, _isBlackListed);
	return true;
  }



}

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused  returns (bool) {
    return super.transfer(_to, _value);
  }

  function secondSigneeTransfer(address _from, address _to, uint256 _value) public whenNotPaused  returns (bool) {
    return super.secondSigneeTransfer(_from, _to, _value);
  }

  // function firstSigneeApprove(address _secondSignee, uint256 _value) public whenNotPaused onlySalesManager returns (bool) {
  function firstSigneeApprove(address _secondSignee, uint256 _value) public whenNotPaused  returns (bool) {
    return super.firstSigneeApprove(_secondSignee, _value);
  }

  // function increaseApproval(address _secondSignee, uint _addedValue) public whenNotPaused onlySalesManager returns (bool success) {
  function increaseApproval(address _secondSignee, uint _addedValue) public whenNotPaused  returns (bool success) {
    return super.increaseApproval(_secondSignee, _addedValue);
  }
  
  // function decreaseApproval(address _secondSignee, uint _subtractedValue) public whenNotPaused onlySalesManager returns (bool success) {
  function decreaseApproval(address _secondSignee, uint _subtractedValue) public whenNotPaused  returns (bool success) {
    return super.decreaseApproval(_secondSignee, _subtractedValue);
  }

  function blackListAddress(address listAddress,  bool isBlackListed) public whenNotPaused   returns (bool success) {
	return super._blackList(listAddress, isBlackListed);
  }
  
}

contract Raj3Coin is PausableToken {
    string public name;
    string public symbol;
    uint public decimals;
    event Mint(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);
    // event secondSigneeTransfer(address indexed _from, address indexed _to, uint256 _value);

	
    constructor(string memory _name, string memory _symbol, uint256 _decimals, uint256 _supply, address _Treasurer, address _SalesManager) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply * 10**_decimals;
        balances[_Treasurer] = totalSupply;
        treasurer = _Treasurer;
        salesManager = _SalesManager;
        emit Transfer(address(0), _Treasurer, totalSupply);
    }
	
	function burn(uint256 _value) public onlyTreasurer{
		_burn(msg.sender, _value);
	}

	function _burn(address _who, uint256 _value) internal {
		require(_value <= balances[_who]);
		balances[_who] = balances[_who].sub(_value);
		totalSupply = totalSupply.sub(_value);
		emit Burn(_who, _value);
		emit Transfer(_who, address(0), _value);
	}

    function mint(address account, uint256 amount) onlyTreasurer public {

        totalSupply = totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Mint(address(0), account, amount);
        emit Transfer(address(0), account, amount);
    }

    //mapping for discountCoupon
    mapping (address => uint256) discountCoupon;

    function  applyDiscount(address _account, uint256 _value) public  onlySalesManager returns (uint256){
      discountCoupon[_account] = _value;
      return discountCoupon[_account];
    }



    function discountedTransfer(address _to, uint256 _value) public returns (bool) {
        // _value = _value*(1-discountCoupon[_to]/100);
          emit Transfer(msg.sender, _to, discountCoupon[msg.sender]);
        transfer(_to, _value.sub(discountCoupon[msg.sender]));
        discountCoupon[msg.sender] = 0;
        return true;
    }

    
}