/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The shared implementation of the application delegate for both iOS and OS X versions of the game. This class handles initial setup of the game, including loading assets and checking for game controllers, before passing control to AAPLGameSimulation to start the game.
  
 */

#import <SceneKit/SceneKit.h>
#import <SpriteKit/SpriteKit.h>
#import <GameController/GameController.h>
#import <GLKit/GLKMath.h>
#import <GameKit/GameKit.h>

#import "AAPLAppDelegate.h"
#import "AAPLMainMenu.h"
#import "AAPLInGameScene.h"
#import "AAPLGameSimulation.h"
#import "AAPLSceneView.h"
#import "AAPLGameLevel.h"
#import "AAPLPlayerCharacter.h"

@interface AAPLAppDelegate ()

@property (strong, nonatomic) AAPLInGameScene *skScene;

@end

@implementation AAPLAppDelegate

+ (AAPLAppDelegate *)sharedAppDelegate
{
#if TARGET_OS_IPHONE
	return [UIApplication sharedApplication].delegate;
#else
	return [NSApp delegate];
#endif
}

- (void)listenForGameControllerWithSim:(AAPLGameSimulation *)gameSim
{
	//-- GameController hook up
	[[NSNotificationCenter defaultCenter] addObserver:gameSim
											 selector:@selector(controllerDidConnect:)
												 name:GCControllerDidConnectNotification
											   object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:gameSim
											 selector:@selector(controllerDidDisconnect:)
												 name:GCControllerDidDisconnectNotification
											   object:nil];

	[GCController startWirelessControllerDiscoveryWithCompletionHandler:nil];
}

- (void)togglePaused
{
	AAPLGameState currentState = [[AAPLGameSimulation sim] gameState];

	if (currentState == AAPLGameStatePaused) {
		[[AAPLGameSimulation sim] setGameState:AAPLGameStateInGame];
	} else if (currentState == AAPLGameStateInGame) {
		[[AAPLGameSimulation sim] setGameState:AAPLGameStatePaused];
	}
}

- (void)commonApplicationDidFinishLaunchingWithCompletionHandler:(void(^)(void))completionHandler
{
	// Debugging and Stats
#if DEBUG
	self.scnView.showsStatistics = YES;
#endif

	self.scnView.backgroundColor = [SKColor blackColor];

	NSProgress *progress = [NSProgress progressWithTotalUnitCount:10];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[progress becomeCurrentWithPendingUnitCount:2];

		AAPLInGameScene *ui = [[AAPLInGameScene alloc] initWithSize:self.scnView.bounds.size];
		dispatch_async(dispatch_get_main_queue(), ^{
			self.scnView.overlaySKScene = ui;
		});

		[progress resignCurrent];
		[progress becomeCurrentWithPendingUnitCount:3];

		AAPLGameSimulation *gameSim = [AAPLGameSimulation sim];
		gameSim.gameUIScene = ui;

		[progress resignCurrent];
		[progress becomeCurrentWithPendingUnitCount:3];


		[SCNTransaction flush];

		// Preload
		[self.scnView prepareObject:gameSim shouldAbortBlock:NULL];
		[progress resignCurrent];
		[progress becomeCurrentWithPendingUnitCount:1];

		// Game Play Specific Code
		gameSim.gameUIScene.gameStateDelegate = gameSim.gameLevel;
		[gameSim.gameLevel resetLevel];
		gameSim.gameState = AAPLGameStatePreGame;

		[progress resignCurrent];
		[progress becomeCurrentWithPendingUnitCount:1];

		// GameController hook up
		[self listenForGameControllerWithSim:gameSim];


		dispatch_async(dispatch_get_main_queue(), ^{
			self.scnView.scene = gameSim;
			self.scnView.delegate = gameSim;
			if (completionHandler)
				completionHandler();
		});

		[progress resignCurrent];
		
	});
	
}

@end
