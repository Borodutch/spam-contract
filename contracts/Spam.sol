//    _
//  _| |_ _____ _____ _____ _____
// |   __|   __|  _  |  _  |     |
// |__   |__   |   __|     | | | |
// |_   _|_____|__|  |__|__|_|_|_|
//   |_|

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @custom:security-contact spam@bdut.ch
contract Spam is
  Initializable,
  ERC20Upgradeable,
  ERC20BurnableUpgradeable,
  ERC20PausableUpgradeable,
  OwnableUpgradeable,
  ERC20PermitUpgradeable,
  ERC20VotesUpgradeable,
  ERC20FlashMintUpgradeable,
  ReentrancyGuard
{
  // State
  uint256 public mintRate;
  uint256 public supplyCap;
  uint256 public amountMinted;
  address public spamGod;

  // spammer => ticketType => lastClaimTimestamp
  mapping(uint256 => mapping(uint256 => uint256)) public lastClaimTimestamps;

  // Events
  event MintRateSet(uint256 newMintRate);
  event SupplyCapSet(uint256 newSupplyCap);
  event SpamGodSet(address newSpamGod);
  event AteSpam(address indexed spammer);
  event PrayedToSpamGod(address indexed spammer);
  event ClaimedSpam(
    address indexed spammer,
    uint256 ticketType,
    uint256 amount,
    uint256 fromTimestamp,
    uint256 toTimestamp
  );

  function initialize(
    address initialOwner,
    string calldata name,
    string calldata symbol,
    uint256 premintAmount,
    uint256 initialMintRate,
    uint256 initialSupplyCap,
    address initialSpamGod
  ) public initializer {
    mintRate = initialMintRate;
    supplyCap = initialSupplyCap;
    spamGod = initialSpamGod;

    __ERC20_init(name, symbol);
    __ERC20Burnable_init();
    __ERC20Pausable_init();
    __Ownable_init(initialOwner);
    __ERC20Permit_init(name);
    __ERC20Votes_init();
    __ERC20FlashMint_init();

    _mint(initialOwner, premintAmount);
    amountMinted += premintAmount;
  }

  function setMintRate(uint256 newMintRate) public onlyOwner {
    mintRate = newMintRate;
    emit MintRateSet(newMintRate);
  }

  function setSupplyCap(uint256 newSupplyCap) public onlyOwner {
    supplyCap = newSupplyCap;
    emit SupplyCapSet(newSupplyCap);
  }

  function setSpamGod(address newSpamGod) public onlyOwner {
    spamGod = newSpamGod;
    emit SpamGodSet(newSpamGod);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function withdraw() public onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function mint() public payable nonReentrant {
    require(msg.value > 0, "No Ether sent");
    uint256 amountToMint = msg.value * mintRate;
    require(amountMinted + amountToMint <= supplyCap, "Supply cap exceeded");
    amountMinted += amountToMint;
    _mint(msg.sender, amountToMint);
  }

  function eatSpam() public {
    emit AteSpam(msg.sender);
  }

  function prayToSpamGod() public {
    emit PrayedToSpamGod(msg.sender);
  }

  function claimSpam(
    bytes calldata data,
    bytes32 r,
    bytes32 vs
  ) public nonReentrant {
    (address recoveredSpamGod, ECDSA.RecoverError ecdsaError, ) = ECDSA
      .tryRecover(MessageHashUtils.toEthSignedMessageHash(data), r, vs);
    require(
      ecdsaError == ECDSA.RecoverError.NoError,
      "Error while verifying the ECDSA signature"
    );
    require(
      recoveredSpamGod == spamGod,
      "You're praying to the wrong Spam God, beware!"
    );
    (
      uint256 spammer,
      uint256 ticketType,
      uint256 spamAmount,
      uint256 fromTimestamp,
      uint256 toTimestamp
    ) = abi.decode(data, (uint256, uint256, uint256, uint256, uint256));
    require(
      lastClaimTimestamps[spammer][ticketType] < fromTimestamp,
      "Back to the future! You're claiming a ticket from the past!"
    );
    _mint(msg.sender, spamAmount);
    lastClaimTimestamps[spammer][ticketType] = toTimestamp;
    emit ClaimedSpam(
      msg.sender,
      ticketType,
      spamAmount,
      fromTimestamp,
      toTimestamp
    );
  }

  // The following functions are overrides required by Solidity.

  function _update(
    address from,
    address to,
    uint256 value
  )
    internal
    override(ERC20Upgradeable, ERC20PausableUpgradeable, ERC20VotesUpgradeable)
  {
    super._update(from, to, value);
  }

  function nonces(
    address owner
  )
    public
    view
    override(ERC20PermitUpgradeable, NoncesUpgradeable)
    returns (uint256)
  {
    return super.nonces(owner);
  }
}
