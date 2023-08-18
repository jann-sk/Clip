// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ETHToken {
    string public name = "ETH Token";
    string public symbol = "ETHT";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event LogMessage(address message);

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        emit LogMessage(msg.sender);
        emit LogMessage(spender);
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool) {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf[msg.sender], "ERC20: insufficient balance");

        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(
            amount <= balanceOf[sender],
            "ERC20: insufficient balance line56"
        );
        require(
            amount <= allowance[sender][msg.sender],
            "ERC20: transfer amount exceeds allowance"
        );

        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        allowance[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(address to, uint256 amount) external returns (bool) {
        require(to != address(0), "ERC20: mint to the zero address");

        totalSupply += amount;
        balanceOf[to] += amount;

        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
        return true;
    }

    function burn(uint256 amount) external returns (bool) {
        require(
            amount <= balanceOf[msg.sender],
            "ERC20: burn amount exceeds balance"
        );

        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;

        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }
}
