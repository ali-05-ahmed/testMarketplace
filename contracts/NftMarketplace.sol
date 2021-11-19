// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./Auction.sol";


contract NftMarketplace is ReentrancyGuardUpgradeable {
    
  uint256 private tokenId;
    
  using Counters for Counters.Counter;
  Counters.Counter private _itemIds;
  Counters.Counter private _itemsSold;

  address payable owner;
  uint256 listingPrice ;
  // company's cut in each transfer
    uint256 public companyCut;

  Auction auction ;
  
  function initialize(address auctionContract)public initializer{
    owner = payable(msg.sender);
    listingPrice = 0.025 ether;
    companyCut = 20; 
    auction =Auction(auctionContract);
  }

  struct MarketItem {
    uint itemId;
    address nftContract;
    uint256 tokenId;
    address payable seller;
    address payable owner;
    uint256 price;
    bool sold;
    bool _auction;
  }
  
  mapping(address=> mapping(uint256=>bool)) private NFTexist;
  mapping(uint256 => MarketItem) private idToMarketItem;
  

  event MarketItemCreated (
    uint indexed itemId,
    address indexed nftContract,
    uint256 indexed tokenId,
    address seller,
    address owner,
    uint256 price,
    bool sold,
    bool _auction
  );

  //change price if auction is not in progress
  function setPrice(uint256 _itemId , uint256 _price) public {
    require(msg.sender==idToMarketItem[_itemId].seller, "Invalid owner");
    require(idToMarketItem[_itemId]._auction == false , " Auction in progress");
    idToMarketItem[_itemId].price=_price;
  }

  /* Returns the listing price of the contract */
  function getNftPrice(uint256 _itemId) public view returns (uint256) {
    return idToMarketItem[_itemId].price;
  }
  
  /* Places an item for sale on the marketplace */
  function createMarketItem(
    address nftContract,
    uint256 tokenId,
    uint256 price,
    bool _auction,
    uint256 _seconds
  ) public payable nonReentrant {
    require(NFTexist[nftContract][tokenId] == false, "NFT already Exist on the market");
    require(price > 0, "Price must be at least 1 wei");
  //  require(msg.value == listingPrice, "Price must be equal to listing price");
  NFTexist[nftContract][tokenId] = true;
  if(_auction == true)
  auction.createAuction(price, _seconds , nftContract, tokenId, msg.sender);
   
    _itemIds.increment();
    uint256 itemId = _itemIds.current();
  
    idToMarketItem[itemId] =  MarketItem(
      itemId,
      nftContract,
      tokenId,
      payable(msg.sender),
      payable(address(0)),
      price * 1 wei,
      false,
      _auction
    );

    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

    emit MarketItemCreated(
      itemId,
      nftContract,
      tokenId,
      msg.sender,
      address(0),
      price,
      false,
      _auction
    );
  }

  function startAuction(uint256 itemId,uint256 _endingUnix)public {
    MarketItem memory item = idToMarketItem[itemId];
require(item._auction==false,"auction in progress");
require(NFTexist[item.nftContract][item.tokenId]==true , "NFT Dont Exist on market place");
auction.createAuction(item.price, _endingUnix , item.nftContract, item.tokenId, msg.sender);
item._auction==true;
  }

  /* Creates the sale of a marketplace item */
  /* Transfers ownership of the item, as well as funds between parties */
  function createMarketSale(
    address nftContract,
    uint256 itemId
    ) public payable nonReentrant {
      uint price;
      uint tokenId = idToMarketItem[itemId].tokenId;
      address payable buyer;
    if(idToMarketItem[itemId]._auction == true){
           require(auction._checkAuctionStatus(tokenId,nftContract) == false , "Auction in progress cant pay");
           (buyer,price) = auction.getBidWinner(tokenId,nftContract);
          require(buyer == msg.sender , "Faulty buyer");
          require(msg.value == price && price > 0, "Please submit the asking price in order to complete the purchase");
          auction.concludeAuction(tokenId,nftContract);
          idToMarketItem[itemId]._auction = false;
    }
     else{
    price = idToMarketItem[itemId].price;
    require(msg.value == price, "Please submit the asking price in order to complete the purchase");  
     }
  
    idToMarketItem[itemId].seller.transfer(msg.value);
    IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
    idToMarketItem[itemId].owner = payable(msg.sender);
    idToMarketItem[itemId].sold = true;
    NFTexist[nftContract][tokenId] = false;
    _itemsSold.increment();
    //payable(owner).transfer(listingPrice);
  }

  /* Returns all unsold market items */
  function fetchMarketItems() public view returns (MarketItem[] memory) {
    uint itemCount = _itemIds.current();
    uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
    uint currentIndex = 0;

    MarketItem[] memory items = new MarketItem[](unsoldItemCount);
    for (uint i = 0; i < itemCount; i++) {
      if (idToMarketItem[i + 1].owner == address(0)) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  /* Returns onlyl items that a user has purchased */
  function fetchMyNFTs() public view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == msg.sender) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  /* Returns only items a user has created */
  function fetchItemsCreated() public view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].seller == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].seller == msg.sender) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }
}
