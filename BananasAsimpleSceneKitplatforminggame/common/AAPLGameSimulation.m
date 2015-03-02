/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  This class manages the global state of the game. It handles SCNSceneRendererDelegate methods for participating in the update/render loop, polls for input (directly for game controllers and via AAPLSceneView for key/touch input), and delegates game logic to the AAPLGameLevel object.
  
 */

#import <GLKit/GLKit.h>
#import <GameController/GameController.h>

#import "AAPLGameSimulation.h"
#import "AAPLSceneView.h"
#import "AAPLPlayerCharacter.h"
#import "AAPLInGameScene.h"
#import "AAPLGameLevel.h"
#import "AAPLAppDelegate.h"
#import "AAPLCoconut.h"

AAPLGameSimulation *_sharedSimulation = nil;

@interface AAPLGameSimulation ()
{
	CGFloat _walkSpeed;
	NSTimeInterval _previousUpdateTime;
	NSTimeInterval _previousPhysicsUpdateTime;
	NSTimeInterval _deltaTime;
}

@property (strong, nonatomic) SCNTechnique *desaturationTechnique;

@end

@implementation AAPLGameSimulation

// Singleton for easy lookup
+ (AAPLGameSimulation *)sim
{
	if (_sharedSimulation == nil) {
		_sharedSimulation = [[AAPLGameSimulation alloc] init];
	}

	return _sharedSimulation;
}

- (void)setupTechniques
{

	// The scene can be de-saturarted as a full screen effect.
	NSURL *url = [[NSBundle mainBundle] URLForResource:@"art.scnassets/techniques/desaturation" withExtension:@"plist"];
	self.desaturationTechnique = [SCNTechnique techniqueWithDictionary:[NSDictionary dictionaryWithContentsOfURL:url]];
	[self.desaturationTechnique setValue:@0.0 forKey:@"Saturation"];
}

- (id)init
{
	self = [super init];

	if (self) {

		// We create one level in our simulation.
		self.gameLevel = [[AAPLGameLevel alloc] init];
		_gameState = AAPLGameStatePaused;

		// Register ourself as a listener to physics callbacks.
		SCNNode *levelNode = [self.gameLevel createLevel];
		[self.rootNode addChildNode:levelNode];
		[self.physicsWorld setContactDelegate:self];
		self.physicsWorld.gravity = SCNVector3Make(0, -800, 0);

		[self setupTechniques];
	}

	return self;
}

- (void)setPostGameFilters
{
	[SCNTransaction begin];

	[self.desaturationTechnique setValue:@1.0 forKey:@"Saturation"];

	[SCNTransaction setAnimationDuration:1.0];

	[SCNTransaction commit];

	AAPLAppDelegate *appDelegate = [AAPLAppDelegate sharedAppDelegate];
	[appDelegate.scnView setTechnique:self.desaturationTechnique];
}

- (void)setPauseFilters
{
	[SCNTransaction begin];

	[self.desaturationTechnique setValue:@1.0 forKey:@"Saturation"];

	[SCNTransaction setAnimationDuration:1.0];
	[self.desaturationTechnique setValue:@0.0 forKey:@"Saturation"];

	[SCNTransaction commit];

	AAPLAppDelegate *appDelegate = [AAPLAppDelegate sharedAppDelegate];
	[appDelegate.scnView setTechnique:self.desaturationTechnique];
}

- (void)setPregameFilters
{

	[SCNTransaction begin];

	[self.desaturationTechnique setValue:@1.0 forKey:@"Saturation"];

	[SCNTransaction setAnimationDuration:1.0];
	[self.desaturationTechnique setValue:@0.0 forKey:@"Saturation"];

	[SCNTransaction commit];

	AAPLAppDelegate *appDelegate = [AAPLAppDelegate sharedAppDelegate];
	[appDelegate.scnView setTechnique:self.desaturationTechnique];
}

- (void)setIngameFilters
{
	[SCNTransaction begin];

	[self.desaturationTechnique setValue:@0.0 forKey:@"Saturation"];

	[SCNTransaction setAnimationDuration:1.0];
	[self.desaturationTechnique setValue:@1.0 forKey:@"Saturation"];
	[SCNTransaction commit];

	SCNAction *dropTechnique = [SCNAction waitForDuration:1.0f];

	AAPLAppDelegate *appDelegate = [AAPLAppDelegate sharedAppDelegate];
	[appDelegate.scnView.scene.rootNode runAction:dropTechnique completionHandler:^{
		[appDelegate.scnView setTechnique:nil];
	}];
}

- (void)setGameState:(AAPLGameState)gameState
{
	// Ignore redundant state changes.
	if (_gameState == gameState)
		return;

	// Change the UI system according to gameState.
	[self.gameUIScene setGameState:gameState];

	// Only reset the level from a non paused mode.
	if (gameState == AAPLGameStateInGame && _gameState != AAPLGameStatePaused) {
		[self.gameLevel resetLevel];
	}
	_gameState = gameState;

	// Based on the new game state... set the saturation value
	// that the techniques will use to render the scenekit view.
	if (_gameState == AAPLGameStatePostGame) {
		[self setPostGameFilters];
	} else if (_gameState == AAPLGameStatePaused) {
		[[AAPLGameSimulation sim] playSound:@"deposit.caf"];
		[self setPauseFilters];
	} else if (_gameState == AAPLGameStatePreGame) {
		[self setPregameFilters];
	} else {
		[[AAPLGameSimulation sim] playSound:@"ack.caf"];
		[self setIngameFilters];
	}
}

/*! Our main input pump for the app.
 */
- (void)renderer:(id <SCNSceneRenderer>)aRenderer updateAtTime:(NSTimeInterval)time
{

	if (_previousUpdateTime == 0.0) {
		_previousUpdateTime = time;
	}
	_deltaTime = time - _previousUpdateTime;
	_previousUpdateTime = time;

	AAPLSceneView *aView = (AAPLSceneView *)aRenderer;

	bool pressingLeft = NO;
	bool pressingRight = NO;
	bool pressingJump = NO;

	GCGamepad *gamePad = self.controller.gamepad;
	GCExtendedGamepad *extGamePad = self.controller.extendedGamepad;

	if (gamePad.dpad.left.pressed == YES || extGamePad.leftThumbstick.left.pressed == YES)
		pressingLeft = YES;

	if (gamePad.dpad.right.pressed == YES || extGamePad.leftThumbstick.right.pressed == YES)
		pressingRight = YES;

	if (gamePad.buttonA.pressed == YES ||
		gamePad.buttonB.pressed == YES ||
		gamePad.buttonX.pressed == YES ||
		gamePad.buttonY.pressed == YES ||
		gamePad.leftShoulder.pressed == YES ||
		gamePad.rightShoulder.pressed == YES)
		pressingJump = YES;

	if ([aView.keysPressed containsObject:AAPLLeftKey] == YES)
		pressingLeft = YES;

	if ([aView.keysPressed containsObject:AAPLRightKey] == YES)
		pressingRight = YES;

	if ([aView.keysPressed containsObject:AAPLJumpKey] == YES)
		pressingJump = YES;

	if (self.gameState == AAPLGameStateInGame && self.gameLevel.hitByLavaReset == NO) {
		if (pressingLeft) {
			self.gameLevel.playerCharacter.walkDirection = WalkDirectionLeft;
		} else if (pressingRight) {
			self.gameLevel.playerCharacter.walkDirection = WalkDirectionRight;
		}

		if (pressingLeft || pressingRight) {
			//Run if not running
			self.gameLevel.playerCharacter.inRunAnimation = YES;
		} else {
			//Stop running if running
			self.gameLevel.playerCharacter.inRunAnimation = NO;
		}

		if (pressingJump) {
			[self.gameLevel.playerCharacter performJumpAndStop:NO];
		} else {
			[self.gameLevel.playerCharacter performJumpAndStop:YES];
		}
	} else if (self.gameState == AAPLGameStatePreGame || self.gameState == AAPLGameStatePostGame) {
		if (pressingJump) {
			[self setGameState:AAPLGameStateInGame];
		}
	}


}

/*! Our main simulation pump for the app.
 */
- (void)renderer:(id <SCNSceneRenderer>)aRenderer didSimulatePhysicsAtTime:(NSTimeInterval)time
{
	[self.gameLevel update:_deltaTime withRenderer:(AAPLSceneView *)aRenderer];
}

#pragma mark - Collision handling

- (void)physicsWorld:(SCNPhysicsWorld *)world didBeginContact:(SCNPhysicsContact *)contact
{
	if (self.gameState == AAPLGameStateInGame) {
		// Player to banana, large banana, or coconut
		if (contact.nodeA == self.gameLevel.playerCharacter.collideSphere) {
			[self playerCollideWithContact:contact.nodeB point:contact.contactPoint];
			return;
		} else if (contact.nodeB == self.gameLevel.playerCharacter.collideSphere) {
			[self playerCollideWithContact:contact.nodeA point:contact.contactPoint];
			return;
		}

		// Coconut to anything but the player.
		if ((contact.nodeB.physicsBody.categoryBitMask == GameCollisionCategoryCoconut)) {
			[self handleCollideForCoconut:(AAPLCoconut *)contact.nodeB];
		} else if ((contact.nodeA.physicsBody.categoryBitMask == GameCollisionCategoryCoconut)) {
			[self handleCollideForCoconut:(AAPLCoconut *)contact.nodeA];
		}
	}
}

- (void)playerCollideWithContact:(SCNNode *)node point:(SCNVector3)contactPoint
{
	if ([self.gameLevel.bananas containsObject:node] == YES) {
		[self.gameLevel collectBanana:node];
	} else if ([self.gameLevel.largeBananas containsObject:node] == YES) {
		[self.gameLevel collectLargeBanana:node];
	} else if (node.physicsBody.categoryBitMask == GameCollisionCategoryCoconut) {
		[self.gameLevel collideWithCoconut:node point:contactPoint];
	} else if (node.physicsBody.categoryBitMask == GameCollisionCategoryLava) {
		[self.gameLevel collideWithLava];
	}
}

- (void)handleCollideForCoconut:(AAPLCoconut *)coconut
{
	// Remove coconut from the world after it has time to fall offscreen.
	[coconut runAction:[SCNAction waitForDuration:3.0f] completionHandler:^{
		[coconut removeFromParentNode];
		[self.gameLevel.coconuts removeObject:coconut];
	}];
}

#pragma mark - Game Controller handling

- (void)controllerDidConnect:(NSNotification *)note
{
	GCController *controller = [note object];

	// Assign the last in controller.
	self.controller = controller;
}

- (void)controllerDidDisconnect:(NSNotification *)note
{
	self.controller = nil;

	AAPLGameState currentState = [[AAPLGameSimulation sim] gameState];

	// Pause the if we are in game and the controller was disconnected.
	if (currentState == AAPLGameStateInGame) {
		[[AAPLGameSimulation sim] setGameState:AAPLGameStatePaused];
	}
}

- (void)setController:(GCController *)controller
{
	_controller = controller;

	if (_controller == nil) {
		return;
	}

	[_controller setControllerPausedHandler:^(GCController *myController) {
		AAPLGameState currentState = [[AAPLGameSimulation sim] gameState];

		if (currentState == AAPLGameStatePaused) {
			[[AAPLGameSimulation sim] setGameState:AAPLGameStateInGame];
		} else if (currentState == AAPLGameStateInGame) {
			[[AAPLGameSimulation sim] setGameState:AAPLGameStatePaused];
		}
	}];
}

#pragma mark - Sound & Music

- (void)playSound:(NSString *)soundFileName
{
	if (soundFileName == nil)
		return;

	NSString *path = [NSString stringWithFormat:@"Sounds/%@", soundFileName];
	[self.gameUIScene runAction:[SKAction playSoundFileNamed:path waitForCompletion:NO]];
}

- (void)playMusic:(NSString *)soundFileName
{
	if (soundFileName == nil)
		return;
	if ([self.gameUIScene actionForKey:soundFileName] != nil)
		return;

	NSString *path = [NSString stringWithFormat:@"Sounds/%@", soundFileName];
	SKAction *repeatAction = [SKAction repeatActionForever:[SKAction playSoundFileNamed:path waitForCompletion:YES]];
	[self.gameUIScene runAction:repeatAction withKey:soundFileName];
}

#pragma mark - Resource Loading convenience

NSString *const ArtFolderRoot = @"art.scnassets";

+ (NSString *)pathForArtResource:(NSString *)resourceName
{
	return [NSString stringWithFormat:@"%@/%@", ArtFolderRoot, resourceName];
}

+ (SCNNode *)loadNodeWithName:(NSString *)name fromSceneNamed:(NSString *)path
{
	// Load the scene from the specified file
	SCNScene *scene = [SCNScene sceneNamed:path
							   inDirectory:nil
								   options:@{SCNSceneSourceConvertToYUpKey : @YES,
											 SCNSceneSourceAnimationImportPolicyKey :SCNSceneSourceAnimationImportPolicyPlayRepeatedly}];

	// Retrieve the root node
	SCNNode *node = scene.rootNode;

	// Search for the node named "name"
	if (name) {
		node = [node childNodeWithName:name recursively:YES];
	} else {
		node = node.childNodes[0];
	}

	return node;
}

+ (SCNParticleSystem *)loadParticleSystemWithName:(NSString *)name
{
	NSString *path = [NSString stringWithFormat:@"level/effects/%@.scnp", name];
	path = [self pathForArtResource:path];
	path = [[NSBundle mainBundle] pathForResource:path ofType:nil];
	SCNParticleSystem *newSystem = [NSKeyedUnarchiver unarchiveObjectWithFile:path];

	path = [NSString stringWithFormat:@"level/effects/%@", [((NSURL *)newSystem.particleImage).path lastPathComponent]];
	path = [self pathForArtResource:path];
	NSURL *url = [NSURL URLWithString:[path stringByAddingPercentEscapesUsingEncoding:NSUnicodeStringEncoding]];
	newSystem.particleImage = url;
	return newSystem;
}

@end
