pragma solidity >=0.4.22 <0.7.0;

// Implementation of Morra game
contract Morra {

    struct Player {
        address payable playerAddress;
        bytes32 hashedMove;
        uint256 pick;
        uint256 guess;
        uint256 amount;
    }

    Player[2] private players;
    
    // Amount of ether to play game
    uint256 private constant stake = 10 ether;
    // withdraw counter is integer from 0 up to 2
    uint256 private withdrawCounter;
    // Reveal revealStarted
    bool private revealStarted;
    // Time when first reveal occured
    uint private timeCounter;
    // Result of game is calculated
    bool private resultCalculated;
    uint private constant timeout = 120;
    
    event Play(address player, uint256 amount);
    event Commit(address player, bytes32 message);
    event Reveal(address player);
    event Withdraw(address player, uint256 amount);
    
    constructor () public {
        revealStarted = false;
        withdrawCounter = 0;
        resultCalculated = false;
    }
    
    // ***DO NOT FORGET TO HASH YOUR MOVE***
    
    // Hash your move locally without sending pick and guess number in network (safeguard for front-running)
    function hashYourMove(uint256 pick, uint256 guess, string memory salt) public pure returns(bytes32) {
        require(pick>=1 && pick<=5, "Pick a number from 1 to 5");
        require(guess>=1 && guess<=5, "Guess a number from 1 to 5");
        require(bytes(salt).length>0, "Give a string of length > 0 for a more secure hash.");
        return sha256(abi.encodePacked(pick, guess, salt));
    }
    
    // ***JOIN***    
    
    // Join Morra game
    function join() public payable {
        require(msg.sender != players[0].playerAddress && msg.sender != players[1].playerAddress,
                "You are already playing Morra game.");
        require(players[0].playerAddress == address(0x0) || players[1].playerAddress == address(0x0),
                "Morra game is full.");
        require(withdrawCounter==0, "Both players need to withdraw before starting new game!");
        require(msg.value==stake, "You need to pay 10 Ether to play Morra game.");
        
        if (players[0].playerAddress == address(0x0)) {
            players[0].playerAddress = msg.sender;
        } else if (players[1].playerAddress == address(0x0)) {
            players[1].playerAddress = msg.sender;
        }
        emit Play(msg.sender,msg.value);
    }
    
    //  ***COMMIT***
     
    // Check if player has joined Morra game
    modifier validPlayer() {
        require(msg.sender==players[0].playerAddress || msg.sender==players[1].playerAddress,
                "You do not have access to Morra game.");
        _;
    }

    // Player commits move
    function commit(bytes32 hashedMove) public validPlayer {
        if (msg.sender == players[0].playerAddress) {
            require(players[0].hashedMove==0x0,
                    "You have already made a move");
            players[0].hashedMove = hashedMove;
        } else if (msg.sender == players[1].playerAddress) {
            require(players[1].hashedMove==0x0,
                    "You have already made a move.");
            players[1].hashedMove = hashedMove;
        }
        emit Commit(msg.sender,hashedMove);
    }
    
    //  ***REVEAL***
    
    // Player reveals move
    function reveal(uint256 pick, uint256 guess, string memory salt) public validPlayer {
        require(players[0].hashedMove!=0x0 && players[1].hashedMove!=0x0,
                "Not all players have committed.");
        bytes32 hashedMove = sha256(abi.encodePacked(pick,guess,salt));
        require (pick>=1 && pick<=5 && guess>=1 && guess<=5,
                 "You tried to fool the game. Your picked or guessed number is not from 1 to 5");
        if (msg.sender == players[0].playerAddress) {
            require(players[0].pick==0 && players[0].guess==0,
                    "You have already revealed move.");
            require(players[0].hashedMove == hashedMove,
                    "Hashing your revealed move does not match the saved hashed move.");
            players[0].pick = pick;
            players[0].guess = guess;
        } else if (msg.sender == players[1].playerAddress) {
            require(players[1].pick==0 && players[1].guess==0,
                    "You have already revealed your move.");
            require(players[1].hashedMove == hashedMove,
                    "Hashing your revealed move does not match the saved hashed move.");
            players[1].pick = pick;
            players[1].guess = guess;
        }
        
        if (revealStarted == false) {
            revealStarted = true;
            timeCounter = now;
        }
        emit Reveal(msg.sender);
    }
    
    //  ***RESULT***

    // Calculate result of Morra game
    function result() public {
        require(!resultCalculated, "Result has been calculated yet.");
        //Check if players have revealed or timeout passed
        require((players[0].pick!=0 && players[1].pick!=0 && players[0].guess!=0 && players[1].guess!=0) ||
                ((now > timeCounter + timeout) && revealStarted),
                "Cannot calculate result and withdraw. Not all players revealed or timeout has not passed yet since first reveal.");        
        //if player1 does not reveal on time loses bet as a penalty
        if (players[0].pick==0) {
            players[1].amount = address(this).balance;
            players[0].amount = 0;
        //if player2 does not reveal on time loses bet as a penalty
        } else if (players[1].pick==0) {
            players[0].amount = address(this).balance;
            players[1].amount = 0;
        // if both players guess right
        } else if (players[0].guess==players[1].pick && players[1].guess==players[0].pick) {
            players[0].amount = stake;
            players[1].amount = stake;
        // if only player1 guesses right
        } else if (players[0].guess==players[1].pick) {
            // calculations are SAFE FOR OVERFLOW as stake 5 ether
            // and pick from 1 to 10 and has been checked in previous function
            players[0].amount = stake + (players[0].pick + players[1].pick) * (10 ether);
            players[1].amount =  stake - (players[0].pick + players[1].pick) * (10 ether);
        // if only player2 guesses right
        } else if (players[1].guess==players[0].pick) {
            // calculations are SAFE FOR OVERFLOW as stake 5 ether
            // and pick from 1 to 10 and has been checked in previous function
            players[1].amount = stake + (players[0].pick + players[1].pick) * (10 ether);
            players[0].amount = stake - (players[0].pick + players[1].pick) * (10 ether);
        //both players guessed wrong
        } else {
            players[0].amount = stake;
            players[1].amount = stake;
        }
        
        resultCalculated = true;
    }
    
    //  ***WITHDRAW***
    
    // Withdraw amount of Ether (PULL)
    function calculateResultAndWithdraw() validPlayer public {
                
        require(resultCalculated, "Result has not been calculated yet.");
        
        uint256 amount;
        address payable player;
        if (msg.sender==players[0].playerAddress) {
            amount = players[0].amount;
            player = players[0].playerAddress;
            // reentrancy attack protector
            players[0].playerAddress = address(0x0);
            players[0].hashedMove = 0x0;
            players[0].pick = 0;
            players[0].guess = 0;
            players[0].amount = 0;
        } else if (msg.sender==players[1].playerAddress) {
            amount = players[1].amount;
            player = players[1].playerAddress;
            players[1].playerAddress = address(0x0);
            players[1].hashedMove = 0x0;
            players[1].pick = 0;
            players[1].guess = 0;
            players[1].amount = 0;
        }
        player.transfer(amount);
        
        // withdraw takes values from 0 to 2 (no overflow/underflow possible)
        withdrawCounter += 1;
        
        // If both players have withdrawn, initialize variables to play again
        if (withdrawCounter==2) {
            revealStarted = false;
            timeCounter = 0;
            resultCalculated = false;
            withdrawCounter = 0;
        }
    }
}
