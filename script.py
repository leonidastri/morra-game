import hashlib

def main():
    print("------------Morra game (A smart contract)------------\n")
    print("Instructions for the Morra game:\n")
    print("Phase 1: You have to send to the contract the HASHED_PICK and HASHED_GUESS string to hide your pick and guess number.")
    print("Phase 2: You have to send to the contract the UNHASHED_PICK and UNHASHED_GUESS string to reveal your pick and guess number.")
    print("Phase 3: Check if you are the winner!\n")    
    print("* This script is used to help you create UNHASHED_MOVE and HASHED_MOVE strings to join the game.")
    print("*UNHASHED_MOVE is a string <[1-5]><[1-5]><string>.")
    print("*HASH_MOVE is the hash value of UNHASHED_MOVE using sha256.\n")

    numbers = ["1","2","3","4","5"]
    while(True):
        pick = input("Pick one number from 1 to 5: ")
        if (pick in numbers):
            break;
        else:
            print("Wrong Value!")

    while(True):
        guess = input("Guess one number from 1 to 5: ")
        if (guess in numbers):
            break;
        else:
            print("Wrong Value!")
    
    s = input("Give a string of arbitrary length to append to UNHASHED_MOVE: ")
    
    unhashedMove = pick + guess + s;
    print("\nYour UNHASHED_MOVE is equal to your pick + guess + string of arbitrary length.\n")

    hashedMove = "0x" + hashlib.sha256(unhashedMove.encode()).hexdigest()

    print("\nUse the following in reveal function:")
    print("pick: ", pick);
    print("guess: ", guess);
    print("salt: ", string);
    print("HASHED_MOVE:", hashedMove)

    print("\nUse HASHED_MOVE in \"makeMove\" function.")
    print("Use UNHASHED_MOVE in \"revealMove\" function.")

main()
