// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract TestFoundersAlphaSeederz is ERC721, Ownable, ReentrancyGuard {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost = 0.01 ether;
  uint256 public maxSupply = 963;
  uint256 public maxMintAmountPerTx = 9;

  bool public paused = true;
  bool public revealed = false;

  uint256 public presalePrice = 0.005; // Precio preventa
  uint256 public presaleSupply = 99; // Cantidad de piezas disponibles en preventa
  uint256 public presaleMaxUnits = 6; // Unidades máximas por transacción en preventa

  bool public presaleActive; // Booleano para activar o desactivar la preventa
  uint256 public presaleUnitsSold; // Variable para verificar si la preventa está activa o no



  constructor() ERC721("TestFoundersAlphaSeederz", "TFAS") {
    setHiddenMetadataUri("ipfs://bafybeihtgcurq5ud72eq3llzssv276axyuf72qdlqgvccfwxauktca4ywy/hidden_metadata.json");
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current().add(_mintAmount) <= maxSupply, "Max supply exceeded!");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }
  
  
  function setPresaleStatus(bool _presaleActive) public onlyOwner {
    presaleActive = _presaleActive;
  }

  function presaleMint(uint256 _mintAmount) public payable nonReentrant {
    require(presaleActive, "La preventa no esta activa");
    require(presaleUnitsSold.add(_mintAmount) <= presaleSupply, "La cantidad de piezas disponibles en preventa ha sido superada");
    require(msg.value >= presalePrice.mul(_mintAmount), "Fondos insuficientes");
    require(_mintAmount <= presaleMaxUnits, "Se ha superado el limite maximo de unidades por transaccion");

    _mintLoop(msg.sender, _mintAmount);
    presaleUnitsSold += _mintAmount;
  }
     
  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) nonReentrant {
    require(!paused, "The contract is paused!");
    require(msg.value >= cost.mul(_mintAmount), "Insufficient funds!");

    _mintLoop(msg.sender, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner {
    //(bool hs, ) = payable(0x943590A42C27D08e3744202c4Ae5eD55c2dE240D).call{value: address(this).balance * 5 / 100}("");
    //require(hs);
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
   }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}