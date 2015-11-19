# FourInARow: Using the GameplayKit Minmax Strategist for Opponent AI

This sample demonstrates how to use the GKMinmaxStrategist class to implement a computer-controlled opponent for turn-based, adversarial games. As part of this demonstration, the sample shows how to structure gameplay model code for use with the minmax strategist using the GKGameModel protocol and related APIs.

## Playing the Game

Tap in a column to drop a chip of your color there. (Red moves first, Black moves second.) Get four chips in a row -- horizontally, vertically, or diagonally -- to win.

## Building a Game Model

This project builds a game in stages:
1. The `AAPLBoard` and `AAPLPlayer` classes implement a generic model for a Four-In-A-Row game. Use the `FourInARowTests` unit test case to exercise the generic game model.
2. The `AAPLViewController` class adds a UI for playing the game on an iOS device. With the `USE_AI_PLAYER` macro left undefined, the game is for two human players.
3. The classes and categories in `AAPLMinmaxStrategy.h` and `AAPLMinmaxStrategy.m` extend the generic game model to support using GameplayKit for opponent AI. 
4. With the `USE_AI_PLAYER` macro defined, the `AAPLViewController` class replaces user control for the second player (black chips) with an AI opponent using the `GKMinmaxStrategist` class.

For a more thorough discussion of this project, see the chapter "The Minmax Strategist" in [GameplayKit Programming Guide][1].

[1]: https://developer.apple.com/library/prerelease/ios/documentation/General/Conceptual/GameplayKit_Guide/index.html

## Requirements

### Build

Xcode 7.0, iOS 9.0

### Runtime

iOS 9.0

Copyright (C) 2015 Apple Inc. All rights reserved.
