/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The shared implementation of the application delegate for both iOS and OS X versions of the game. This class handles initial setup of the game, including loading assets and checking for game controllers, before passing control to AAPLGameSimulation to start the game.
  
 */

#import <SceneKit/SceneKit.h>
#import <SpriteKit/SpriteKit.h>
#import <GameKit/GameKit.h>

@class AAPLSceneView;

@interface AAPLAppDelegate : NSObject

+ (AAPLAppDelegate *)sharedAppDelegate;

@property (weak) IBOutlet AAPLSceneView *scnView;

- (void)togglePaused;

- (void)commonApplicationDidFinishLaunchingWithCompletionHandler:(void(^)(void))completionHandler;

@end
