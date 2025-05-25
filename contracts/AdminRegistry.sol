// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title AdminRegistry
 * @dev Contract for managing admin roles and permissions
 */
contract AdminRegistry is Ownable2Step {
    // Mapping of addresses to admin status
    mapping(address => bool) public admins;
    
    // Total number of admins
    uint256 public adminCount;
    
    // Events
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    
    /**
     * @dev Constructor sets the initial admin(s)
     * @param _initialAdmins Array of initial admin addresses
     */
    constructor(address[] memory _initialAdmins) Ownable(msg.sender) {
        for (uint256 i = 0; i < _initialAdmins.length; i++) {
            if (_initialAdmins[i] != address(0) && !admins[_initialAdmins[i]]) {
                admins[_initialAdmins[i]] = true;
                adminCount++;
                emit AdminAdded(_initialAdmins[i]);
            }
        }
    }
    
    /**
     * @dev Add a new admin
     * @param _admin Address to add as admin
     */
    function addAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Admin cannot be zero address");
        require(!admins[_admin], "Address is already an admin");
        
        admins[_admin] = true;
        adminCount++;
        
        emit AdminAdded(_admin);
    }
    
    /**
     * @dev Remove an admin
     * @param _admin Address to remove from admins
     */
    function removeAdmin(address _admin) external onlyOwner {
        require(admins[_admin], "Address is not an admin");
        
        admins[_admin] = false;
        adminCount--;
        
        emit AdminRemoved(_admin);
    }
    
    /**
     * @dev Check if an address is an admin
     * @param _address Address to check
     * @return Boolean indicating if the address is an admin
     */
    function isAdmin(address _address) external view returns (bool) {
        return admins[_address];
    }
    
    /**
     * @dev Modifier to restrict function access to admins only
     */
    modifier onlyAdmin() {
        require(admins[msg.sender] || msg.sender == owner(), "Caller is not an admin or owner");
        _;
    }
}
