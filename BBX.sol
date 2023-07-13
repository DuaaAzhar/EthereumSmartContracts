// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    function percentageAmount( uint256 total_, uint8 percentage_ ) internal pure returns ( uint256 percentAmount_ ) {
        return div( mul( total_, percentage_ ), 1000 );
    }

    function substractPercentage( uint256 total_, uint8 percentageToSub_ ) internal pure returns ( uint256 result_ ) {
        return sub( total_, div( mul( total_, percentageToSub_ ), 1000 ) );
    }

    function percentageOfTotal( uint256 part_, uint256 total_ ) internal pure returns ( uint256 percent_ ) {
        return div( mul(part_, 100) , total_ );
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    function quadraticPricing( uint256 payment_, uint256 multiplier_ ) internal pure returns (uint256) {
        return sqrrt( mul( multiplier_, payment_ ) );
    }

  function bondingCurve( uint256 supply_, uint256 multiplier_ ) internal pure returns (uint256) {
      return mul( multiplier_, supply_ );
  }
}



interface IOwnable {
  function owner() external view returns (address);
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}
abstract contract Ownable is IOwnable,Context {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }
    
    function pushManagement( address newOwner_ ) public virtual override onlyOwner() {
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }
    
    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
        _newOwner = address(0);
    }
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}
contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor ()  {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function removeMinter(address account) public onlyMinter {
        _removeMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

contract BBX is ERC20('BBX Token', 'BBX'),MinterRole,Ownable{

  using SafeMath for uint256;

   uint256 buyTax;
   uint256 TreasuryTax;
   uint256 BurnTax;
   mapping (address => bool) public whiteList;
   address TreasuryWallet;

 uint256 private constant _initialSupply = 3000000*10**18;
    constructor() {
        _mint(msg.sender, _initialSupply);
    }



 function mint(address account, uint256 amount) public  onlyMinter returns (bool) {
    _mint(account, amount);
    return true;
  }

   function burn(address account,uint256 amount) public   onlyMinter returns (bool) {
    _burn(account, amount);
    return true;
  }


 function transfer(address to, uint256 amount) public override returns (bool) {
        
        address owner = _msgSender();
        //require(whiteList[owner] || whiteList[to] , "None of the member is included in WhiteList");
        require(whiteList[owner]!=true || whiteList[to]!=true , "Both of the members are included in whiteList");
        if (whiteList[owner])
        {
        uint256 _Buytax= amount.mul(buyTax).div(100);
        uint256 finalAmount=amount.sub(_Buytax);
        _transfer(owner, to, finalAmount);
        }
        
        else if (whiteList[to])
        {
          uint256 _Treasurytax = amount.mul(TreasuryTax).div(100);
          _transfer(owner,TreasuryWallet, _Treasurytax);
         uint256 _BurnTax = amount.mul(BurnTax).div(100);
         burn(owner,_BurnTax);
         uint256 totalTax=_Treasurytax.add(_BurnTax);
         uint256 finalAmount=amount.sub(totalTax);
         _transfer(owner, to, finalAmount);
        }
        else{
             _transfer(owner,to, amount);
        }
        return true;
    }
    

    function transferFrom(address from,address to,uint256 amount) public override returns (bool) {
        address spender = _msgSender();  
        _spendAllowance(from, spender, amount);
        // require(whiteList[from] || whiteList[to] , "None of the member is included in WhiteList");
        require(whiteList[from]!=true && whiteList[to]!=true , "Both of the members are included in whiteList");
        if (whiteList[from])
        {
        uint256 _Buytax= amount.mul(buyTax).div(100);
        uint256 finalAmount=amount.sub(_Buytax);
         _transfer(from, to, finalAmount);
        }
        else if (whiteList[to])
        {
          uint256 _Treasurytax = amount.mul(TreasuryTax).div(100);
          _transfer(from,TreasuryWallet, _Treasurytax);
         uint256 _BurnTax = amount.mul(BurnTax).div(100);
         burn(from, _BurnTax);
         uint256 totalTax=_Treasurytax.add(_BurnTax);
         uint256 finalAmount=amount.sub(totalTax);
         _transfer(from, to, finalAmount);
        }
        else{
            _transfer(from,to, amount);
        }
       
        return true;
    }



   function includeInWhiteList(address account) public onlyOwner {
        whiteList[account] = true;
    }
    function removeFromWhiteList(address account) public onlyOwner{
        whiteList[account]=false;
    }
 
   
    function setSellTax (uint256 _treasuryTax, uint256 _burnTax ) public onlyOwner
    {
          TreasuryTax=_treasuryTax;
          BurnTax=_burnTax;

    }

    function setBuyTax (uint256 _buyTax ) public onlyOwner
    {
          buyTax=_buyTax;

    }

      function setTreasuryAddress (address _treasuryWallet ) public onlyOwner
    {
         
         TreasuryWallet=_treasuryWallet;
    }
}
