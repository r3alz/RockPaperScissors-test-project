// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RockPaperScissors {
    
    address public player1;
    address public player2;
    address public player1CreditGame;
    address public player2CreditGame;
    string player1Choice;
    string player2Choice;
    string player1ChoiceCreditGame;
    string player2ChoiceCreditGame;
    uint public amountBid;
    uint public totalBid;
    uint public amountBidCreditGame;
    uint public totalBidCreditGame;
    
    
    // keeps track of the amount that a player has bid + their winnings
    mapping (address => uint) public balances;
    // used to see if player is already in a public game or a plubic credit game
    mapping (address => bool) public inGame;
    
    // required in order to playPublicGame()
    modifier isOpen() {
        require(player1 == address(0) || player2 == address(0), "game is full"); // allows player to join if player1 or player2 have not joined
        require((player1 != address(0) && msg.value == amountBid) || player1 == address(0), "you must pay the amountBid by player1 to play"); // player1 sets bid amount. If player1 already joined and set bid amount then player2 can join and matches the amount
        _;
    }
    
    // require both players to have a different address
    modifier isDifferentAddress() {
        require(player1 != address(0) && player1 != msg.sender || player1 == address(0), "you must have a different address than player1");
        _;
    }
    
    // Make sure the players are making the right choice - They must choose one of the following: "Rock", "Paper", "Scissors", "rock", "paper", or "scissors"
    modifier isCorrectChoice(string memory choice) {
        require(keccak256(bytes(choice)) ==  keccak256(bytes("Rock")) ||
                keccak256(bytes(choice)) ==  keccak256(bytes("Scissors")) ||
                keccak256(bytes(choice)) ==  keccak256(bytes("Paper")) ||
                keccak256(bytes(choice)) ==  keccak256(bytes("rock")) ||
                keccak256(bytes(choice)) ==  keccak256(bytes("paper")) ||
                keccak256(bytes(choice)) ==  keccak256(bytes("scissors")),
                "Your choice must be one of the following: Rock, Paper, Scissors, rock, paper, or scissors"
        );
        _;
    }
    
    // required in order to playPublicGameWithCredits
    modifier isOpenCreditGame(uint creditBid) {
        require(player1CreditGame == address(0) || player2CreditGame == address(0), "game is full"); // allows player to join if player1CreditGame or player2CreditGame have not joined
        require((player1CreditGame != address(0) && (msg.value == amountBidCreditGame || creditBid * 10**18 == amountBidCreditGame)) || player1CreditGame == address(0), "you must pay the amountBid by player1 to play"); // player1CreditGame sets bid amount. If player1CreditGame already joined and set bid amount then player2CreditGame can join and matches the amount
        _;
    }
    
    // require both players to have a different address
    modifier isDifferentAddressCreditGame() {
        require(player1CreditGame != address(0) && player1CreditGame != msg.sender || player1CreditGame == address(0), "you must have a different address than player1"); 
        _;
    }
    
    modifier isInGame() {
        require(inGame[msg.sender] != true, "You are currently in a game already");
        _;
    }
    
    
    function playPublicGame(string memory choice) public payable isOpen isDifferentAddress isCorrectChoice(choice) isInGame {
        if (player1 == address(0)) {
            player1 = msg.sender;
            inGame[msg.sender] = true;
            player1Choice = choice;
            amountBid = msg.value;
            balances[msg.sender] += msg.value;
            totalBid += msg.value;
        } else {
            player2 = msg.sender;
            inGame[msg.sender] = true;
            player2Choice = choice;
            balances[msg.sender] += msg.value;
            totalBid += msg.value;
        }
        
        if (player1 != address(0) && player2 != address(0)) {
            completeGame(player1Choice, player2Choice);
        }
    }
    
    
    function playPublicGameWithCredits(string memory choice, uint creditBid) public payable isOpenCreditGame(creditBid) isDifferentAddressCreditGame isCorrectChoice(choice) isInGame {
        require((balances[msg.sender] > 0 && creditBid > 0) || creditBid <= 0, "If you don't have a balance you must send ether from wallet");
        if (player1CreditGame == address(0)) {
            player1CreditGame = msg.sender;
            inGame[msg.sender] = true;
            player1ChoiceCreditGame = choice;
            if (creditBid > 0) {
                balances[msg.sender] -= creditBid * 10**18;
                amountBidCreditGame = creditBid * 10**18;
                totalBidCreditGame += amountBidCreditGame;
            } else {
                amountBidCreditGame = msg.value;
                balances[msg.sender] += msg.value;
                totalBidCreditGame += msg.value;
            }
        } else {
            player2CreditGame = msg.sender;
            inGame[msg.sender] = true;
            player2ChoiceCreditGame = choice;
            if (creditBid > 0) {
                balances[msg.sender] -= creditBid * 10**18;
                amountBidCreditGame = creditBid * 10**18;
                totalBidCreditGame += amountBidCreditGame;
            } else {
                amountBidCreditGame = msg.value;
                balances[msg.sender] += msg.value;
                totalBidCreditGame += msg.value;
            }
        }
        if (player1CreditGame != address(0) && player2CreditGame != address(0)) {
            completeCreditGame(player1ChoiceCreditGame, player2ChoiceCreditGame);
        }
    }
    
    function completeGame(string memory choice1, string memory choice2) private {
        if (keccak256(bytes(choice1)) == keccak256(bytes("Rock")) && keccak256(bytes(choice2)) == keccak256(bytes("Scissors")) || 
            keccak256(bytes(choice1)) == keccak256(bytes("Paper")) && keccak256(bytes(choice2)) == keccak256(bytes("Rock")) ||
            keccak256(bytes(choice1)) == keccak256(bytes("Scissors")) && keccak256(bytes(choice2)) == keccak256(bytes("Paper")) ||
            keccak256(bytes(choice1)) == keccak256(bytes("rock")) && keccak256(bytes(choice2)) == keccak256(bytes("scissors")) || 
            keccak256(bytes(choice1)) == keccak256(bytes("paper")) && keccak256(bytes(choice2)) == keccak256(bytes("rock")) ||
            keccak256(bytes(choice1)) == keccak256(bytes("scissors")) && keccak256(bytes(choice2)) == keccak256(bytes("paper"))) 
        {
            balances[player1] += amountBid;
            balances[player2] -= amountBid;
        } else if (keccak256(bytes(choice2)) == keccak256(bytes("Rock")) && keccak256(bytes(choice1)) == keccak256(bytes("Scissors")) || 
            keccak256(bytes(choice2)) == keccak256(bytes("Paper")) && keccak256(bytes(choice1)) == keccak256(bytes("Rock")) ||
            keccak256(bytes(choice2)) == keccak256(bytes("Scissors")) && keccak256(bytes(choice1)) == keccak256(bytes("Paper")) ||
            keccak256(bytes(choice2)) == keccak256(bytes("rock")) && keccak256(bytes(choice1)) == keccak256(bytes("scissors")) || 
            keccak256(bytes(choice2)) == keccak256(bytes("paper")) && keccak256(bytes(choice1)) == keccak256(bytes("rock")) ||
            keccak256(bytes(choice2)) == keccak256(bytes("scissors")) && keccak256(bytes(choice1)) == keccak256(bytes("paper"))) 
        {
            balances[player2] += amountBid;
            balances[player1] -= amountBid;
        } 
        
        resetRegularGame();
    }
    
    function completeCreditGame(string memory choice1, string memory choice2) private {
        if (keccak256(bytes(choice1)) == keccak256(bytes("Rock")) && keccak256(bytes(choice2)) == keccak256(bytes("Scissors")) || 
            keccak256(bytes(choice1)) == keccak256(bytes("Paper")) && keccak256(bytes(choice2)) == keccak256(bytes("Rock")) ||
            keccak256(bytes(choice1)) == keccak256(bytes("Scissors")) && keccak256(bytes(choice2)) == keccak256(bytes("Paper")) ||
            keccak256(bytes(choice1)) == keccak256(bytes("rock")) && keccak256(bytes(choice2)) == keccak256(bytes("scissors")) || 
            keccak256(bytes(choice1)) == keccak256(bytes("paper")) && keccak256(bytes(choice2)) == keccak256(bytes("rock")) ||
            keccak256(bytes(choice1)) == keccak256(bytes("scissors")) && keccak256(bytes(choice2)) == keccak256(bytes("paper"))) 
        {
            balances[player1CreditGame] += totalBidCreditGame;
        } else if (keccak256(bytes(choice2)) == keccak256(bytes("Rock")) && keccak256(bytes(choice1)) == keccak256(bytes("Scissors")) || 
            keccak256(bytes(choice2)) == keccak256(bytes("Paper")) && keccak256(bytes(choice1)) == keccak256(bytes("Rock")) ||
            keccak256(bytes(choice2)) == keccak256(bytes("Scissors")) && keccak256(bytes(choice1)) == keccak256(bytes("Paper")) ||
            keccak256(bytes(choice2)) == keccak256(bytes("rock")) && keccak256(bytes(choice1)) == keccak256(bytes("scissors")) || 
            keccak256(bytes(choice2)) == keccak256(bytes("paper")) && keccak256(bytes(choice1)) == keccak256(bytes("rock")) ||
            keccak256(bytes(choice2)) == keccak256(bytes("scissors")) && keccak256(bytes(choice1)) == keccak256(bytes("paper"))) 
        {
            balances[player2CreditGame] += totalBidCreditGame;
        } 
        
        resetCreditGame();
    }
    
    function withdrawBalance() public {
        require(balances[msg.sender] > 0, "you have no balance");
        address _to = msg.sender;
        (bool sent,) = _to.call{value: balances[_to]}("");
        require(sent, "Failed to send Ether");
        
        if (msg.sender == player1) {
            resetRegularGame();
        } else if (msg.sender == player1CreditGame) {
            resetCreditGame();
        }
    }
    
    function resetRegularGame() private {
        inGame[player1] = false;
        inGame[player2] = false;
        player1 = address(0);
        player2 = address(0);
        amountBid = 0;
        totalBid = 0;
        player1Choice = "";
        player1Choice = "";
    }
    
    function resetCreditGame() private {
        inGame[player1CreditGame] = false;
        inGame[player2CreditGame] = false;
        player1CreditGame = address(0);
        player2CreditGame = address(0);
        amountBidCreditGame = 0;
        totalBidCreditGame = 0;
        player1ChoiceCreditGame = "";
        player1ChoiceCreditGame = "";
    }
}