/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  This class manages loading and running skeletal animations for a character in the game.
  
 */

#import "AAPLSkinnedCharacter.h"
#import "AAPLGameLevel.h"

@implementation AAPLSkinnedCharacter

- (void)findAndSetSkeleton
{
	[self enumerateChildNodesUsingBlock:^(SCNNode *child, BOOL *stop) {
		if ( child.skinner != nil) {
			self.mainSkeleton = child.skinner.skeleton;
			*stop = YES;
		}
	}];
}

- (id)initWithNode:(SCNNode *)characterRootNode
{
	self = [super init];
	if (self) {
		characterRootNode.position = SCNVector3Make(0, 0, 0);

		[self addChildNode:characterRootNode];

		//-- Find the first skeleton
		[self enumerateChildNodesUsingBlock:^(SCNNode *child, BOOL *stop) {
			if ( child.skinner != nil) {
				self.mainSkeleton = child.skinner.skeleton;
				*stop = YES;
			}
		}];
	}

	return self;
}

- (CAAnimation *)cachedAnimationForKey:(NSString *)key
{
	return [self.animationsDict objectForKey:key];
}

+ (CAAnimation *)loadAnimationNamed:(NSString *)animationName fromSceneNamed:(NSString *)sceneName
{
	// Load the DAE using SCNSceneSource in order to be able to retrieve the animation by its identifier
	NSURL *url = [[NSBundle mainBundle] URLForResource:sceneName withExtension:@"dae"];
	SCNSceneSource *sceneSource = [SCNSceneSource sceneSourceWithURL:url options:@{SCNSceneSourceConvertToYUpKey : @YES} ];

	CAAnimation *animation = [sceneSource entryWithIdentifier:animationName withClass:[CAAnimation class]];

	// Blend animations for smoother transitions
	[animation setFadeInDuration:0.3];
	[animation setFadeOutDuration:0.3];

	return animation;
}

- (CAAnimation *)loadAndCacheAnimation:(NSString *)daeFile withName:(NSString *)name forKey:(NSString *)key
{
	if (self.animationsDict == nil) {
		self.animationsDict = [[NSMutableDictionary alloc] init];
	}

	CAAnimation *anim = [[self class] loadAnimationNamed:name fromSceneNamed:daeFile];

	if (anim) {
		[self.animationsDict setObject:anim forKey:key];
		anim.delegate = self;
	}
	return anim;
}

- (CAAnimation *)loadAndCacheAnimation:(NSString *)daeFile forKey:(NSString *)key
{
	return [self loadAndCacheAnimation:daeFile withName:key forKey:key];
}

- (void)chainAnimation:(NSString *)firstKey toAnimation:(NSString *)secondKey
{
	[self chainAnimation:firstKey toAnimation:secondKey fadeTime:0.85f];
}

- (void)chainAnimation:(NSString *)firstKey toAnimation:(NSString *)secondKey fadeTime:(CGFloat)fadeTime
{
	CAAnimation *firstAnim = [self cachedAnimationForKey:firstKey];
	CAAnimation *secondAnim = [self cachedAnimationForKey:secondKey];
	if (firstAnim == nil || secondAnim == nil)
		return;

	SCNAnimationEventBlock chainEventBlock = ^(CAAnimation *animation, id animatedObject, BOOL playingBackward) {
		[self.mainSkeleton addAnimation:secondAnim forKey:secondKey];
	};

	if (firstAnim.animationEvents == nil || firstAnim.animationEvents.count == 0) {
		firstAnim.animationEvents = @[[SCNAnimationEvent animationEventWithKeyTime:fadeTime block:chainEventBlock]];
	} else {
		NSMutableArray *pastEvents = [NSMutableArray arrayWithArray:firstAnim.animationEvents];
		[pastEvents addObject:[SCNAnimationEvent animationEventWithKeyTime:fadeTime block:chainEventBlock]];
		firstAnim.animationEvents = pastEvents;
	}
}

- (void)update:(NSTimeInterval)deltaTime
{
	// To be implemented by subclasses
}

@end
