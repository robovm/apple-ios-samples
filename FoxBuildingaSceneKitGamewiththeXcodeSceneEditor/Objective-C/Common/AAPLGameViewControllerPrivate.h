/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

*/

@import simd;
@import SceneKit;
@import GameController;

#import "AAPLGameViewController.h"
#import "AAPLCharacter.h"

@interface AAPLGameViewController() {
    // Nodes to manipulate the camera
    SCNNode *_cameraYHandle;
    SCNNode *_cameraXHandle;
    
    // The character
    AAPLCharacter *_character;
    
    // Game states
    BOOL _gameIsComplete;
    BOOL _lockCamera;
    
    SCNMaterial *_grassArea;
    SCNMaterial *_waterArea;
    NSArray<SCNNode *> *_flames;
    NSArray<SCNNode *> *_enemies;
    
    // Sounds
    SCNAudioSource *_collectPearlSound;
    SCNAudioSource *_collectFlowerSound;
    SCNAudioPlayer *_flameThrowerSound;
    SCNAudioSource *_victoryMusic;
    
    // Particles
    SCNParticleSystem *_confettiParticleSystem;
    SCNParticleSystem *_collectFlowerParticleSystem;
    
    NSUInteger _collectedPearlsCount;
    NSUInteger _collectedFlowersCount;
    
    // Collisions
    CGFloat _maxPenetrationDistance;
    SCNVector3 _replacementPosition;
    BOOL _replacementPositionIsValid;
    
    // For automatic camera animation
    SCNNode *_currentGround;
    SCNNode *_mainGround;
    NSMapTable<SCNNode *, NSValue *> *_groundToCameraPosition;
    
    // Game controls
    GCControllerDirectionPad *_controllerDPad;
    vector_float2 _controllerDirection;
    
#if !(TARGET_OS_IOS || TARGET_OS_TV)
    CGPoint _lastMousePosition;
#elif TARGET_OS_IOS
    UITouch *_padTouch;
    UITouch *_panningTouch;
#endif
}

- (void)panCamera:(CGPoint)direction;

@end

@interface AAPLGameViewController (GameControls) <AAPLKeyboardAndMouseEventsDelegate>

- (void)setupGameControllers;
@property(nonatomic, readonly) vector_float2 controllerDirection;

@end
