// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Game {
    
    address public _adr_playerA;
    address public _adr_playerB;
    
    mapping(address => Bet) public _bets;
    
    struct Bet{
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

    function giveHiddenBet(bytes32 _bet) public payable{
        // Perform checks
        require(_locked == 0, "There are already 2 players. Wait for the next game to start!");
        require(msg.value == 1 ether, "You must bet 1 ETH");
        require(_bets[msg.sender]._hiddenBet == bytes32(0), "You have already put your bet");
        
        // Change the smart contract state
        _playersJoined += 1;
        _bets[msg.sender]._hiddenBet = _bet;
        
        // Lock the contract if both players beded 
        // and emmit events to announce their participation
        if (_playersJoined == 2){
            _locked = 1;
            _adr_playerB = msg.sender;
            // Emmit event
            emit Play(msg.sender, 2);
        }else{
            _adr_playerA = msg.sender;
            // Emmit event
            emit Play(msg.sender, 1);
        }
        
    }
    
    function giveRealBet(string memory _realBet, string memory _salt) external{
        require(_playersJoined == 2, "Wait for player #2 to join the game");
        require(keccak256(abi.encodePacked(
            _realBet, _salt)) == _bets[msg.sender]._hiddenBet, "Error: Provided invalid input: Abort");
        
        _bets[msg.sender]._realBet = _realBet;
        _bets[msg.sender]._isValid = true;
    }
    
    function evaluateWinner() external{
        require(_bets[_adr_playerA]._isValid && _bets[_adr_playerB]._isValid, 
            "Error: Players did not provide their real bet");
        
        if (keccak256(abi.encode(_bets[_adr_playerA]._realBet)) == keccak256(abi.encode(_bets[_adr_playerA]._realBet))){
            _winner = _adr_playerA;
        }else if (keccak256(abi.encode(_bets[_adr_playerA]._realBet)) != keccak256(abi.encode(_bets[_adr_playerA]._realBet))) {
            _winner = _adr_playerB;
        }
        
        // Emit event
        emit WinnerAnnounced(_winner);
    }
    
   
    function withdraw() external{
        // Checks
        require(msg.sender == _winner, "You are not the winner!");
        
        // Change smart contract state
        _locked = 0;
        _winner = address(0);
        _playersJoined = 0;
        _bets[_adr_playerA] = Bet("",bytes32(0), false);
        _bets[_adr_playerB] = Bet("",bytes32(0), false);
        _adr_playerA = address(0);
        _adr_playerB = address(0);
        
        // Reward transfer
        (bool success, ) = msg.sender.call{value: 2 ether}("");
        require(success, "Error: Withdraw unsuccessful");
        
        // Emmit event
        emit NewGame("New game spots available");
        
    }
  
}

