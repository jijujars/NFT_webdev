// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMarketplace is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _listingIds;

    struct Listing {
        uint256 listingId;
        address nftContract;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool active;
    }

    // Mapping from listingId to Listing
    mapping(uint256 => Listing) private _listings;
    // Mapping from seller to their proceeds
    mapping(address => uint256) private _proceeds;

    event ListingCreated(
        uint256 indexed listingId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        uint256 price
    );
    event ListingUpdated(uint256 indexed listingId, uint256 newPrice);
    event ListingCancelled(uint256 indexed listingId);
    event NFTSold(
        uint256 indexed listingId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address buyer,
        uint256 price
    );

    function createListing(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external nonReentrant returns (uint256) {
        require(price > 0, "Price must be greater than zero");
        require(
            IERC721(nftContract).ownerOf(tokenId) == msg.sender,
            "Not the owner"
        );
        require(
            IERC721(nftContract).getApproved(tokenId) == address(this),
            "NFT not approved"
        );

        _listingIds.increment();
        uint256 listingId = _listingIds.current();

        _listings[listingId] = Listing({
            listingId: listingId,
            nftContract: nftContract,
            tokenId: tokenId,
            seller: msg.sender,
            price: price,
            active: true
        });

        emit ListingCreated(listingId, nftContract, tokenId, msg.sender, price);
        return listingId;
    }

    function updateListing(uint256 listingId, uint256 newPrice) external {
        require(newPrice > 0, "Price must be greater than zero");
        Listing storage listing = _listings[listingId];
        require(listing.active, "Listing not active");
        require(listing.seller == msg.sender, "Not the seller");

        listing.price = newPrice;
        emit ListingUpdated(listingId, newPrice);
    }

    function cancelListing(uint256 listingId) external {
        Listing storage listing = _listings[listingId];
        require(listing.active, "Listing not active");
        require(listing.seller == msg.sender, "Not the seller");

        listing.active = false;
        emit ListingCancelled(listingId);
    }

    function buyNFT(uint256 listingId) external payable nonReentrant {
        Listing storage listing = _listings[listingId];
        require(listing.active, "Listing not active");
        require(msg.value == listing.price, "Incorrect price");
        require(msg.sender != listing.seller, "Seller cannot be buyer");

        listing.active = false;
        _proceeds[listing.seller] += msg.value;

        IERC721(listing.nftContract).safeTransferFrom(
            listing.seller,
            msg.sender,
            listing.tokenId
        );

        emit NFTSold(
            listingId,
            listing.nftContract,
            listing.tokenId,
            listing.seller,
            msg.sender,
            listing.price
        );
    }

    function getListing(uint256 listingId)
        external
        view
        returns (Listing memory)
    {
        return _listings[listingId];
    }

    function getProceeds(address seller) external view returns (uint256) {
        return _proceeds[seller];
    }

    function withdrawProceeds() external nonReentrant {
        uint256 proceeds = _proceeds[msg.sender];
        require(proceeds > 0, "No proceeds to withdraw");

        _proceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        require(success, "Transfer failed");
    }
} 