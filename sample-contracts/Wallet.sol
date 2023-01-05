//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract SampleWallet {
    address payable owner;
    // quem é esse owner?

    mapping(address => uint256) public allowance;
    mapping(address => bool) public isAllowedToSend;

    mapping(address => bool) public guardian;
    address payable nextOwner;
    uint256 guardiansResetCount;
    uint256 public constant confirmationsFromGuardiansForReset = 3;

    constructor() {
        owner = payable(msg.sender);
        // sim, o owner é quem chamou o contrato
        // inicia a variável, falando que pode trocar valores
    }

    // permitir que outras pessoas gastem fundos dessa carteira
    function proposeNewOwner(address payable newOwner) public {
        require(guardian[msg.sender], "You are not guardian, aborting");
        // o q esse require faz exatamente?
        if (nextOwner != newOwner) {
            // checa se o newOwner proposto, já é o mesmo que o nextOwner que estava
            nextOwner = newOwner;
            guardiansResetCount = 0;
        }

        guardiansResetCount++;

        if (guardiansResetCount >= confirmationsFromGuardiansForReset) {
            owner = nextOwner;
            nextOwner = payable(address(0));
        }
    }

    function setAllowance(address _from, uint256 _amount) public {
        require(msg.sender == owner, "You are not the owner, aborting!");
        allowance[_from] = _amount;
        isAllowedToSend[_from] = true;
    }

    function denySending(address _from) public {
        require(msg.sender == owner, "You are not the owner, aborting!");
        isAllowedToSend[_from] = false;
    }

    function transfer(
        address payable _to,
        uint256 _amount,
        bytes memory payload
    ) public returns (bytes memory) {
        require(
            _amount <= address(this).balance,
            "Can't send more than the contract owns, aborting."
        );
        if (msg.sender != owner) {
            require(
                isAllowedToSend[msg.sender],
                "You are not allowed to send any transactions, aborting"
            );
            require(
                allowance[msg.sender] >= _amount,
                "You are trying to send more than you are allowed to, aborting"
            );
            allowance[msg.sender] -= _amount;
        }
        (bool success, bytes memory returnData) = _to.call{value: _amount}(
            payload
        );
        require(success, "Transaction failed, aborting");
        return returnData;
    }

    receive() external payable {}
}
