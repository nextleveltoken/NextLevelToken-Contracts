pragma solidity ^0.4.11;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


//ERC Token Standard #20 Interface
contract ERC20Interface {
    //Get the total token supply
    function totalSupply() constant returns (uint256 totalSupply);
    
    //Get the account balance of another account with address _owner
    function balanceOf(address _owner) constant returns (uint256 balance);
    
    //Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) returns (bool success);
    
    //Send _value amount of tokens to address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    
    /*Allow _spender to withdraw from your account, multiple times,
    up to the _value amount*/
    function approve(address _spender, uint256 _value) returns (bool success);
    
    //Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    
    //Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    //Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract NextLevelToken is ERC20Interface {
    using SafeMath for uint256;
    
    string public constant symbol = "NLT";
    string public constant name = "NextLevelToken";
    uint public constant decimals = 0;
    uint256 _totalSupply = 175000000;
    uint public blackoutEnd = now + 10 weeks;
    uint public devBlackout = now + 72 weeks;
    address public devWallet;
    
    //Owner of this contract
    address public owner;
    
    //Events
    event FrozenFunds(address target, bool frozen);
    
    //Balances for each account
    mapping(address => uint256) balances;
    
    //Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;
    
    //Can the account transfer?
    mapping (address => bool) public frozenAccount;
    
    
    //Functions with is modifier can only be executed by the owner
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
    
    //Constructor
    function NextLevelToken() {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }
    
    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = _totalSupply;
    }
    
    // What is the balance of a particular account?
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    //Set the developer wallet and lock it
    function setDevWallet(address wallet) onlyOwner {
        if (devWallet != 0x0) revert();
        devWallet = wallet;
    }
    
     // Transfer the balance from owner's account to another account
    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (frozenAccount[msg.sender]) revert();
        if (msg.sender != owner) {
            if(now <= blackoutEnd) revert();
        }    
        if (msg.sender == devWallet) {
            if(now <= devBlackout) revert();
        }
        
        if (balances[msg.sender] >= _amount 
            && _amount > 0
            && balances[_to].add(_amount) > balances[_to]) {
            balances[msg.sender] = balances[msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
      }
      
    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool success) {
        if (frozenAccount[msg.sender]) revert();
        if (msg.sender != owner) {
            if(now <= blackoutEnd) revert();
        }  
        if (msg.sender == devWallet) {
            if(now <= devBlackout) revert();
        }
        
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to].add(_amount) > balances[_to]) {
            balances[_from] = balances[_from].sub(_amount);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
      
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
  
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    //Freeze or Unfreeze Account
    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    
    //Get Blackout End
    function getBlackoutEnd() constant returns (uint) {
        return blackoutEnd;
    }
    
    //Get Dev Blackout End
    function getDevBlackoutEnd() constant returns (uint) {
        return devBlackout;
    }
    
}
