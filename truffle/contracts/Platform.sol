// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Proposal.sol";

contract Platform is ERC1155, Ownable {
    using SafeMath for uint256;
    mapping (uint256 => uint256) private _softcapPercentages;
    mapping (uint256 => uint256) private _totalSupplies;
    mapping (uint256 => address) private _mintOwners;
    mapping (uint256 => address[]) public publishedProposals;

    constructor() ERC1155("") {
    }
    
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function getSoftcapPercentage(uint256 id) public view returns (uint256) {
        return _softcapPercentages[id];
    }

    function setSoftcapPercentage(uint256 id, uint256 softcapPercentage) public onlyOwner {
        _softcapPercentages[id] = softcapPercentage;
    }

    function getCirculatingSupply(uint256 id) public view returns (uint256) {
        return _totalSupplies[id] - balanceOf(_mintOwners[id], id);
    }

    function _increaseTotalSupply(uint256 id, uint256 amount) private {
        _totalSupplies[id] = _totalSupplies[id].add(amount);
    }

    function _decreaseTotalSupply(uint256 id, uint256 amount) private {
        _totalSupplies[id] = _totalSupplies[id].sub(amount);
    }
    
    function getMintOwner(uint256 id) public view returns (address) {
        return _mintOwners[id];
    }
    
    function addProposal(uint256 id, address contractAddress) public {
        Proposal published = Proposal(contractAddress);
        if(published.owner() == msg.sender) {
            if(_doesItInclude(id, contractAddress) == false) {
                address[] storage arr = publishedProposals[id];
                arr.push(contractAddress);
            }
        }
    }

    function getProposalLength(uint256 id) public view returns(uint256) {
        return publishedProposals[id].length;
    }

    function getProposalAddress(uint256 id, uint256 index) public view returns(address) {
        for(uint256 i=0; i<publishedProposals[id].length; i++) {
            if(i == index) {
                address addr = publishedProposals[id][index];
                return addr;
            }
        }

        return 0x0000000000000000000000000000000000000000;
    }

    function _doesItInclude(uint256 id, address proposal) private view returns (bool) {
        for(uint256 i=0; i<publishedProposals[id].length; i++) {
            if(publishedProposals[id][i] == proposal) {
                return true;
            }
        }

        return false;
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
        _increaseTotalSupply(id, amount);
        _mintOwners[id] = account;
    }

    function burn(address account, uint256 id, uint256 value) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
        _decreaseTotalSupply(id, value);
    }
}
