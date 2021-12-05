// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Platform.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Proposal is ERC1155Holder, Ownable {
    using SafeMath for uint256;

    string public title;
    string public content;
    Platform public _token = Platform(0x52C84043CD9c865236f11d9Fc9F56aa003c1f922);
    // ERC20 public GOV = ERC20(0x6FD3810Ab88700606237C3DF21Ce74D486517dCE);

    uint256 public id;
    // uint256 public requiredAmountToVote;
    uint256 public accepted;
    uint256 public rejected;
    uint256 public totalVoteCount;
    uint256 public createdAt = block.timestamp;
    uint256 public votingStartsAt;
    uint256 public votingClosesAt;
    uint256 public softcapPeriod;
    uint256 public softcapPercentage;
    mapping (address => uint256) public votes;
    address[] private _uniqueVoters;
    mapping (address => uint256) public supporters;
    address[] private _uniqueSupporters;
    uint256 public totalSupported;
    bool public isProposalValid = true;

    modifier softcapPeriodIsActive() {
        require(block.timestamp < votingStartsAt, "Proposal started to be voted.");
        _;
    }

    modifier votingIsActive() {
        require(block.timestamp >= votingStartsAt && block.timestamp < votingClosesAt, "Outside of voting period.");
        require(isProposalValid == true, "Proposal is invalid");
        if(totalSupported < calculateRequiredAmount()) {
            _fundBackSupporters();
            isProposalValid = false;
        }
        _;
    }

    modifier votingIsClosed() {
        require(block.timestamp > votingClosesAt, "Voting is not closed yet.");
        _;
    }

    modifier isNotMintAccount() {
        require(msg.sender != _token.getMintOwner(id), "Owner cannot vote.");
        _;
    }

    modifier hasVoted() {
        require(votes[msg.sender] > 0, "You must use vote to close proposal");
        _;
    }

    modifier hasSupported() {
        require(supporters[msg.sender] > 0, "You have to support to distribute back");
        _;
    }

    /*modifier mustSupplyRequiredAmount(uint256 amount) {
        require(amount >= requiredAmountToVote, "Given amount is less than required amount to vote");
        _;
    }*/
    uint256 requiredAmountToCreate = 1;

    constructor(
        uint256 id_,
        string memory title_,
        string memory content_,
        uint256 softcapPeriod_,
        uint256 votingPeriod_
        // uint256 requiredAmountToVote_
    ) {
        require(_token.balanceOf(msg.sender, id_) >= requiredAmountToCreate, "You dont have enough to create proposal");
        id = id_;
        title = title_;
        content = content_;
        softcapPeriod = softcapPeriod_;
        votingStartsAt = block.timestamp.add(softcapPeriod_ * 1 days);
        votingClosesAt = block.timestamp.add(votingPeriod_.add(softcapPeriod_) * 1 days);
        // requiredAmountToVote = requiredAmountToVote_;
        softcapPercentage = _token.getSoftcapPercentage(id);
    }

    function giveVote(uint256 amount, bool choice) public votingIsActive isNotMintAccount {
        if(isProposalValid == true) {
            // To make sure every voter is stored uniquely.
            // No duplicate value exists.
            if(votes[msg.sender] == 0) {
                _uniqueVoters.push(msg.sender);
            }

            if(choice) {
                votes[msg.sender] = votes[msg.sender].add(amount);
                accepted = accepted.add(amount);
            } else {
                votes[msg.sender] = votes[msg.sender].add(amount);
                rejected = rejected.add(amount);
            }
            
            totalVoteCount = totalVoteCount.add(amount);
            // GOV.transfer(address(this), 1);
            _token.safeTransferFrom(msg.sender, address(this), id, amount, "0x0");
        }
    }

    function supportProposal(uint256 amount) public softcapPeriodIsActive isNotMintAccount {
        // To make sure every supporter is stored uniquely.
        // No duplicate value exists.
        if(supporters[msg.sender] == 0) {
            _uniqueSupporters.push(msg.sender);
        }

        supporters[msg.sender] = supporters[msg.sender].add(amount);
        totalSupported = totalSupported.add(amount);
        // uint256 fee = 1 * 10 ** 18;
        // GOV.approve(address(this),amount);
        // GOV.transferFrom(msg.sender, address(this), fee);
        _token.safeTransferFrom(msg.sender, address(this), id, amount, "0x0");
    }

    function fundBackVoters() public hasVoted votingIsClosed {
        for(uint256 i = 0; i < _uniqueVoters.length; i++) {
            _token.safeTransferFrom(address(this), _uniqueVoters[i], id, votes[_uniqueVoters[i]], "0x0");
        }
    }

    /*function fundBackSupporters() public hasSupported votingIsActive {
        for(uint256 i = 0; i < _uniqueSupporters.length; i++) {
            _token.safeTransferFrom(address(this), _uniqueSupporters[i], id, supporters[_uniqueSupporters[i]], "0x0");
        }
    }*/

    function _fundBackSupporters() private {
        for(uint256 i = 0; i < _uniqueSupporters.length; i++) {
            _token.safeTransferFrom(address(this), _uniqueSupporters[i], id, supporters[_uniqueSupporters[i]], "0x0");
        }
        delete _uniqueSupporters;
    }

    function calculateRequiredAmount() public view returns (uint256) {
        return _token.getCirculatingSupply(id).mul(softcapPercentage).div(100);
    }
}