pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/metatx/MinimalForwarder.sol";

contract CashOut is ERC2771Context, Pausable, Ownable {
    constructor(
        MinimalForwarder forwarder // Initialize trusted forwarder
    ) ERC2771Context(address(forwarder)) {}

    event TokenFundsDeposited(
        address indexed tokenDeposited,
        address indexed addressDeposited,
        uint256 amountDeposited
    );
    event TokenFundsWithdrawn(
        address indexed tokenWithdrawn,
        address indexed withdrawAddress,
        uint256 amountWithdrawn
    );
    event FundsWithdrawn(
        address indexed withdrawAddressNative,
        uint256 amountWithdrawnNative
    );
    event UniqueTokenAdded(address indexed addedToken);
    event contractTokenBalanceAdjusted(address indexed token, uint256 amount);
    address[] public allowedTokensAddresses;
    mapping(address => uint256) public contractTokenBalances;
    mapping(address => bool) public tokenIsAllowed;

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    receive() external payable {}

    fallback() external payable {}

    function addAllowedToken(address _token) public onlyOwner {
        require(!tokenIsAllowed[_token], "token Already Exists");
        allowedTokensAddresses.push(_token);
        tokenIsAllowed[_token] = true;
        emit UniqueTokenAdded(_token);
    }

    function depositToken(address _token, uint256 _amount) public {
        require(_amount > 0, "the amount should be greater than zero");
        require(tokenIsAllowed[_token], "the token is not currently allowed");
        require(
            IERC20(_token).balanceOf(_msgSender()) >= _amount,
            "you have insufficient Funds available in your wallet"
        );
        IERC20(_token).transferFrom(_msgSender(), address(this), _amount);
        uint256 contractTokenBalance = contractTokenBalances[_token] += _amount;
        emit contractTokenBalanceAdjusted(_token, contractTokenBalance);
        emit TokenFundsDeposited(_token, _msgSender(), _amount);
    }

    function withdrawToken(
        address _withdrawerAddress,
        address _token,
        uint256 _amount
    ) public onlyOwner whenNotPaused {
        require(_amount > 0, "Withdraw an amount greater than 0");
        require(tokenIsAllowed[_token], "the token is currently not allowed");
        require(
            IERC20(_token).balanceOf(address(this)) >= _amount,
            "insufficient tokens available in the contract"
        );
        IERC20(_token).transfer(_withdrawerAddress, _amount);
        uint256 contractTokenBalance = contractTokenBalances[_token] -= _amount;
        emit contractTokenBalanceAdjusted(_token, contractTokenBalance);
        emit TokenFundsWithdrawn(_token, _withdrawerAddress, _amount);
    }

    function withdrawCoin(address _withdrawerAddress)
        public
        payable
        onlyOwner
        whenNotPaused
    {
        uint256 _amount = address(this).balance;
        (bool success, ) = payable(_withdrawerAddress).call{value: _amount}("");
        require(success, "Failed to withdraw coin to address");
        emit FundsWithdrawn(_withdrawerAddress, _amount);
    }

    function _msgSender()
        internal
        view
        virtual
        override(Context, ERC2771Context)
        returns (address sender)
    {
        return ERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }
}
