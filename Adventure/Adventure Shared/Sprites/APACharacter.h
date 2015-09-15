/*
     File: APACharacter.h
 Abstract: n/a
  Version: 1.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

/* Used by the move: method to move a character in a given direction. */
typedef enum : uint8_t {
    APAMoveDirectionForward = 0,
    APAMoveDirectionLeft,
    APAMoveDirectionRight,
    APAMoveDirectionBack,
} APAMoveDirection;

/* The different animation states of an animated character. */
typedef enum : uint8_t {
    APAAnimationStateIdle = 0,
    APAAnimationStateWalk,
    APAAnimationStateAttack,
    APAAnimationStateGetHit,
    APAAnimationStateDeath,
    kAnimationStateCount
} APAAnimationState;

/* Bitmask for the different entities with physics bodies. */
typedef enum : uint8_t {
    APAColliderTypeHero             = 1,
    APAColliderTypeGoblinOrBoss     = 2,
    APAColliderTypeProjectile       = 4,
    APAColliderTypeWall             = 8,
    APAColliderTypeCave             = 16
} APAColliderType;


#define kMovementSpeed 200.0
#define kRotationSpeed 0.06

#define kCharacterCollisionRadius   40
#define kProjectileCollisionRadius  15

#define kDefaultNumberOfWalkFrames 28
#define kDefaultNumberOfIdleFrames 28


@class APAMultiplayerLayeredCharacterScene;
#import "APAParallaxSprite.h"

@interface APACharacter : APAParallaxSprite

@property (nonatomic, getter=isDying) BOOL dying;
@property (nonatomic, getter=isAttacking) BOOL attacking;
@property (nonatomic) CGFloat health;
@property (nonatomic, getter=isAnimated) BOOL animated;
@property (nonatomic) CGFloat animationSpeed;
@property (nonatomic) CGFloat movementSpeed;

@property (nonatomic) NSString *activeAnimationKey;
@property (nonatomic) APAAnimationState requestedAnimation;

/* Preload shared animation frames, emitters, etc. */
+ (void)loadSharedAssets;

/* Initialize a standard sprite. */
- (id)initWithTexture:(SKTexture *)texture atPosition:(CGPoint)position;

/* Initialize a parallax sprite. */
- (id)initWithSprites:(NSArray *)sprites atPosition:(CGPoint)position usingOffset:(CGFloat)offset;

/* Reset a character for reuse. */
- (void)reset;

/* Overridden Methods. */
- (void)animationDidComplete:(APAAnimationState)animation;
- (void)collidedWith:(SKPhysicsBody *)other;
- (void)performDeath;
- (void)configurePhysicsBody;

/* Assets - should be overridden for animated characters. */
- (NSArray *)idleAnimationFrames;
- (NSArray *)walkAnimationFrames;
- (NSArray *)attackAnimationFrames;
- (NSArray *)getHitAnimationFrames;
- (NSArray *)deathAnimationFrames;
- (SKEmitterNode *)damageEmitter;   // provide an emitter to show damage applied to character
- (SKAction *)damageAction;         // action to run when damage is applied

/* Applying Damage - i.e., decrease health. */
- (BOOL)applyDamage:(CGFloat)damage;
- (BOOL)applyDamage:(CGFloat)damage fromProjectile:(SKNode *)projectile; // use projectile alpha to determine potency

/* Loop Update - called once per frame. */
- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)interval;

/* Orientation, Movement, and Attacking. */
- (void)move:(APAMoveDirection)direction withTimeInterval:(NSTimeInterval)timeInterval;
- (CGFloat)faceTo:(CGPoint)position;
- (void)moveTowards:(CGPoint)position withTimeInterval:(NSTimeInterval)timeInterval;
- (void)moveInDirection:(CGPoint)direction withTimeInterval:(NSTimeInterval)timeInterval;
- (void)performAttackAction;

/* Scenes. */
- (void)addToScene:(APAMultiplayerLayeredCharacterScene *)scene; // also adds the shadow blob
- (APAMultiplayerLayeredCharacterScene *)characterScene; // returns the MultiplayerLayeredCharacterScene this character is in

/* Animation. */
- (void)fadeIn:(CGFloat)duration;

@end
