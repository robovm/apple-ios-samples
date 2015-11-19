# AgentsCatalog: Using the Agents System in GameplayKit

Uses the Agents system in GameplayKit to let the characters in a game move themselves according to high-level goals. This sample demonstrates several of the individual goals that an agent can perform, such as moving to a target, avoiding obstacles, and following a predefined path. AgentsCatalog also shows how to tie multiple goals together to create more complex behaviors, such as making a group of agents seek a common target while moving together as a flock.

## Exploring the Catalog

Use the toolbar to switch between eight scenes, each of which demonstrates one or more of the goals available in GameplayKit's agent simulation. In each scene, a circle with an inscribed triangle represents an agent. Agents whose triangle is white can be controlled the mouse (OS X) or touch (iOS) input -- click or touch and drag and the agent will follow the mouse or touch position. 

## Exploring the Code

This project uses two shared classes to run the GameplayKit agent simulation for display in a SpriteKit scene:

- `AAPLAgentNode` is a SpriteKit node that owns a `GKAgent2D` object and displays a visual representation of the agent. By adopting the `GKAgentDelegate` protocol, the node can automatically update its position and rotation in the scene to match the state of the agent.
- `AAPLGameScene` is the base class for the eight demonstration scene that provides two key features for each:
	- Using a component system to include all of the scene's agents in SpriteKit's per-frame `update:` cycle
	- Tracking mouse or touch events with an invisible agent so that agents in each scene can follow the mouse or touch location.

The eight scene classes demonstrate various ways to use `GKGoal` and `GKBehavior` objects to motivate an agent's movement:

- `AAPLSeekScene`: The "player" agent follows the mouse/touch location. (This behavior is the basis for more complex behaviors in several of the other scenes.)
- `AAPLWanderScene`: An agent wanders aimlessly.
- `AAPLFleeScene`: An "enemy" agent stays away whenever the player agent draws near.
- `AAPLAvoidScene`: The player agent steers around obstacles to reach the mouse/touch location.
- `AAPLSeparateScene`: Two "friend" agents attempt to maintain consistent distance from the player agent.
- `AAPLAlignScene`: Two "friend" agents attempt to maintain consistent orientation with the player agent.
- `AAPLFlockScene`: By combining separation, alignment, and cohesion goals, a group of agents moves together to follow the mouse/touch.
- `AAPLPathScene`: An agent automatically follows a path.

For more information about using the GameplayKit agent simulation, see the chapter "Agents, Goals, and Behaviors" in [GameplayKit Programming Guide][1].

[1]: https://developer.apple.com/library/prerelease/ios/documentation/General/Conceptual/GameplayKit_Guide/index.html

## Requirements

### Build

Xcode 7.0, iOS 9.0 SDK or OS X 10.11 SDK

### Runtime

iOS 9.0 or OS X 10.11

Copyright (C) 2015 Apple Inc. All rights reserved.
