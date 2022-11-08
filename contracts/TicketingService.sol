// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

abstract contract Ownable {
    address public owner;

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Ticket is ERC721Enumerable {
    uint256 public constant MAX_TICKETS_PER_USER = 1;

    constructor() ERC721("ERC721","ERC721") {}

    function mint(address receiver) public {
        uint256 tokenId = totalSupply();
        _safeMint(receiver, tokenId);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256) pure override internal {
        require(from == address(0) || to == address(0), "Soulbound token");
    }

    function echidna_test_price() public view returns(bool) {
        return (MAX_TICKETS_PER_USER == 1);
    }
}

contract TicketingService is Ownable {
    Ticket immutable ticketContract;
    uint256 public constant PRICE = 0.01 ether;
    uint8 public constant MAX_TICKETS_PER_BATCH = 4;

    event NewTicket(address indexed receiver);
    event Refund(address indexed ticketOwner);

    constructor(/*address ticketContractAddress*/) {
        //ticketContract = Ticket(ticketContractAddress);
        ticketContract = Ticket(0x0AaCfbeC6a24756c20D41914F2caba817C0d8521);
    }

    function mintTicket(address receiver) public payable {
        require(msg.value >= PRICE, "Invalid price");
        require(ticketContract.balanceOf(receiver) <= ticketContract.MAX_TICKETS_PER_USER(), "One ticket per address allowed");

        ticketContract.mint(receiver);

        emit NewTicket(receiver);
    }

    function mintBatch(address[] memory receivers) public payable {
        for(uint256 i = 0; i < MAX_TICKETS_PER_BATCH; i++) {
            mintTicket(receivers[i]);
        }
    }

    function refundTicket(uint256 tokenId) public {
        require(msg.sender == ticketContract.ownerOf(tokenId));
        //(bool sent, ) = msg.sender.call{value: PRICE}("");
        payable(msg.sender).transfer(PRICE);
        ticketContract.burn(tokenId);
        
        emit Refund(msg.sender);
    }

    function echidna_test_price() public view returns(bool) {
        return (PRICE == 0.01 ether);
    }

    function echidna_test_max_tickets() public view returns(bool) {
        return (MAX_TICKETS_PER_BATCH == 4);
    }

    function echidna_test_contract_address() public view returns(bool) {
        return (ticketContract == Ticket(0x0AaCfbeC6a24756c20D41914F2caba817C0d8521));
    }

    function echidna_test_refund_ticket() public returns(bool) {
        uint _tokenId = 5;
        uint256 supply = ticketContract.totalSupply();
        refundTicket(_tokenId);
        return(supply == (ticketContract.totalSupply() - 1));
    }
    

    function echidna_test_mint_ticket() public returns(bool) {
        address _receiver = address(0x10000);
        uint256 balance = ticketContract.balanceOf(_receiver);
        mintTicket(_receiver);
        return(balance == (ticketContract.balanceOf(_receiver) + 1));
    }

    function echidna_test_mint_ticket_supply() public returns(bool) {
        address _receiver = address(0x10000);
        uint256 supply = ticketContract.totalSupply();
        mintTicket(_receiver);
        return(supply == (ticketContract.totalSupply() + 1));
    }
}