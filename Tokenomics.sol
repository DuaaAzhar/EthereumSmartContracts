// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Tokenomics is ERC20, Ownable {

    using SafeMath for uint256;
    uint256 _LPbuyTax=1; uint256 _GFbuyTax=2;
    uint256 _LPsellTax=1; uint256 _GFsellTax=6;
    uint256 _maxWalletTax=1;
    address public _stakingPool;
    address public _liquidityPool;
    address public _presale;
    address public _growthFund;
    address public _FDO;
    mapping (address => bool) public whiteList;
    uint256 public walletAmount;
       
    constructor(
         address stakingPool, address liquidityPool,address presale, address growthFund, address FDO
    )
         ERC20("Tokenomic", "TM") 
         {
        _mint(msg.sender, 1000000000 * 10 ** uint256(decimals()));
        _stakingPool=stakingPool;
        _liquidityPool=liquidityPool;
        _presale=presale;
        _growthFund=growthFund;
        _FDO=FDO;
        
        //balance Distribution
        uint256 balance= totalSupply();
         uint256 stakeAmount=balance.mul(10).div(100);
         _transfer(msg.sender,_stakingPool, stakeAmount);
         
         uint256 liquidityAmount= balance.mul(15).div(100);
         _transfer(msg.sender,_liquidityPool, liquidityAmount);

         uint256 presaleAmount= balance.mul(15).div(100);
         _transfer(msg.sender,_presale, presaleAmount);

         uint256 growthAmount= balance.mul(2).div(100);
         _transfer(msg.sender,_growthFund, growthAmount);

         uint256 FDOAmount= balance.mul(3).div(100);
         _transfer(msg.sender,_FDO, FDOAmount);

     }
   
     function setWhiteMember(address account) public onlyOwner{
         whiteList[account]=true;
     }
     function removeWhiteMember(address account) public onlyOwner{
         whiteList[account]=false;
     }
     
     

     function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address from= msg.sender;
        myTransfer(from, to, amount);
        return true;
    }
   
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        myTransfer(from, to, amount);
        _spendAllowance(from, msg.sender, amount);
        return true;
    }

    function myTransfer(address from, address to, uint256 amount) internal  {
        uint256 finalAmount = amount;
        require(whiteList[from] || whiteList[to], "Sender or Recipient must be WhiteMember");
        require( !(whiteList[from] && whiteList[to]), "transfer not allowed");
        //buy Tokens
        if(whiteList[to]){
            uint256 LPAmount= amount.mul(_LPbuyTax).div(100);
            if(LPAmount > 0)
                _transfer(from, _liquidityPool, LPAmount);
                
            uint256 growthAmount= amount.mul(_GFbuyTax).div(100);
            if(growthAmount > 0)
                _transfer(from, _growthFund, growthAmount); 
            finalAmount= amount.sub(LPAmount).sub(growthAmount);    
        }
        //Sell tokens
        else if(whiteList[from]){
            uint256 LPAmount= amount.mul(_LPsellTax).div(100);
            if(LPAmount > 0)
             _transfer(from , _liquidityPool, LPAmount );

            uint256 growthAmount= amount.mul(_GFsellTax).div(100);
            if(growthAmount > 0)
             _transfer(from, _growthFund, growthAmount);

            finalAmount= amount.sub(LPAmount).sub(growthAmount);
        }
        walletAmount=totalSupply().mul(_maxWalletTax).div(100);
        require( (balanceOf(to) <= walletAmount) && ( (balanceOf(to).add(finalAmount)) <= walletAmount) && (!isOwner(to))
            , "Max Limit Reached of tokens");
        _transfer(from, to, finalAmount); 
        
    }
    function isOwner(address account) public view returns(bool){
        if(account== owner())
         return true;
        else
         return false;
    }
    
    function setBuyTax(uint256 LPbuyTax, uint256 GFbuyTax) public onlyOwner{
        _LPbuyTax= LPbuyTax;
        _GFbuyTax=GFbuyTax;
    }

    function setSellTax(uint256 LPsellTax,uint256 GFsellTax) public onlyOwner{
        _LPsellTax= LPsellTax;
        _GFsellTax=GFsellTax;
    }

    function setWalletLimit(uint256 limit) public onlyOwner{
        _maxWalletTax=limit;
    }

    
     
}