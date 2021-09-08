pragma solidity ^0.6.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Game is Ownable{
    //game host address
    address payable gameHostAddress;
    //bid address
    address payable [10] public bidAddressArray;
    //current bid address pos
    uint public pos;
    //fund
    uint fund;
    //bid value
    uint public bidValue;
    //game status
    bool public openForBidding;
    // deadline for current bid
    uint public deadline;
    // interval
    uint public interval;
    // game id
    uint public gameId;
    // jackpot id
    uint public jackpotId;
    
    //events
    event NewCurrentBidAddress(address bidAddress, uint pos, uint jackpot, uint deadline, uint gameId, uint jackpotId);
    event GameEnded(address winnerAddress, uint jackpot, uint gameId, uint jackpotId, uint endType);
    event GameStarted(uint jackpot, uint deadline, uint gameId, uint jackpotId);
    event DeadlineExtended(uint deadline, uint gameId, uint jackpotId);
    
    
    constructor(
        uint bidValue_,
        address payable gameHostAddress_,
        uint interval_,
        uint gameId_
        ) public payable {
        gameHostAddress = gameHostAddress_;
        fund = msg.value;
        bidValue = bidValue_;
        interval = interval_;
        deadline = now + 5 * interval_;
        pos = 9;
        openForBidding = true;
        gameId = gameId_;
        jackpotId = 1;
        emit GameStarted(getJackpot(), deadline, gameId, jackpotId);
    }
    
    function bid() external payable {
        require(msg.value == bidValue);
        require(openForBidding == true);
        require(now <= deadline);

        fund += msg.value;
        pos++;
        if(pos > 9){
            pos = 0;
        }
        bidAddressArray[pos] = msg.sender;

        deadline = now + interval;
        
        emit NewCurrentBidAddress(bidAddressArray[pos], pos, getJackpot(), deadline, gameId, jackpotId);
        
    }

    function restart(
        uint bidValue_,
        address payable gameHostAddress_,
        uint interval_
        ) external payable onlyOwner {
        require(openForBidding == false);

        gameHostAddress = gameHostAddress_;
        fund = fund + msg.value;
        bidValue = bidValue_;
        interval = interval_;
        deadline = now + 5 * interval_;
        pos = 9;
        jackpotId++;
        openForBidding = true;
        
        emit GameStarted(getJackpot(), deadline, gameId, jackpotId);
    }

    function end(uint endType) external onlyOwner {
        address payable winner = bidAddressArray[pos]; 
        if(winner == address(0)){
            return;
        }
        openForBidding = false;

        uint jackpot = getJackpot();
        uint commission = getCommission(); 
        uint nextGameFund = fund * 1/10; 

        fund = fund - jackpot; 
        fund = fund - commission;
        fund = fund - nextGameFund;

        winner.transfer(jackpot);
        
        gameHostAddress.transfer(commission);        
        
        uint consolationFees = fund * 1/9;
        
        if(consolationFees > bidValue){
            consolationFees = bidValue;
        }
        for(uint i = 0; i < 10; i ++){
            if(bidAddressArray[i] == address(0)){
                continue;
            }
            if(i != pos){
                bidAddressArray[i].transfer(consolationFees);
                fund = fund - consolationFees;
                bidAddressArray[i] = address(0);
            }
        }

        emit GameEnded(winner, jackpot, gameId, jackpotId, endType);
        bidAddressArray[pos] = address(0);
        pos = 9;
    }


    function getBidAddressArray() public view returns( address payable [10] memory){
        return bidAddressArray;
    }

    function getJackpot() public view returns(uint) {
        return fund * 6/10;
    }  
    
    function getCommission() public view onlyOwner returns(uint) {
        return fund * 1/10;
    }   

    function getBalanceContract() external view onlyOwner returns(uint) {
        return address(this).balance;
    }

    function extendDeadline() external onlyOwner{
        deadline = now + 5 * interval;
        emit DeadlineExtended(deadline, gameId, jackpotId);
    }

    function destroy() external onlyOwner {
        selfdestruct(gameHostAddress);
    }

    function withdraw(uint amount) external onlyOwner {
        require(amount <= address(this).balance);
        gameHostAddress.transfer(amount);
        fund = fund - amount;
    }

    function clear() external onlyOwner {
        gameHostAddress.transfer(address(this).balance);
        fund = 0;
    }    
   
}