// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Campaign.sol";
import "./AdminRegistry.sol";

/**
 * @title CampaignFactory
 * @dev Factory contract for creating individual campaign contracts
 */
contract DeFiAidCampaignFactory is Ownable2Step {
    using SafeERC20 for IERC20;

    // Platform fee percentage (2.9% = 290 / 10000)
    uint256 public platformFeePercentage = 290;
    uint256 public constant PERCENTAGE_BASE = 10000;

    // Platform wallet address
    address public platformWallet;

    // USDT token address
    address public usdtToken;
    
    // Admin registry contract
    AdminRegistry public adminRegistry;

    // Array to store all campaign addresses
    address[] public campaigns;

    // Mapping from campaign address to creator address
    mapping(address => address) public campaignToCreator;

    // Mapping from creator address to their campaigns
    mapping(address => address[]) public creatorToCampaigns;
    
    // Mapping to track KYC verified creators
    mapping(address => bool) public kycVerifiedCreators;

    // Events
    event CampaignCreated(
        address indexed campaignAddress,
        address indexed creator,
        string title,
        uint256 goal,
        uint256 duration
    );
    event PlatformFeeUpdated(uint256 newFeePercentage);
    event PlatformWalletUpdated(address newPlatformWallet);
    event USDTTokenUpdated(address newUsdtToken);
    event AdminRegistryUpdated(address newAdminRegistry);
    event CreatorKYCVerified(address indexed creator, bool verified);

    /**
     * @dev Constructor sets the platform wallet, USDT token address, and admin registry address
     * @param _platformWallet Address that will receive platform fees
     * @param _usdtToken Address of the USDT token contract
     * @param _adminRegistry Address of the existing AdminRegistry contract
     */
    constructor(
        address _platformWallet, 
        address _usdtToken,
        address _adminRegistry
    ) Ownable(msg.sender) {
        require(_platformWallet != address(0), "Platform wallet cannot be zero address");
        require(_usdtToken != address(0), "USDT token cannot be zero address");
        require(_adminRegistry != address(0), "Admin registry cannot be zero address");
        
        platformWallet = _platformWallet;
        usdtToken = _usdtToken;
        adminRegistry = AdminRegistry(_adminRegistry);
    }

    /**
     * @dev Modifier to restrict function access to admins only
     */
    modifier onlyAdmin() {
        require(adminRegistry.isAdmin(msg.sender) || msg.sender == owner(), "Caller is not an admin or owner");
        _;
    }
    
    /**
     * @dev Creates a new campaign contract
     * @param _title Campaign title
     * @param _description Campaign description
     * @param _goal Funding goal in USDT (with 6 decimals)
     * @param _duration Duration of the campaign in days
     * @return Address of the newly created campaign
     */
    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _goal,
        uint256 _duration
    ) external returns (address) {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(_goal > 0, "Goal must be greater than 0");
        require(_duration > 0, "Duration must be greater than 0");
        require(kycVerifiedCreators[msg.sender], "Creator must be KYC verified");

        // Create new campaign contract
        Campaign newCampaign = new Campaign(
            msg.sender,
            platformWallet,
            usdtToken,
            _title,
            _description,
            _goal,
            _duration,
            platformFeePercentage,
            PERCENTAGE_BASE
        );

        address campaignAddress = address(newCampaign);

        // Store campaign data
        campaigns.push(campaignAddress);
        campaignToCreator[campaignAddress] = msg.sender;
        creatorToCampaigns[msg.sender].push(campaignAddress);

        // Emit event
        emit CampaignCreated(
            campaignAddress,
            msg.sender,
            _title,
            _goal,
            _duration
        );

        return campaignAddress;
    }

    /**
     * @dev Set KYC verification status for a creator
     * @param _creator Address of the creator
     * @param _verified Boolean indicating if the creator is verified
     */
    function setCreatorKYCStatus(address _creator, bool _verified) external onlyAdmin {
        require(_creator != address(0), "Creator cannot be zero address");
        kycVerifiedCreators[_creator] = _verified;
        emit CreatorKYCVerified(_creator, _verified);
    }
    
    /**
     * @dev Batch set KYC verification status for multiple creators
     * @param _creators Array of creator addresses
     * @param _verified Array of verification statuses
     */
    function batchSetCreatorKYCStatus(address[] calldata _creators, bool[] calldata _verified) external onlyAdmin {
        require(_creators.length == _verified.length, "Arrays must have the same length");
        for (uint256 i = 0; i < _creators.length; i++) {
            require(_creators[i] != address(0), "Creator cannot be zero address");
            kycVerifiedCreators[_creators[i]] = _verified[i];
            emit CreatorKYCVerified(_creators[i], _verified[i]);
        }
    }
    
    /**
     * @dev Updates the admin registry contract
     * @param _newAdminRegistry New admin registry contract address
     */
    function updateAdminRegistry(address _newAdminRegistry) external onlyOwner {
        require(_newAdminRegistry != address(0), "Admin registry cannot be zero address");
        adminRegistry = AdminRegistry(_newAdminRegistry);
        emit AdminRegistryUpdated(_newAdminRegistry);
    }

    /**
     * @dev Updates the platform fee percentage
     * @param _newFeePercentage New fee percentage (e.g., 290 for 2.9%)
     */
    function updatePlatformFee(uint256 _newFeePercentage) external onlyAdmin {
        require(_newFeePercentage <= 1000, "Fee cannot exceed 10%");
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeUpdated(_newFeePercentage);
    }

    /**
     * @dev Updates the platform wallet address
     * @param _newPlatformWallet New platform wallet address
     */
    function updatePlatformWallet(address _newPlatformWallet) external onlyAdmin {
        require(_newPlatformWallet != address(0), "Platform wallet cannot be zero address");
        platformWallet = _newPlatformWallet;
        emit PlatformWalletUpdated(_newPlatformWallet);
    }

    /**
     * @dev Updates the USDT token address
     * @param _newUsdtToken New USDT token address
     */
    function updateUsdtToken(address _newUsdtToken) external onlyAdmin {
        require(_newUsdtToken != address(0), "USDT token cannot be zero address");
        usdtToken = _newUsdtToken;
        emit USDTTokenUpdated(_newUsdtToken);
    }

    /**
     * @dev Returns the total number of campaigns
     * @return Number of campaigns
     */
    function getCampaignCount() external view returns (uint256) {
        return campaigns.length;
    }

    /**
     * @dev Returns all campaigns created by a specific creator
     * @param _creator Address of the creator
     * @return Array of campaign addresses
     */
    function getCampaignsByCreator(address _creator) external view returns (address[] memory) {
        return creatorToCampaigns[_creator];
    }

    /**
     * @dev Returns all campaigns
     * @return Array of campaign addresses
     */
    function getAllCampaigns() external view returns (address[] memory) {
        return campaigns;
    }
    
    /**
     * @dev Checks if a creator is KYC verified
     * @param _creator Address of the creator to check
     * @return Boolean indicating if the creator is KYC verified
     */
    function isKycVerified(address _creator) external view returns (bool) {
        return kycVerifiedCreators[_creator];
    }
}
