// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Campaign
 * @dev Contract for individual fundraising campaigns
 */
contract Campaign is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Campaign details
    address public creator;
    address public platformWallet;
    address public usdtToken;
    string public title;
    string public description;
    uint256 public goal;
    uint256 public endTime;
    uint256 public platformFeePercentage;
    uint256 public percentageBase;
    bool public paused;
    
    // Campaign statistics
    uint256 public totalDonations;
    uint256 public totalWithdrawn;
    uint256 public donorCount;
    
    // Mapping to track donations by address
    mapping(address => uint256) public donations;
    
    // Array to store all donor addresses
    address[] public donors;

    // Events
    event DonationReceived(address indexed donor, uint256 amount, uint256 timestamp);
    event FundsWithdrawn(address indexed recipient, uint256 amount, uint256 platformFee, uint256 timestamp);
    event CampaignPaused(bool paused);

    // Modifiers
    modifier onlyCreator() {
        require(msg.sender == creator, "Only campaign creator can call this function");
        _;
    }

    modifier onlyPlatform() {
        require(msg.sender == platformWallet, "Only platform wallet can call this function");
        _;
    }

    modifier campaignActive() {
        require(!paused, "Campaign is paused");
        require(block.timestamp < endTime, "Campaign has ended");
        _;
    }

    /**
     * @dev Constructor sets up the campaign
     * @param _creator Address of the campaign creator
     * @param _platformWallet Address that will receive platform fees
     * @param _usdtToken Address of the USDT token contract
     * @param _title Campaign title
     * @param _description Campaign description
     * @param _goal Funding goal in USDT (with 6 decimals)
     * @param _duration Duration of the campaign in days
     * @param _platformFeePercentage Platform fee percentage
     * @param _percentageBase Base for percentage calculation
     */
    constructor(
        address _creator,
        address _platformWallet,
        address _usdtToken,
        string memory _title,
        string memory _description,
        uint256 _goal,
        uint256 _duration,
        uint256 _platformFeePercentage,
        uint256 _percentageBase
    ) {
        creator = _creator;
        platformWallet = _platformWallet;
        usdtToken = _usdtToken;
        title = _title;
        description = _description;
        goal = _goal;
        endTime = block.timestamp + (_duration * 1 days);
        platformFeePercentage = _platformFeePercentage;
        percentageBase = _percentageBase;
        paused = false;
    }

    /**
     * @dev Allows a user to donate USDT to the campaign
     * @param _amount Amount of USDT to donate (with 6 decimals)
     */
    function donate(uint256 _amount) external nonReentrant campaignActive {
        require(_amount > 0, "Donation amount must be greater than 0");
        
        // Transfer USDT from donor to campaign contract
        IERC20(usdtToken).safeTransferFrom(msg.sender, address(this), _amount);
        
        // Update donation records
        if (donations[msg.sender] == 0) {
            donors.push(msg.sender);
            donorCount++;
        }
        
        donations[msg.sender] += _amount;
        totalDonations += _amount;
        
        // Emit event
        emit DonationReceived(msg.sender, _amount, block.timestamp);
    }

    /**
     * @dev Allows the creator to withdraw funds
     * @param _amount Amount to withdraw (with 6 decimals)
     */
    function withdraw(uint256 _amount) external nonReentrant onlyCreator {
        uint256 availableToWithdraw = totalDonations - totalWithdrawn;
        require(_amount > 0 && _amount <= availableToWithdraw, "Invalid withdrawal amount");
        
        // Calculate platform fee
        uint256 platformFee = (_amount * platformFeePercentage) / percentageBase;
        uint256 creatorAmount = _amount - platformFee;
        
        // Update withdrawal records
        totalWithdrawn += _amount;
        
        // Transfer funds
        if (platformFee > 0) {
            IERC20(usdtToken).safeTransfer(platformWallet, platformFee);
        }
        IERC20(usdtToken).safeTransfer(creator, creatorAmount);
        
        // Emit event
        emit FundsWithdrawn(creator, creatorAmount, platformFee, block.timestamp);
    }

    /**
     * @dev Allows the platform to pause/unpause the campaign
     * @param _paused New paused state
     */
    function setPaused(bool _paused) external onlyPlatform {
        paused = _paused;
        emit CampaignPaused(_paused);
    }

    /**
     * @dev Returns campaign details
     * @return Campaign details as a tuple
     */
    function getCampaignDetails() external view returns (
        address, string memory, string memory, uint256, uint256, uint256, uint256, bool
    ) {
        return (
            creator,
            title,
            description,
            goal,
            totalDonations,
            totalWithdrawn,
            endTime,
            paused
        );
    }

    /**
     * @dev Returns the donation amount for a specific donor
     * @param _donor Address of the donor
     * @return Donation amount
     */
    function getDonationAmount(address _donor) external view returns (uint256) {
        return donations[_donor];
    }

    /**
     * @dev Returns all donors
     * @return Array of donor addresses
     */
    function getAllDonors() external view returns (address[] memory) {
        return donors;
    }

    /**
     * @dev Checks if the campaign has ended
     * @return True if the campaign has ended
     */
    function hasEnded() external view returns (bool) {
        return block.timestamp >= endTime;
    }

    /**
     * @dev Checks if the campaign has reached its goal
     * @return True if the campaign has reached its goal
     */
    function goalReached() external view returns (bool) {
        return totalDonations >= goal;
    }

    /**
     * @dev Returns the available balance to withdraw
     * @return Available balance
     */
    function getAvailableBalance() external view returns (uint256) {
        return totalDonations - totalWithdrawn;
    }
}
