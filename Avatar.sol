// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract Game is ERC721 {

  uint256 public totalSupply; // total amount of avatars available

  uint8 constant WATER = 0;
  uint8 constant AIR = 1;
  uint8 constant FIRE = 2;
  uint8 constant DECK_SIZE = 3;

  uint256 private nonce = 123; // nonce used by pseudo-random generator


  // an avatar has 4 attributes
  struct avatar {
    uint8 water;
    uint8 air;
    uint8 fire;
    uint8 speed;
  }

  // a mapping from ids to avatars
  mapping(uint256 => avatar) public avatars;

  // a mapping from players to their decks
  mapping(address => uint256[DECK_SIZE]) public decks;

  // a mapping from ids of avatars to booleans - if true, the avatar is for sale
  mapping(uint256 => bool) public forSale;

  // address of the flag holder
  address public flagHolder;

  constructor() ERC721("Hats Game 1", "HG1") {
    // create an unbeatable superdeck for the deployer
    avatar memory superavatar = avatar(9,9,9,9);
    flagHolder = msg.sender;
    for (uint8 i; i < DECK_SIZE; i++) {
      decks[flagHolder][i] = _mintavatar(flagHolder, superavatar);
    }
  }

  // join the game and receive `DECK_SIZE` random avatars
  function join() external returns (uint256[DECK_SIZE] memory deck) {
    address newPlayer = msg.sender;
    require(balanceOf(newPlayer) == 0, "player already joined");

    // give the new player DECK_SIZE pseudorandom avatars
    deck[0] = _mintavatar(newPlayer);
    deck[1] = _mintavatar(newPlayer);
    deck[2] = _mintavatar(newPlayer);

    decks[newPlayer] = deck;
  }

  // fight the flagHolder with your deck
  function fight() external {
    address attacker = msg.sender;
    address opponent = flagHolder;
    uint256[DECK_SIZE] memory deck0 = decks[attacker];
    uint256[DECK_SIZE] memory deck1 = decks[opponent];

    for (uint8 i = 0; i < DECK_SIZE; i++) {
      uint8 element = randomGen(3);
      // if the first player wins, burn the avatar of the second player
      if (_fight(deck0[i], deck1[i], element)) {
        _burn(deck1[i]);
      } else {
        _burn(deck0[i]);
      }
    }

    // winner is the player with most avatars left
    if (balanceOf(attacker) > balanceOf(opponent)) {
        flagHolder = attacker;
    }

    // replenish balance of both players so they can play again
    uint256[DECK_SIZE] memory deckAttacker = decks[attacker];
    uint256[DECK_SIZE] memory deckOpponent = decks[opponent];
    for (uint i; i < DECK_SIZE; i++) {
      if (!_exists(deckAttacker[i])) {
        deckAttacker[i] = _mintavatar(attacker);
      }
      if (!_exists(deckOpponent[i])) {
        deckOpponent[i] = _mintavatar(opponent);
      }
    }

    decks[attacker] = deckAttacker;
    decks[opponent] = deckOpponent;
  }

  // fight _avatar0 against _avatar1 in element _element
  function _fight(uint256 _avatar0, uint256 _avatar1, uint8 _element) internal view returns(bool) {
    assert(_element < 3);
    avatar memory avatar0;
    avatar memory avatar1;

    avatar0 = avatars[_avatar0];
    avatar1 = avatars[_avatar1];

    if (_element == WATER) {
      if (avatar0.water > avatar1.water) {
        return true;
      } else if (avatar0.water < avatar1.water) {
        return false;
      } else {
        return avatar0.speed > avatar1.speed;
      }
    } else if (_element == AIR) {
      if (avatar0.air > avatar1.air) {
        return true;
      } else if (avatar0.air < avatar1.air) {
        return false;
      } else {
        return avatar0.speed > avatar1.speed;
      }
    } else if (_element == FIRE) {
      if (avatar0.fire > avatar1.fire) {
        return true;
      } else if (avatar0.fire < avatar1.fire) {
        return false;
      } else {
        return avatar0.speed > avatar1.speed;
      }
    }
  }

  // put a avatar up for sale
  function putUpForSale(uint256 _avatarId) external {
    require(ownerOf(_avatarId) == msg.sender, "Can only put your own avatars up for sale");
    forSale[_avatarId] = true;
  }

  // swap your avatar with _avatarId1 for a avatar with _avatarId2 that is for sale and owned by _to
  function swap(address _to, uint256 _avatarId1, uint256 _avatarId2) external {
    address swapper = msg.sender;
    require(forSale[_avatarId2], "Cannot swap an avatar that is not for sale");
    require(swapper != _to, "Cannot swap a avatar with yourself");

    // @audit Got side-effect in transfer if receiver is contract.
    // Got reentrancy through side effect.
    _safeTransfer(swapper, _to, _avatarId1, "");
    _safeTransfer(_to, swapper, _avatarId2, "");

    //Update the decks
    uint256 idx1 = indexInDeck(swapper, _avatarId1);
    uint256 idx2 = indexInDeck(_to, _avatarId2);
    decks[swapper][idx1] = _avatarId2;
    decks[_to][idx2] = _avatarId1;

    // @audit forSale is not set to false after swap.

  }

  function indexInDeck(address _owner, uint256 _avatarId) internal view returns(uint256 idx) {
    for (uint256 i; i < DECK_SIZE; i++) {
      if (decks[_owner][i] == _avatarId) {
        idx = i;
      }
    }

  }

  function swapForNewavatar(uint256 _avatarId) external {
    address swapper = msg.sender;
    require(ownerOf(_avatarId) == swapper, "Can only swap your own avatar for a new avatar");
    uint256 idx = indexInDeck(swapper, _avatarId);
    _burn(_avatarId);
    decks[swapper][idx] = _mintavatar(swapper);
  }

  function _mintavatar(address _to, avatar memory avatar) internal returns(uint256) {
    uint256 tokenId = totalSupply;
    totalSupply += 1;
    avatars[tokenId] = avatar;
    _mint(_to, tokenId);
    return tokenId;
  }

  function _mintavatar(address _to) internal returns(uint256) {
    avatar memory newavatar = genavatar();
    return _mintavatar(_to, newavatar);
  }

  // generate a new avatar
  function genavatar() private returns (avatar memory newavatar) {
    // generate a new avatar
    uint8 fire = randomGen(10);
    uint8 water = randomGen(10);
    uint8 air = randomGen(10);
    uint8 speed = randomGen(10);
    newavatar = avatar(fire, water, air, speed);
  }

  // function that generates pseudorandom numbers
  function randomGen(uint256 i) private returns (uint8) {
    uint8 x = uint8(uint256(keccak256(abi.encodePacked(block.number, msg.sender, nonce))) % i);
    nonce++;
    return x;
  }

   function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
      // disable transferFrom - the only way to obtain a new avatar is by swapping
      require(false, "transfers of avatars are disabled");
    }

     function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
      // disable transferFrom - the only way to obtain a new avatar is by swapping
      require(false, "transfers of avatars are disabled");

    }

}
