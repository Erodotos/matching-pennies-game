pragma solidity 0.8.0;

/// @title Matching pennies game
/// @author Erodotos Demetriou
contract Game {
    uint256 public _playDeadline;
    address public _playedLast;
    address public _adr_playerA;
    address public _adr_playerB;

    mapping(address => Bet) public _bets;

    struct Bet {
        string _realBet;
        bytes32 _hiddenBet;
        bool _isValid;
    }

    uint8 public _locked = 0;
    uint8 public _playersJoined = 0;
    address public _winner;

    event Play(address indexed _playerAddress, uint8 _playerNumber);
    event WinnerAnnounced(address indexed _winner);
    event NewGame(string _newGame);

    /// @notice Takes 1 ETH as bet stake and set contract state accordingly
    /// @param _bet This is an obscured 32-byte string produced after
    /// hashing (real_bet || salt)
    function giveHiddenBet(bytes32 _bet) public payable {
        // Perform checks
        require(
            _locked == 0,
            "There are already 2 players. Wait for the next game to start!"
        );
        require(msg.value == 1 ether, "You must bet 1 ETH");
        require(
            _bets[msg.sender]._hiddenBet == bytes32(0),
            "You have already put your bet"
        );

        // Change the smart contract state
        _playersJoined += 1;
        _bets[msg.sender]._hiddenBet = _bet;
        _playDeadline = block.timestamp + 10 minutes;
        _playedLast = msg.sender;

        // Lock the contract if both players beted
        // and emmit events to announce their participation
        if (_playersJoined == 2) {
            _locked = 1;
            _adr_playerB = msg.sender;
            emit Play(msg.sender, 2);
        } else {
            _adr_playerA = msg.sender;
            emit Play(msg.sender, 1);
        }
    }

    /// @notice Receives the players real bets 
    /// and their salt and check the initial bet validity
    /// @param _realBet A string representing the real bet
    /// @param _salt The salt that the message sender used
    /// to create his initial obscured bet
    function giveRealBet(string memory _realBet, string memory _salt) external {
        require(_playersJoined == 2, "Wait for player #2 to join the game");
        require(
            keccak256(abi.encodePacked(_realBet, _salt)) ==
                _bets[msg.sender]._hiddenBet,
            "Error: Provided invalid input: Abort"
        );

        _bets[msg.sender]._realBet = _realBet;
        _bets[msg.sender]._isValid = true;

        _playedLast = msg.sender;
        _playDeadline = block.timestamp + 10 minutes;
    }

    /// @notice Calculates the game winner
    function evaluateWinner() external {
        require(
            _bets[_adr_playerA]._isValid && _bets[_adr_playerB]._isValid,
            "Error: Players did not provide their real bet"
        );

        if (
            keccak256(abi.encode(_bets[_adr_playerA]._realBet)) ==
            keccak256(abi.encode(_bets[_adr_playerA]._realBet))
        ) {
            _winner = _adr_playerA;
        } else if (
            keccak256(abi.encode(_bets[_adr_playerA]._realBet)) !=
            keccak256(abi.encode(_bets[_adr_playerA]._realBet))
        ) {
            _winner = _adr_playerB;
        }

        // Emit event
        emit WinnerAnnounced(_winner);
    }

    /// @notice Let a player to stop the game and get 
    /// refund in case his opponent griefs
    function requestRefund() external {
        // Checks
        require(
            block.timestamp > _playDeadline &&
                msg.sender == _playedLast &&
                _winner == address(0),
            "You are not allowed  to request a refund yet!"
        );

        gameReset(1 ether);
    }

    /// @notice Allows the winner to withdraw his reward
    function withdraw() external {
        // Checks
        require(msg.sender == _winner, "You are not the winner!");

        gameReset(2 ether);
    }

    /// @notice Send money to the winner or the 
    /// refund requestor and reset game variables for a new round
    function gameReset(uint8 _value) internal {
        _locked = 0;
        _winner = address(0);
        _playersJoined = 0;
        _bets[_adr_playerA] = Bet("", bytes32(0), false);
        _bets[_adr_playerB] = Bet("", bytes32(0), false);
        _adr_playerA = address(0);
        _adr_playerB = address(0);
        _playDeadline = 0;

        // Reward/Refund transfer
        (bool success, ) = msg.sender.call{value: _value}("");
        require(success, "Error: Withdraw unsuccessful");

        // Emmit event
        emit NewGame("New game spots available");
    }
}
