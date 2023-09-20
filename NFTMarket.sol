// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract NFTMarket is ERC721URIStorage, Ownable {
    struct NFTListing {
        uint256 price;
        address seller;
    }

    // struct MintTokenInfo {
    //     IERC20 paytoken;
    //     uint256 costvalue;
    // }
    struct TokenInfo {
        IERC20 paytoken;
        uint256 costvalue;
    }

    // struct PricesList {
    //     IERC20 tokenAddress;
    //     uint256 costvalue;
    // }
    // struct AuctionList {
    //     uint256 nftId;
    //     bool available;
    // }
    // AuctionList[] public arrAuctionList;

    TokenInfo[] public AllowedCrypto;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIDs;
    mapping(uint256 => NFTListing) public _listing;
    mapping(uint256 => address) public _firstOwnerOfNFT;
    mapping(uint256 => uint256[3]) public TokenPriceNFT;
    uint256 public listedNFT;
    uint256 tokenCount;

    event NFTTransfer(
        uint256 tokenID,
        address from,
        address to,
        string tokenURI,
        uint256 price
    );

    constructor() ERC721("Imran NFT Market", "INFT") {
        console.log("Constructor Run Sucessfully");

    }

    // 
    // Code for Rewad giving to the NFT uploader+++++++++++++++++++++++++++++++++++
    // 
    
    address public NftMarketCoin;

    function setNftMarketCoinAddress (address tokenAddress) public {
        NftMarketCoin = tokenAddress;
    }

    function sendNftCreatingReward() public {
        IERC20(NftMarketCoin).transfer(msg.sender, 20);
        console.log("Reward sent to the NFT creater");
    }

    function checkTokenBalance(address account) external view returns (uint256) {
        // Create an instance of the ERC20 token interface
        IERC20 token = IERC20(NftMarketCoin);

        // Call the balanceOf function of the ERC20 token contract
        return token.balanceOf(account);
    }

    // 
    // Code for Rewad giving to the NFT uploader Ends-----------------------------
    // 

    // function addCurrency(IERC20 _paytoken, uint256 _costvalue)
    //     public
    //     onlyOwner
    // {
    //     AllowedCrypto.push(
    //         MintTokenInfo({paytoken: _paytoken, costvalue: _costvalue})
    //     );
    //     tokenCount++;
    //     console.log("Add Currency Sucessfully");
    // }

    function addCurrency(
        IERC20 _paytoken,
        uint256 _costvalue
    ) public onlyOwner {
        AllowedCrypto.push(
            TokenInfo({
                paytoken: _paytoken,
                costvalue: _costvalue
            })
        );
    }

    // function addCurrency(IERC20 _paytoken, uint256 _costvalue) public onlyOwner {
//     function addCurrency(address _paytoken) public onlyOwner {
//     AllowedCrypto.push(
//         MintTokenInfo(
//             paytoken: _paytoken
//             costvalue: _costvalue
//         )
//     );
//     tokenCount++;
//     console.log("Currency Added Successfully");
// }

    function createNFT(string calldata tokenURI) public {
        _tokenIDs.increment();
        uint256 currentID = _tokenIDs.current();
        _safeMint(msg.sender, currentID);
        _setTokenURI(currentID, tokenURI);
        _firstOwnerOfNFT[currentID] = msg.sender;
        sendNftCreatingReward();
        // bool auctionAvailable = false;
        // AuctionList memory newObjectList = AuctionList(currentID, auctionAvailable);
        // arrAuctionList.push(newObjectList);
        emit NFTTransfer(currentID, address(0), msg.sender, tokenURI, 0);
        // console.log("NFT created Sucessfully");
    }

    function listNFT(
        uint256 tokenID,
        uint256 price,
        uint256 token1P,
        uint256 token2P,
        uint256 token3P
    ) public {
        require(price > 0, "NFT Market: Price must be grater than 0");
        require(
            token1P > 0,
            "NFT Market: Price of Token 1 must be grater than 0"
        );
        require(
            token2P > 0,
            "NFT Market: Price of Token 2 must be grater than 0"
        );
        require(
            token3P > 0,
            "NFT Market: Price of Token 3 must be grater than 0"
        );
        address tokenOwner = ownerOf(tokenID);
        require(msg.sender == tokenOwner, "NFT Market: You are not the owner");

        // uint256[3] memory paramPrice = [token1P, token2P, token3P];

        // for (uint256 i = 0; i <= tokenCount; i++) {
        //     TokenPriceNFT[tokenID][i] = paramPrice[i];
        // }
        TokenPriceNFT[tokenID][0] = token1P;
        TokenPriceNFT[tokenID][1] = token2P;
        TokenPriceNFT[tokenID][2] = token3P;

        // console.log("Token 1 price", TokenPriceNFT[tokenID][0]);
        // console.log("Token 2 price", TokenPriceNFT[tokenID][1]);
        // console.log("Token 3 price", TokenPriceNFT[tokenID][2]);



        // TokenPriceNFT[msg.sender][] =
        listedNFT++;
        approve(address(this), tokenID);
        transferFrom(msg.sender, address(this), tokenID);
        _listing[tokenID] = NFTListing(price, msg.sender);
        string memory tokenURL = tokenURI(tokenID);
        emit NFTTransfer(tokenID, msg.sender, address(this), tokenURL, price);
        // console.log("NFT Listed Sucessfully");
    }

    function buyNFT(uint256 tokenID) public payable {
        NFTListing memory listing = _listing[tokenID];
        require(
            listing.seller != msg.sender,
            "NFT Market: You are the owner of this NFT, You can't buy it."
        );
        require(listing.price > 0, "NFT Market: NFT is not listed for sale");
        require(msg.value == listing.price, "NFT Markt: Incorrect Price");
        ERC721(address(this)).transferFrom(address(this), msg.sender, tokenID);
        // ERC721(address(this)).approve(msg.sender, tokenID);
        // transferFrom(address(this), msg.sender, tokenID);
        payable(listing.seller).transfer(listing.price.mul(80).div(100));
        payable(_firstOwnerOfNFT[tokenID]).transfer(
            listing.price.mul(10).div(100)
        );
        string memory tokenURL = tokenURI(tokenID);
        clearListing(tokenID);
        emit NFTTransfer(tokenID, address(this), msg.sender, tokenURL, 0);
        // console.log("NFT bought with ETH Sucessfully");

    }

    // To buy NFT with token you first need to approve the NFT contract to transfer ERC20 using transferFrom function from buyer to NFT smart contract and this approvel can be  done from the smart contract of ERC20
    function buyNFT_WtihToken(uint256 tokenID, uint256 priceTokenID_inArray)
        public
        payable
    {
        NFTListing memory listing = _listing[tokenID];
        require(listing.seller != msg.sender,"NFT Market: You are the owner of this NFT, You can't buy it.");
        require(listing.price > 0, "NFT Market: NFT is not listed for sale");
        TokenInfo memory tokens = AllowedCrypto[priceTokenID_inArray];
        IERC20 paytoken;
        paytoken = tokens.paytoken;

        uint256 cost;
        cost = TokenPriceNFT[tokenID][priceTokenID_inArray];
        console.log(cost, ":: Cost of token");
        // paytoken.allowance(msg.sender, address(this));
        paytoken.transferFrom(msg.sender,address(this), cost);
        
        // uint256 tokenPriceCheck = TokenPriceNFT[tokenID][priceTokenID_inArray];
        
        // require(msg.value == tokenPriceCheck, "NFT Markt: Incorrect Price");

        // TokenInfo memory tokens = AllowedCrypto[priceTokenID_inArray];
        // IERC20 paytoken;
        // paytoken = tokens.paytoken;

        ERC721(address(this)).transferFrom(address(this), msg.sender, tokenID);
        // paytoken.transferFrom(msg.sender, address(this), cost);
        // ERC721(address(this)).approve(msg.sender, tokenID);
        // transferFrom(address(this), msg.sender, tokenID);
        // payable(listing.seller).transfer(listing.price.mul(80).div(100));
        // payable(_firstOwnerOfNFT[tokenID]).transfer(
        //     listing.price.mul(10).div(100)
        // );
        // payable(listing.seller).transfer(listing.price.mul(80).div(100));

        paytoken.transferFrom(
            address(this),
            listing.seller,
            cost.mul(80).div(100)
        );
        paytoken.transferFrom(
            address(this),
            _firstOwnerOfNFT[tokenID],
            cost.mul(10).div(100)
        );

        string memory tokenURL = tokenURI(tokenID);
        clearListing(tokenID);
        emit NFTTransfer(tokenID, address(this), msg.sender, tokenURL, 0);
        // console.log("NFT bought with Token Sucessfully");
    }

    function cancelListing(uint256 tokenID) public {
        NFTListing memory listing = _listing[tokenID];
        require(listing.price > 0, "NFT Market: NFT is not listed for sale");
        require(
            listing.seller == msg.sender,
            "NFT Market: You are not the seller"
        );
        ERC721(address(this)).transferFrom(address(this), msg.sender, tokenID);
        clearListing(tokenID);
        string memory tokenURL = tokenURI(tokenID);
        emit NFTTransfer(tokenID, address(this), msg.sender, tokenURL, 0);
        // console.log("Listing Cancel Sucessfully");

    }
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "NFT Market: Balance is zero");
        payable(msg.sender).transfer(balance);
        console.log("Withdraw fund from contract Sucessfully");
    }

    function clearListing(uint256 tokenID) private {
        _listing[tokenID].price = 0;
        _listing[tokenID].seller = address(0);
        listedNFT--;
        // console.log("ReduceNFT count Sucessfully");
    }

    function currentId() public view returns (uint256) {
        return _tokenIDs.current();
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // 
    // Auction Code Start From There-------------------------------------
    // 

    
    uint256 public maxBid;
    address public latestBidder;
    uint256 public auctionNftID = 0;
    address public auctionNftOwner;
    uint256 public bidCount = 0;
    uint256 public deadline;
    // uint256 auctionNftCount = 0;
    // mapping (address => mapping(uint256 => bool)) public listedAuctionNft;

    function auctionNft(
        uint256 tokenID,
        uint256 minPrice,
        uint256 deadlineTime
    ) public {
        require(minPrice > 0, "NFT Market: Price must be grater than 0");
        address tokenOwner = ownerOf(tokenID);
        require(msg.sender == tokenOwner, "NFT Market: You are not the owner");
        require(deadlineTime > 0, "Your auction time is very small");
        deadline = block.timestamp + deadlineTime; // in unix form
        maxBid = minPrice;
        auctionNftOwner = msg.sender;
        auctionNftID = tokenID;
        // auctionNftCount++;
        // listedAuctionNft [msg.sender][tokenID] = true;
        approve(address(this), tokenID);
        transferFrom(msg.sender, address(this), tokenID);
        // _listing[tokenID] = NFTListing(price, msg.sender);
        string memory tokenURL = tokenURI(tokenID);
        emit NFTTransfer(tokenID, msg.sender, address(this), tokenURL, minPrice);
        console.log("NFT Listed Sucessfully");
    }

    function bidAuctionNft(uint256 tokenId, uint256 bidPrice) external {
        require(auctionNftID != 0, "Curretly no NFT is listed for Auction");
        require(msg.sender != auctionNftOwner, "You cannot Bid, because you are the owner");
        require(tokenId == auctionNftID, "This NFT is not listed for Auction");
        require(block.timestamp < deadline, "Deadline has passed");
        require(bidPrice > maxBid, "Your Bid price is low");
        maxBid = bidPrice;
        latestBidder = msg.sender;
        bidCount++;
    }

    function buyAuctionNft(uint256 tokenID) public payable {
        require(msg.sender == latestBidder, "You cannot Buy, because you are not the Highest Bidder");
        require(msg.value == maxBid, "Incorrect Price of auction NFT");
        require(tokenID == auctionNftID, "Auction NFT Id is not correct");
        require(block.timestamp > deadline, "Deadline has not passed yet");
        ERC721(address(this)).transferFrom(address(this), msg.sender, tokenID);
        payable(auctionNftOwner).transfer(maxBid.mul(80).div(100));
        console.log("Auction NFT bought with ETH Sucessfully");

    }

    

}