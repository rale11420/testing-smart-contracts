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
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Ticket is ERC721Enumerable, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter public Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public constant MAX_TICKETS_PER_USER = 1;
    uint256 public constant PRICE = 0.01 ether;

    constructor() ERC721("ERC721","ERC721") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address receiver) public onlyRole(MINTER_ROLE){
        uint256 tokenId = Counter.current();
        Counter.increment();
        _safeMint(receiver, tokenId);
    }

    function burn(uint256 tokenId) public {
        require(msg.sender == ownerOf(tokenId));
        _burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256) pure override internal {
        require(from == address(0) || to == address(0), "Soulbound token");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TicketingService is Ownable, ReentrancyGuard {
    Ticket immutable ticketContract;
    
    uint8 public constant MAX_TICKETS_PER_BATCH = 4;

    event NewTicket(address indexed receiver);
    event Refund(address indexed ticketOwner);

    constructor(address ticketContractAddress) {
        ticketContract = Ticket(ticketContractAddress);
    }

    function mintTicket(address receiver) public payable {
        require(receiver != address(0));
        
        require(ticketContract.balanceOf(receiver) <= ticketContract.MAX_TICKETS_PER_USER(), "One ticket per address allowed");

        ticketContract.mint(receiver);

        emit NewTicket(receiver);
    }

    function mintBatch(address[] memory receivers) public payable {
        //require(msg.value >= receivers.length * PRICE);
        for(uint256 i = 0; i < MAX_TICKETS_PER_BATCH; i++) {
            require(receivers[i] != address(0));
            require(ticketContract.balanceOf(receivers[i]) <= ticketContract.MAX_TICKETS_PER_USER(), "One ticket per address allowed");

            ticketContract.mint(receivers[i]);

            emit NewTicket(receivers[i]);
        }
    }

    function refundTicket(uint256 tokenId) public {
        require(msg.sender == ticketContract.ownerOf(tokenId));
        
        ticketContract.burn(tokenId);

        (bool sent, ) = msg.sender.call{value: ticketContract.PRICE()}("");
        require(sent);

        emit Refund(msg.sender);
    }

    function withdraw() public onlyOwner {
        uint amount = address(this).balance;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent);
    }
}