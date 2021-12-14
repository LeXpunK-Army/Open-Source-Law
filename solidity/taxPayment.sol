//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/// FOR DEMONSTRATION ONLY, incomplete, unaudited, not recommended to be used for any purpose and provided with no warranty whatsoever
/// @notice simple tax remitting contract to give IRS its pound of DeFi flesh, sends whole-uint tax rate to immutable IRS wallet address 
 
interface IERC20 {

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// contingent on numerous external factors such as jurisdiction and status of each msg.sender, but initially created as a flat rate federal tax demonstration
// meant to be an abstract add-on to another contract which results in income taxable event when a dApp makes a transaction 
contract TaxPayment {
  
    address payable public immutable IRS;
    uint256 public immutable taxRate;
    mapping(address => uint256) taxPaymentNumber;
    mapping(uint256 => mapping(address => uint256) /*taxPaymentNumber*/) taxPaymentNumberAmount;
    
    event TaxPaid(address indexed taxpayer, uint256 indexed taxPaymentNumber, uint256 indexed timeOfPayment, uint256 taxPaymentAmount);
    
    /// @param _IRSaddress IRS's designated address to receive taxes
    /// @param _taxRate flat percentage tax rate expressed as a whole number, for now
    constructor(address _IRSaddress, uint256 _taxRate) payable {
        require(_IRSaddress != address(0), "Invalid IRS wallet address");
        require(_taxRate > 0 && _taxRate < 100, "Submit tax rate percentage as whole number between 0 and 100, for example 5 for 5%");
        IRS = payable(_IRSaddress); 
        taxRate = _taxRate*10e16;
    }
    
    // ******** msg.sender must separately approve address(this) for tokenAddress ********
    /// @param _income received income amount by msg.sender in the applicable token corresponding to _tokenAddress, assuming 18 decimals 
    /// @param _tokenAddress contract address of ERC20 token received (if applicable/if not simple ETH payment)
    /// @return taxes paid, tax payment number for this msg.sender
    function payTax(uint256 _income, address _tokenAddress) public returns(uint256, uint256) {
        IERC20 ierc20;
        ierc20 = IERC20(_tokenAddress);
        uint256 _taxes = (_income*taxRate)/10e18;
        ierc20.transferFrom(msg.sender, IRS, _taxes);
	    taxPaymentNumber[msg.sender]++;
	    taxPaymentNumberAmount[_taxes][msg.sender] = taxPaymentNumber[msg.sender];
	    emit TaxPaid(msg.sender, taxPaymentNumber[msg.sender], block.timestamp, _taxes);
        return(_taxes, taxPaymentNumber[msg.sender]);
    }
}