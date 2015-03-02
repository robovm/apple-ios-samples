/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  This class manages loading and running skeletal animations for a character in the game.
  
 */

#import <SceneKit/SceneKit.h>

@interface AAPLSkinnedCharacter : SCNNode

// Dictionary used to look up the animations by key.
@property (strong, nonatomic) NSMutableDictionary *animationsDict;

// main skeleton reference for faster look up.
@property (strong, nonatomic) SCNNode *mainSkeleton;

- (id)initWithNode:(SCNNode *)characterRootNode;
- (void)findAndSetSkeleton;

- (void)update:(NSTimeInterval)deltaTime;

- (CAAnimation *)loadAndCacheAnimation:(NSString *)daeFile forKey:(NSString *)key;
- (CAAnimation *)loadAndCacheAnimation:(NSString *)daeFile withName:(NSString *)name forKey:(NSString *)key;

- (CAAnimation *)cachedAnimationForKey:(NSString *)key;
- (void)chainAnimation:(NSString *)firstKey toAnimation:(NSString *)secondKey;
- (void)chainAnimation:(NSString *)firstKey toAnimation:(NSString *)secondKey fadeTime:(CGFloat)fadeTime;

@end
