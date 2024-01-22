// SPDX-License-Identifier: MIT
pragma  solidity ^0.8.4;

import  "@openzeppelin/contracts@4.6.0/token/ERC20/ERC20.sol";
import  "@openzeppelin/contracts@4.6.0/token/ERC721/IERC721.sol";
import  "@openzeppelin/contracts@4.6.0/access/Ownable.sol";
import  "@openzeppelin/contracts@4.6.0/token/ERC20/extensions/draft-ERC20Permit.sol";
import  "@openzeppelin/contracts@4.6.0/token/ERC721/utils/ERC721Holder.sol";

contract FractionalizedNFT is ERC20, Ownable, ERC20Permit, ERC721Holder {
    struct FractionalizedNFTInfo {
        IERC721 collection;
        uint256 tokenId;
        bool initialized;
        bool forSale;
        uint256 salePrice;
        bool canRedeem;
    }

    mapping(uint256 => FractionalizedNFTInfo) public fractionalizedNFTs;

    constructor() ERC20("EGEMONEY", "EGEM") ERC20Permit("MYEGEM") {}



    function initialize(address _collection,address nft_owner, uint256 _tokenId, uint256 _amount) external onlyOwner {
    require(_amount > 0, "Amount needs to be more than 0");

    IERC721 collection = IERC721(_collection);
    require(!fractionalizedNFTs[_tokenId].initialized, "NFT already initialized");

    collection.safeTransferFrom(nft_owner, address(this), _tokenId);

    fractionalizedNFTs[_tokenId] = FractionalizedNFTInfo({
        collection: collection,
        tokenId: _tokenId,
        initialized: true,
        forSale: false,
        salePrice: 0,
        canRedeem: false
    });

    _mint(nft_owner, _amount);
}

    function putForSale(uint256 _nftId, uint256 _price) external onlyOwner {
        FractionalizedNFTInfo storage nftInfo = fractionalizedNFTs[_nftId];
        require(nftInfo.initialized, "NFT not initialized");
        nftInfo.salePrice = _price;
        nftInfo.forSale = true;
    }

    function purchase(uint256 _nftId) external payable {
        FractionalizedNFTInfo storage nftInfo = fractionalizedNFTs[_nftId];
        require(nftInfo.forSale, "NFT not for sale");
        require(msg.value >= nftInfo.salePrice, "Not enough funds sent");

        nftInfo.collection.transferFrom(address(this), msg.sender, nftInfo.tokenId);
        nftInfo.forSale = false;
        nftInfo.canRedeem = true;
    }

    function redeem(uint256 _nftId, uint256 _amount) external {
        FractionalizedNFTInfo storage nftInfo = fractionalizedNFTs[_nftId];
        require(nftInfo.canRedeem, "Redemption not available");

        uint256 totalCelo = address(this).balance;
        uint256 toRedeem = (_amount * totalCelo) / totalSupply();
        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(toRedeem);
    }
}