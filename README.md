# CTF_challenge_Mar2024

## Challenge Details

The `Game.sol` contract runs a card battle game where the goal is to get the flag by pitching your deck of Avatars against the deck of the flagholder and win the fight. Here's how it works:

* Anyone can join the game by calling `game.join()`
* When you join, you get a deck of 3 pseudo-random Avatars.
* Each Avatar is an NFT, and has powers like FIRE; WATER; AIR and SPEED, each with a value in a range from [0-9].
* You can swap your Avatars with others or trade one for a randomly generated new one.
* If you want to swap, someone else has to offer one of their Avatars for sale.
* One player always has the flag, and others can try to capture it by challenging the flag holder.
* A fight between two Avatars takes place with one of the 3 elements (FIRE, WATER, or AIR). The Avatar with the highest value in that element wins the fight. If two Avatars have the same strength, the Avatar with the most SPEED wins. If two Avatars are exactly the same, the flag holder wins.
* A fight between two decks consists of pairing the three Avatars of the challenger with the three Avatars of the flag holder, pseudo-randomly choosing three elements, and then having the three pairs fight on each of these elements.

## Goal

The `Game.sol` is deployed with the flagHolder holding an unbeatable deck with perfect Avatars.

Your mission is to obtain the flag: i.e. `game.flagHolder()` should return an address that you control
