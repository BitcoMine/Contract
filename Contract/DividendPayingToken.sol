// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./SafeMathUint.sol";
import "./SafeMathInt.sol";
import "./DividendPayingTokenInterface.sol";
import "./DividendPayingTokenOptionalInterface.sol";
import "./Ownable.sol";


contract DividendPayingToken is ERC20, Ownable, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  address public  BTC = address(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c);
  address public  BME;

  uint256 constant internal magnitude = 2**128;

  mapping(address => uint256) public HolderTokensBTC;
  mapping(address => int256) internal magnifiedBTCDividendCorrections;
  mapping(address => uint256) internal withdrawnBTCDividends;
  uint256 internal magnifiedBTCDividendPerShare;
  uint256 public totalBTCDividendsDistributed;
  uint256 public  CurrentSupplyBTC;

  mapping(address => uint256) public HolderTokensBME;
  mapping(address => int256) internal magnifiedBMEDividendCorrections;
  mapping(address => uint256) internal withdrawnBMEDividends;
  uint256 internal magnifiedBMEDividendPerShare;
  uint256 public totalBMEDividendsDistributed;
  uint256 public  CurrentSupplyBME;

  constructor(string memory _name, string memory _symbol) public ERC20(_name, _symbol) {

  }


  function distributeDividends(uint256 BTCamount ,uint256 BMEamount) public onlyOwner{

      if (BTCamount > 0 && CurrentSupplyBTC > 0) {
      magnifiedBTCDividendPerShare = magnifiedBTCDividendPerShare.add((BTCamount).mul(magnitude) / CurrentSupplyBTC);
      emit DividendsDistributed(msg.sender, BTCamount);
      totalBTCDividendsDistributed = totalBTCDividendsDistributed.add(BTCamount);
      }

      if (BMEamount > 0 && CurrentSupplyBME > 0) {
      magnifiedBMEDividendPerShare = magnifiedBMEDividendPerShare.add((BMEamount).mul(magnitude) / CurrentSupplyBME);
      emit DividendsDistributed(msg.sender, BMEamount);
      totalBMEDividendsDistributed = totalBMEDividendsDistributed.add(BMEamount);
      }
  }

  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(msg.sender);
  }

  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
      uint256 _withdrawableDividend = withdrawableDividendOf(user);

    if ( _withdrawableDividend > 0 ) {

      withdrawnBTCDividends[user] = withdrawnBTCDividends[user].add(_withdrawableDividend);

      bool successBTC = IERC20(BTC).transfer(user, _withdrawableDividend);

      if( !successBTC ) {
        withdrawnBTCDividends[user] = withdrawnBTCDividends[user].sub(_withdrawableDividend);
            return 0;
          }
       return _withdrawableDividend;
       }
    return 0;
    }


  function _withdrawDividendOfUserBME(address payable user) internal returns (uint256) {
      uint256 _withdrawableDividendBME = withdrawableDividendOfBME(user);

   if (_withdrawableDividendBME > 0 ) {

   withdrawnBMEDividends[user] = withdrawnBMEDividends[user].add(_withdrawableDividendBME);

   bool successBME = IERC20(BME).transfer(user, _withdrawableDividendBME);

   if(!successBME) {
     withdrawnBMEDividends[user] = withdrawnBMEDividends[user].sub(_withdrawableDividendBME);
            return 0;
           }
        return _withdrawableDividendBME;
        }
    return 0;
    }


  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnBTCDividends[_owner]);
  }

  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnBTCDividends[_owner];
  }

  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedBTCDividendPerShare.mul(HolderTokensBTC[_owner]).toInt256Safe()
      .add(magnifiedBTCDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  function setBMEadd(address newaddress) public onlyOwner{
    BME = address(newaddress);
  }

  function dividendOfBME(address _owner) public view returns(uint256) {
    return withdrawableDividendOfBME(_owner);
  }

  function withdrawableDividendOfBME(address _owner) public view returns(uint256) {
    return accumulativeDividendOfBME(_owner).sub(withdrawnBMEDividends[_owner]);
  }

  function withdrawnDividendOfBME(address _owner) public view returns(uint256) {
    return withdrawnBMEDividends[_owner];
  }

  function accumulativeDividendOfBME(address _owner) public view returns(uint256) {
    return magnifiedBMEDividendPerShare.mul(HolderTokensBME[_owner]).toInt256Safe()
      .add(magnifiedBMEDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  function _mint(address account, uint256 value) internal override {
    HolderTokensBTC[account] = HolderTokensBTC[account].add(value);
    CurrentSupplyBTC = CurrentSupplyBTC.add(value);

    magnifiedBTCDividendCorrections[account] = magnifiedBTCDividendCorrections[account]
    .sub( (magnifiedBTCDividendPerShare.mul(value)).toInt256Safe() );

  }

  function _burn(address account, uint256 value) internal override {
    HolderTokensBTC[account] = HolderTokensBTC[account].sub(value);
    CurrentSupplyBTC = CurrentSupplyBTC.sub(value);

    magnifiedBTCDividendCorrections[account] = magnifiedBTCDividendCorrections[account]
    .add( (magnifiedBTCDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _mintBME(address account, uint256 value) internal  {
    HolderTokensBME[account] = HolderTokensBME[account].add(value);
    CurrentSupplyBME = CurrentSupplyBME.add(value);

    magnifiedBMEDividendCorrections[account] = magnifiedBMEDividendCorrections[account]
    .sub( (magnifiedBMEDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _burnBME(address account, uint256 value) internal  {
    HolderTokensBME[account] = HolderTokensBME[account].sub(value);
    CurrentSupplyBME = CurrentSupplyBME.sub(value);

    magnifiedBMEDividendCorrections[account] = magnifiedBMEDividendCorrections[account]
    .add( (magnifiedBMEDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = HolderTokensBTC[account];

    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }

  function _setBalanceBME(address account, uint256 newBalance) internal {
    uint256 currentBalance = HolderTokensBME[account];

    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mintBME(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burnBME(account, burnAmount);
    }
  }

}
