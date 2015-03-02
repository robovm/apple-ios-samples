/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  This class simulates the player character. It manages the character's animations and simulates movement and jumping.
  
 */

#import <SpriteKit/SpriteKit.h>
#import <GLKit/GLKit.h>

#import "AAPLMathUtils.h"
#import "AAPLPlayerCharacter.h"
#import "AAPLGameLevel.h"
#import "AAPLGameSimulation.h"
#import "AAPLSceneView.h"

typedef NS_ENUM(NSInteger, AAPLCharacterAnimation) {
	AAPLCharacterAnimationDie = 0,
	AAPLCharacterAnimationRun,
	AAPLCharacterAnimationJump,
	AAPLCharacterAnimationJumpFalling,
	AAPLCharacterAnimationJumpLand,
	AAPLCharacterAnimationIdle,
	AAPLCharacterAnimationGetHit,
	AAPLCharacterAnimationBored,
	AAPLCharacterAnimationRunStart,
	AAPLCharacterAnimationRunStop,
	AAPLCharacterAnimationCount
};

@interface AAPLPlayerCharacter () {
	BOOL _isWalking;
	CGFloat jumpForce;
	CGFloat jumpDuration;
	CGFloat jumpForceOrig;
	CGFloat dustWalkingBirthRate;
}

@property (nonatomic) BOOL inJumpAnimation;
@property (nonatomic) CGFloat groundPlaneHeight;
@property (nonatomic) GLKVector3 velocity;
@property (nonatomic) CGFloat baseWalkSpeed;

@property (strong, nonatomic) SCNNode *cameraHelper;
@property (assign, nonatomic) BOOL ChangingDirection;

+ (NSString *)keyForAnimationType:(AAPLCharacterAnimation)animType;

@end

@implementation AAPLPlayerCharacter

+ (NSString *)keyForAnimationType:(AAPLCharacterAnimation)animType
{

	switch (animType) {
		case AAPLCharacterAnimationBored:
			return @"bored-1";
		case AAPLCharacterAnimationDie:
			return @"die-1";
		case AAPLCharacterAnimationGetHit:
			return @"hit-1";
		case AAPLCharacterAnimationIdle:
			return @"idle-1";
		case AAPLCharacterAnimationJump:
			return @"jump_start-1";
		case AAPLCharacterAnimationJumpFalling:
			return @"jump_falling-1";
		case AAPLCharacterAnimationJumpLand:
			return @"jump_land-1";
		case AAPLCharacterAnimationRun:
			return @"run-1";
		case AAPLCharacterAnimationRunStart:
			return @"run_start-1";
		case AAPLCharacterAnimationRunStop:
			return @"run_stop-1";
		case AAPLCharacterAnimationCount:
			return nil;
	}
	return nil;
}

- (id)initWithNode:(SCNNode *)characterNode
{
	self = [super initWithNode:characterNode];
	if (self) {
		self.categoryBitMask = NodeCategoryLava;

		// Setup walking parameters.
		_velocity = GLKVector3Make(0, 0, 0);
		_isWalking = NO;
		_ChangingDirection = NO;
		_baseWalkSpeed = .0167f;
		_jumpBoost = 0.0f;
		self.walkSpeed = _baseWalkSpeed * 2;
		self.jumping = NO;
		_groundPlaneHeight = 0.0f;
		self.walkDirection = WalkDirectionRight;

		// Create a node to help position the camera and attach to self.
		self.cameraHelper = [SCNNode node];
		[self addChildNode:self.cameraHelper];
		self.cameraHelper.position = SCNVector3Make(1000, 200, 0);

		// Create a capsule used for generic collision.
		_collideSphere = [SCNNode node];
		_collideSphere.position = SCNVector3Make(0, 80, 0);
		SCNGeometry *geo = [SCNCapsule capsuleWithCapRadius:90 height:160];
		SCNPhysicsShape *shape2 = [SCNPhysicsShape shapeWithGeometry:geo options:nil];
		_collideSphere.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeKinematic shape:shape2];

		// We only want to collide with bananas, coins, and coconuts. Ground collision is handled elsewhere.
		_collideSphere.physicsBody.collisionBitMask =
		GameCollisionCategoryBanana |
		GameCollisionCategoryCoin |
		GameCollisionCategoryCoconut |
		GameCollisionCategoryLava;

		// Put ourself into the player category so other objects can limit their scope of collision checks.
		_collideSphere.physicsBody.categoryBitMask = GameCollisionCategoryPlayer;
		[self addChildNode:_collideSphere];

		// Load our dust poof.
		self.dustPoof = [AAPLGameSimulation loadParticleSystemWithName:@"dust"];
		self.dustWalking = [AAPLGameSimulation loadParticleSystemWithName:@"dustWalking"];
		dustWalkingBirthRate = self.dustWalking.birthRate;

		// Load the animations and store via a lookup table.
		[self setupIdleAnimation];
		[self setupRunAnimation];
		[self setupJumpAnimation];
		[self setupBoredAnimation];
		[self setupHitAnimation];

		[self playIdle:NO];
	}

	return self;
}

#pragma mark - Animation Setup

- (void)setupIdleAnimation
{
	CAAnimation *idleAnimation = [self loadAndCacheAnimation:@"art.scnassets/characters/explorer/idle"
													  forKey:[AAPLPlayerCharacter keyForAnimationType:AAPLCharacterAnimationIdle]];
	if (idleAnimation != nil) {
		idleAnimation.repeatCount = FLT_MAX;
		idleAnimation.fadeInDuration = 0.15f;
		idleAnimation.fadeOutDuration = 0.15f;
	}
}

- (void)setupRunAnimation
{
	NSString *runKey = [AAPLPlayerCharacter keyForAnimationType:AAPLCharacterAnimationRun];
	NSString *runStartKey = [AAPLPlayerCharacter keyForAnimationType:AAPLCharacterAnimationRunStart];
	NSString *runStopKey = [AAPLPlayerCharacter keyForAnimationType:AAPLCharacterAnimationRunStop];

	CAAnimation *runAnim = [self loadAndCacheAnimation:@"art.scnassets/characters/explorer/run"
												forKey:runKey];
	CAAnimation *runStartAnim = [self loadAndCacheAnimation:@"art.scnassets/characters/explorer/run_start"
													 forKey:runStartKey];
	CAAnimation *runStopAnim = [self loadAndCacheAnimation:@"art.scnassets/characters/explorer/run_stop"
													forKey:runStopKey];
	runAnim.repeatCount = FLT_MAX;
	runStartAnim.repeatCount = 0;
	runStopAnim.repeatCount = 0;

	runAnim.fadeInDuration = 0.05f;
	runAnim.fadeOutDuration = 0.05f;
	runStartAnim.fadeInDuration = 0.05f;
	runStartAnim.fadeOutDuration = 0.05f;
	runStopAnim.fadeInDuration = 0.05f;
	runStopAnim.fadeOutDuration = 0.05f;


	SCNAnimationEventBlock stepLeftBlock = ^(CAAnimation *animation, id animatedObject, BOOL playingBackward) {
		[[AAPLGameSimulation sim] playSound:@"leftstep.caf"];
	};
	SCNAnimationEventBlock stepRightBlock = ^(CAAnimation *animation, id animatedObject, BOOL playingBackward) {
		[[AAPLGameSimulation sim] playSound:@"rightstep.caf"];
	};

	SCNAnimationEventBlock startWalkStateBlock = ^(CAAnimation *animation, id animatedObject, BOOL playingBackward) {
		if (_inRunAnimation == YES) {
			_isWalking = YES;
		} else {
			[self.mainSkeleton removeAnimationForKey:runKey fadeOutDuration:0.15f];
		}
	};
	SCNAnimationEventBlock stopWalkStateBlock = ^(CAAnimation *animation, id animatedObject, BOOL playingBackward) {
		_isWalking = NO;
		[self turnOffWalkingDust];
		if (_ChangingDirection == YES) {
			_inRunAnimation = NO;
			self.inRunAnimation = YES;
			self.ChangingDirection = NO;
			_walkDirection = (_walkDirection == WalkDirectionLeft) ? WalkDirectionRight : WalkDirectionLeft;
		}
	};

	runStopAnim.animationEvents = @[[SCNAnimationEvent animationEventWithKeyTime:1.0 block:stopWalkStateBlock]];
	runAnim.animationEvents = @[[SCNAnimationEvent animationEventWithKeyTime:0.0 block:startWalkStateBlock],
								[SCNAnimationEvent animationEventWithKeyTime:0.25 block:stepRightBlock],
								[SCNAnimationEvent animationEventWithKeyTime:0.75 block:stepLeftBlock]];
}

- (void)setupJumpAnimation
{
	NSString *jumpKey = [AAPLPlayerCharacter keyForAnimationType:AAPLCharacterAnimationJump];
	NSString *fallingKey = [AAPLPlayerCharacter keyForAnimationType:AAPLCharacterAnimationJumpFalling];
	NSString *landKey = [AAPLPlayerCharacter keyForAnimationType:AAPLCharacterAnimationJumpLand];
	NSString *idleKey = [AAPLPlayerCharacter keyForAnimationType:AAPLCharacterAnimationIdle];

	[self loadAndCacheAnimation:@"art.scnassets/characters/explorer/jump_start" forKey:jumpKey];
	[self loadAndCacheAnimation:@"art.scnassets/characters/explorer/jump_falling" forKey:fallingKey];
	[self loadAndCacheAnimation:@"art.scnassets/characters/explorer/jump_land" forKey:landKey];

	CAAnimation *jumpAnimation = [self cachedAnimationForKey:jumpKey];
	CAAnimation *fallAnimation = [self cachedAnimationForKey:fallingKey];
	CAAnimation *landAnimation = [self cachedAnimationForKey:landKey];

	jumpAnimation.fadeInDuration = 0.15f;
	jumpAnimation.fadeOutDuration = 0.15f;
	fallAnimation.fadeInDuration = 0.15f;
	landAnimation.fadeInDuration = 0.15f;
	landAnimation.fadeOutDuration = 0.15f;

	jumpAnimation.repeatCount = 0;
	fallAnimation.repeatCount = 0;
	landAnimation.repeatCount = 0;

	jumpForce = jumpForceOrig = 7.0f;
	jumpDuration = jumpAnimation.duration;
	SCNAnimationEventBlock leaveGroundBlock = ^(CAAnimation *animation, id animatedObject, BOOL playingBackward) {
		_velocity = GLKVector3Add(_velocity, GLKVector3Make(0, jumpForce * 2.1, 0));
		self.launching = NO;
		self.inJumpAnimation = NO;
	};
	SCNAnimationEventBlock pause = ^(CAAnimation *animation, id animatedObject, BOOL playingBackward) {
		[self.mainSkeleton pauseAnimationForKey:fallingKey];
	};

	jumpAnimation.animationEvents = @[[SCNAnimationEvent animationEventWithKeyTime:0.25f block:leaveGroundBlock]];
	fallAnimation.animationEvents = @[[SCNAnimationEvent animationEventWithKeyTime:0.5f block:pause]];

	// Animation Sequence is to Jump -> Fall -> Land -> Idle.
	[self chainAnimation:jumpKey toAnimation:fallingKey];
	[self chainAnimation:landKey toAnimation:idleKey];
}

- (void)setupBoredAnimation
{
	[self loadAndCacheAnimation:@"art.scnassets/characters/explorer/bored"
						 forKey:[AAPLPlayerCharacter keyForAnimationType:AAPLCharacterAnimationBored]];
	CAAnimation *animation = [self cachedAnimationForKey:[AAPLPlayerCharacter keyForAnimationType:AAPLCharacterAnimationBored]];
	if (animation != nil) {
		animation.repeatCount = FLT_MAX;
	}
}

- (void)setupHitAnimation
{
	[self loadAndCacheAnimation:@"art.scnassets/characters/explorer/hit"
						 forKey:[AAPLPlayerCharacter keyForAnimationType:AAPLCharacterAnimationGetHit]];
	CAAnimation *animation = [self cachedAnimationForKey:[AAPLPlayerCharacter keyForAnimationType:AAPLCharacterAnimationGetHit]];
	if (animation != nil) {
		animation.repeatCount = FLT_MAX;
	}
}

#pragma mark -

- (BOOL)isRunning
{
	return _isWalking;
}

- (void)playIdle:(BOOL)stop
{
	[self turnOffWalkingDust];

	CAAnimation *anim = [self cachedAnimationForKey:[AAPLPlayerCharacter keyForAnimationType:AAPLCharacterAnimationIdle]];
	[anim setRepeatCount:MAXFLOAT];
	[anim setFadeInDuration:0.1];
	[anim setFadeOutDuration:0.1];
	[self.mainSkeleton addAnimation:anim forKey:[AAPLPlayerCharacter keyForAnimationType:AAPLCharacterAnimationIdle]];
}

- (void)playLand
{
	NSString *fallKey = [AAPLPlayerCharacter keyForAnimationType:AAPLCharacterAnimationJumpFalling];
	NSString *key = [AAPLPlayerCharacter keyForAnimationType:AAPLCharacterAnimationJumpLand];
	CAAnimation *anim = [self cachedAnimationForKey:key];
	anim.timeOffset = 0.65f;
	[self.mainSkeleton removeAnimationForKey:fallKey fadeOutDuration:0.15f];
	self.inJumpAnimation = NO;
	if (_isWalking) {
		_inRunAnimation = NO;
		self.inRunAnimation = YES;
	} else {
		[self.mainSkeleton addAnimation:anim forKey:key];
	}

	[[AAPLGameSimulation sim] playSound:@"Land.wav"];
}

- (void)update:(NSTimeInterval)deltaTime
{
	GLKMatrix4 mtx = SCNMatrix4ToGLKMatrix4(self.transform);

	GLKVector3 gravity = GLKVector3Make(0, -90, 0);
	GLKVector3 gravitystep = GLKVector3MultiplyScalar(gravity, deltaTime);

	_velocity = GLKVector3Add(_velocity, gravitystep);

	GLKVector3 minMovement = GLKVector3Make(0, -50, 0);
	GLKVector3 maxMovement = GLKVector3Make(100, 100, 100);
	_velocity = GLKVector3Maximum(_velocity, minMovement);
	_velocity = GLKVector3Minimum(_velocity, maxMovement);

	mtx = GLKMatrix4TranslateWithVector3(mtx, _velocity);
	_groundPlaneHeight = [self getGroundHeight:mtx];

	if (mtx.m31 < _groundPlaneHeight) {
		if (self.launching == NO && _velocity.y < 0.0f) {
			if (self.jumping == YES) {
				self.jumping = NO;
				if (self.dustPoof != nil) {
					[self addParticleSystem:self.dustPoof];
					self.dustPoof.loops = NO;
				}
				[self playLand];
				_jumpBoost = 0.0f;
			}
		}

		// tie to ground.
		mtx.m31 = _groundPlaneHeight;

		_velocity.y = 0.0f;
	}

	self.transform = SCNMatrix4FromGLKMatrix4(mtx);

	//-- move the camera
	SCNNode *camera = [[[AAPLGameSimulation sim] gameLevel] camera].parentNode;

	if (camera != nil) {
		//interpolate
		SCNVector3 pos = SCNVector3Make(self.position.x + ((self.walkDirection == WalkDirectionRight) ? 250 : -250),
										(self.position.y + 261) - (0.85f * (self.position.y - _groundPlaneHeight)),
										(self.position.z + 1500));
		SCNMatrix4 desiredTransform = AAPLMatrix4SetPosition(camera.transform, pos);
		camera.transform = AAPLMatrix4Interpolate(camera.transform, desiredTransform, 0.025);
	}
}

/*! Given our current location,
 shoot a ray downward to collide with our ground mesh or lava mesh
 */
- (CGFloat)getGroundHeight:(GLKMatrix4)mtx
{
	SCNVector3 start = SCNVector3Make(mtx.m30, mtx.m31 + 1000, mtx.m32);
	SCNVector3 end = SCNVector3Make(mtx.m30, mtx.m31 - 3000, mtx.m32);

	NSArray *hits = [[AAPLGameSimulation sim].physicsWorld rayTestWithSegmentFromPoint:start
																			  toPoint:end
																			  options:@{SCNPhysicsTestCollisionBitMaskKey : @(GameCollisionCategoryGround | GameCollisionCategoryLava),
																						SCNPhysicsTestSearchModeKey : SCNPhysicsTestSearchModeClosest}];
	if (hits.count > 0) {
		// take the first hit. make that the ground.
		for (SCNHitTestResult *result in hits) {
			if (result.node.physicsBody.categoryBitMask & ~(GameCollisionCategoryGround|GameCollisionCategoryLava))
				continue;
			return result.worldCoordinates.y;
		}
	}

	// 0 is ground if we didn't hit anything.
	return 0;

}

SCNMatrix4 AAPLMatrix4Interpolate(SCNMatrix4 scnm0, SCNMatrix4 scnmf, CGFloat factor)
{
	GLKMatrix4 m0 = SCNMatrix4ToGLKMatrix4(scnm0);
	GLKMatrix4 mf = SCNMatrix4ToGLKMatrix4(scnmf);
	GLKVector4 p0 = GLKMatrix4GetColumn(m0, 3);
	GLKVector4 pf = GLKMatrix4GetColumn(mf, 3);
	GLKQuaternion q0 = GLKQuaternionMakeWithMatrix4(m0);
	GLKQuaternion qf = GLKQuaternionMakeWithMatrix4(mf);

	GLKVector4 pTmp = GLKVector4Lerp(p0, pf, factor);
	GLKQuaternion qTmp = GLKQuaternionSlerp(q0, qf, factor);
	GLKMatrix4 rTmp = GLKMatrix4MakeWithQuaternion(qTmp);

	SCNMatrix4 transform = { rTmp.m00, rTmp.m01, rTmp.m02, 0.0,
		rTmp.m10, rTmp.m11, rTmp.m12, 0.0,
		rTmp.m20, rTmp.m21, rTmp.m22, 0.0,
		pTmp.x,   pTmp.y,   pTmp.z, 1.0 };

	return transform;
}

/*! Jump with variable heights based on how many times this method gets called.
 */
- (void)performJumpAndStop:(BOOL)stop
{
	jumpForce = 13.0f;
	if (stop == YES) {
		return;
	}

	_jumpBoost += 0.0005f;
	CGFloat maxBoost = self.walkSpeed * 2.0f;
	if (_jumpBoost > maxBoost) {
		_jumpBoost = maxBoost;
	} else {
		_velocity.y += 0.55f;
	}

	if (self.jumping == NO) {
		self.jumping = YES;
		self.launching = YES;
		self.inJumpAnimation = YES;
	}
}

- (void)setInJumpAnimation:(BOOL)jumpAnimState
{
	if (_inJumpAnimation == jumpAnimState) {
		return;
	}

	_inJumpAnimation = jumpAnimState;
	if (_inJumpAnimation == YES) {
		// Launching YES means we are in the preflight jump animation.
		self.launching = YES;

		CAAnimation *anim = [self cachedAnimationForKey:[AAPLPlayerCharacter keyForAnimationType:AAPLCharacterAnimationJump]];
		[self.mainSkeleton removeAllAnimations];
		[self.mainSkeleton addAnimation:anim forKey:[AAPLPlayerCharacter keyForAnimationType:AAPLCharacterAnimationJump]];
		[self turnOffWalkingDust];
	} else {
		self.launching = NO;
	}
}

- (void)setInRunAnimation:(BOOL)runAnimState
{
	if (_inRunAnimation == runAnimState) {
		return;
	}
	_inRunAnimation = runAnimState;

	// If we are running, then
	if (_inRunAnimation == YES) {
		self.walkSpeed = _baseWalkSpeed * 2;

		NSString *runKey = [AAPLPlayerCharacter keyForAnimationType:AAPLCharacterAnimationRun];
		NSString *idleKey = [AAPLPlayerCharacter keyForAnimationType:AAPLCharacterAnimationIdle];

		CAAnimation *runAnim = [self cachedAnimationForKey:runKey];
		[self.mainSkeleton removeAnimationForKey:idleKey fadeOutDuration:0.15f];
		[self.mainSkeleton addAnimation:runAnim forKey:runKey];
		// add or turn on the flow of dust particles.
		if (self.dustWalking != nil) {
			if ([self.particleSystems containsObject:self.dustWalking] == NO) {
				[self addParticleSystem:self.dustWalking];
			} else {
				self.dustWalking.birthRate = dustWalkingBirthRate;
			}
		}
	} else {
		// Fade out run and move to run stop.
		NSString *runKey = [AAPLPlayerCharacter keyForAnimationType:AAPLCharacterAnimationRun];
		NSString *runStopKey = [AAPLPlayerCharacter keyForAnimationType:AAPLCharacterAnimationIdle];
		CAAnimation *runStopAnim = [self cachedAnimationForKey:runStopKey];
		runStopAnim.fadeInDuration = 0.15f;
		runStopAnim.fadeOutDuration = 0.15f;
		[self.mainSkeleton removeAnimationForKey:runKey fadeOutDuration:0.15f];
		[self.mainSkeleton addAnimation:runStopAnim forKey:runStopKey];
		self.walkSpeed = _baseWalkSpeed;
		[self turnOffWalkingDust];
		_isWalking = NO;
	}
}

- (void)turnOffWalkingDust
{
	// Stop the flow of dust by turning the birthrate to 0.
	if (self.dustWalking != nil && [self.particleSystems containsObject:self.dustWalking]) {
		self.dustWalking.birthRate = 0;
	}
}

- (void)setWalkDirection:(WalkDirection)walkDirection
{
	// If we changed directions and are already walking
	// then play the run stop animation once.
	if (walkDirection != _walkDirection && _isWalking == YES && self.launching == NO && self.jumping == NO) {
		if (self.ChangingDirection == NO) {
			[self.mainSkeleton removeAllAnimations];
			NSString *key = [AAPLPlayerCharacter keyForAnimationType:AAPLCharacterAnimationRunStop];
			CAAnimation *anim = [self cachedAnimationForKey:key];
			[self.mainSkeleton addAnimation:anim forKey:key];
			self.ChangingDirection = YES;
			self.walkSpeed = _baseWalkSpeed;
		}
	} else {
		_walkDirection = walkDirection;
	}
}

- (void)setInHitAnimation:(BOOL)GetHitAnimState
{
	_inHitAnimation = GetHitAnimState;

	// Play the get hit animation.
	CAAnimation *anim = [self cachedAnimationForKey:[AAPLPlayerCharacter keyForAnimationType:AAPLCharacterAnimationGetHit]];
	[anim setRepeatCount:0];
	[anim setFadeInDuration:0.15];
	[anim setFadeOutDuration:0.15];
	[self.mainSkeleton addAnimation:anim forKey:[AAPLPlayerCharacter keyForAnimationType:AAPLCharacterAnimationGetHit]];

	_inHitAnimation = NO;

	[[AAPLGameSimulation sim] playSound:@"coconuthit.caf"];
}

@end
