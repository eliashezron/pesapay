// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract CashOuty is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
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
    uint256 public nativeBalance;
    address[] public allowedTokensAddresses;
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");
    mapping(address => uint256) public contractTokenBalances;
    mapping(address => bool) public tokenIsAllowed;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    receive() external payable {
        nativeBalance += msg.value;
    }

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
            IERC20Upgradeable(_token).balanceOf(msg.sender) >= _amount,
            "you have insufficient Funds available in your wallet"
        );
        IERC20Upgradeable(_token).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        uint256 contractTokenBalance = contractTokenBalances[_token] += _amount;
        emit contractTokenBalanceAdjusted(_token, contractTokenBalance);
        emit TokenFundsDeposited(_token, msg.sender, _amount);
    }

    function withdrawToken(
        address _withdrawerAddress,
        address _token,
        uint256 _amount
    ) public onlyOwner whenNotPaused {
        require(_amount > 0, "Withdraw an amount greater than 0");
        require(tokenIsAllowed[_token], "the token is currently not allowed");
        require(
            IERC20Upgradeable(_token).balanceOf(address(this)) >= _amount,
            "insufficient tokens available in the contract"
        );
        IERC20Upgradeable(_token).transfer(_withdrawerAddress, _amount);
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
        nativeBalance = 0;
        emit FundsWithdrawn(_withdrawerAddress, _amount);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
