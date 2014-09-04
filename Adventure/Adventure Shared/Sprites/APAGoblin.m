/*
     File: APAGoblin.m
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

#import "APAGoblin.h"
#import "APACave.h"
#import "APAGraphicsUtilities.h"
#import "APAChaseAI.h"
#import "APAAdventureScene.h"

#define kMinimumGoblinSize 0.5
#define kGoblinSizeVariance 0.350
#define kGoblinCollisionRadius 10

#define kGoblinAttackFrames 33
#define kGoblinDeathFrames 31
#define kGoblinGetHitFrames 25

@implementation APAGoblin

#pragma mark - Initialization
- (id)initAtPosition:(CGPoint)position {
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:@"Goblin_Idle"];
    self = [super initWithTexture:[atlas textureNamed:@"goblin_idle_0001.png"] atPosition:position];
    
    if (self) {
        self.movementSpeed = kMovementSpeed * APA_RANDOM_0_1();                     // set a random movement speed
        self.scale = kMinimumGoblinSize + (APA_RANDOM_0_1() * kGoblinSizeVariance); // and a random goblin size
        self.zPosition = -0.25;
        self.name = @"Enemy";
        
        // Make it AWARE!
        self.intelligence = [[APAChaseAI alloc] initWithCharacter:self target:nil];
    }
    
    return self;
}

#pragma mark - Overridden Methods
- (void)configurePhysicsBody {
    self.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:kGoblinCollisionRadius];
    
    // Our object type for collisions.
    self.physicsBody.categoryBitMask = APAColliderTypeGoblinOrBoss;
    
    // Collides with these objects.
    self.physicsBody.collisionBitMask = APAColliderTypeGoblinOrBoss | APAColliderTypeHero | APAColliderTypeProjectile | APAColliderTypeWall | APAColliderTypeCave;
    
    // We want notifications for colliding with these objects.
    self.physicsBody.contactTestBitMask = APAColliderTypeProjectile;
}

- (void)reset {
    [super reset];
    
    self.alpha = 1.0f;
    [self removeAllChildren];
    
    [self configurePhysicsBody];
}

- (void)animationDidComplete:(APAAnimationState)animationState {
    [super animationDidComplete:animationState];
    switch (animationState) {
        case APAAnimationStateDeath:{
            [self removeAllActions];
            [self runAction:[SKAction sequence:@[[SKAction waitForDuration:0.75],
                                                 [SKAction fadeOutWithDuration:1.0f],
                                                 [SKAction runBlock:^{
                                                     [self removeFromParent];
                                                     [self.cave recycle:self];
                                                 }]]
                             ]];
            break;}
            
        default:
            break;
    }
}

- (void)collidedWith:(SKPhysicsBody *)other {
    if (self.dying) {
        return;
    }
    
    if (other.categoryBitMask & APAColliderTypeProjectile) {
        // Apply random damage of either 100% or 50%.
        self.requestedAnimation = APAAnimationStateGetHit;
        CGFloat damage = 100.0f;
        if ((arc4random_uniform(2)) == 0) {
            damage = 50.0f;
        }
        
        BOOL killed = [self applyDamage:damage fromProjectile:other.node];
        if (killed) {
            [[self characterScene] addToScore:10 afterEnemyKillWithProjectile:other.node];
        }
    }
}

- (void)performDeath {
    [self removeAllActions];
    
    SKSpriteNode *splort = [[self deathSplort] copy];
    splort.zPosition = -1.0;
    splort.zRotation = APA_RANDOM_0_1() * M_PI;
    splort.position = self.position;
    splort.alpha = 0.5;
    [[self characterScene] addNode:splort atWorldLayer:APAWorldLayerGround];
    [splort runAction:[SKAction fadeOutWithDuration:10.0f]];
    
    [super performDeath];
    
    self.physicsBody.collisionBitMask = 0;
    self.physicsBody.contactTestBitMask = 0;
    self.physicsBody.categoryBitMask = 0;
    self.physicsBody = nil;
}

#pragma mark - Shared Assets
+ (void)loadSharedAssets {
    [super loadSharedAssets];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:@"Environment"];

        sSharedIdleAnimationFrames = APALoadFramesFromAtlas(@"Goblin_Idle", @"goblin_idle_", kDefaultNumberOfIdleFrames);
        sSharedWalkAnimationFrames = APALoadFramesFromAtlas(@"Goblin_Walk", @"goblin_walk_", kDefaultNumberOfWalkFrames);
        sharedAttackAnimationFrames = APALoadFramesFromAtlas(@"Goblin_Attack", @"goblin_attack_", kGoblinAttackFrames);
        sharedGetHitAnimationFrames = APALoadFramesFromAtlas(@"Goblin_GetHit", @"goblin_getHit_", kGoblinGetHitFrames);
        sharedDeathAnimationFrames = APALoadFramesFromAtlas(@"Goblin_Death", @"goblin_death_", kGoblinDeathFrames);
        sSharedDamageEmitter = [SKEmitterNode apa_emitterNodeWithEmitterNamed:@"Damage"];
        sSharedDeathSplort = [SKSpriteNode spriteNodeWithTexture:[atlas textureNamed:@"minionSplort.png"]];
        sSharedDamageAction = [SKAction sequence:@[[SKAction colorizeWithColor:[SKColor whiteColor] colorBlendFactor:1.0 duration:0.0],
                                                   [SKAction waitForDuration:0.75],
                                                   [SKAction colorizeWithColorBlendFactor:0.0 duration:0.1]
                                                   ]];
    });
}

static SKEmitterNode *sSharedDamageEmitter = nil;
- (SKEmitterNode *)damageEmitter {
    return sSharedDamageEmitter;
}

static SKAction *sSharedDamageAction = nil;
- (SKAction *)damageAction {
    return sSharedDamageAction;
}

static NSArray *sSharedIdleAnimationFrames = nil;
- (NSArray *)idleAnimationFrames {
    return sSharedIdleAnimationFrames;
}

static NSArray *sSharedWalkAnimationFrames = nil;
- (NSArray *)walkAnimationFrames {
    return sSharedWalkAnimationFrames;
}

static NSArray *sharedAttackAnimationFrames = nil;
- (NSArray *)attackAnimationFrames {
    return sharedAttackAnimationFrames;
}

static NSArray *sharedGetHitAnimationFrames = nil;
- (NSArray *)getHitAnimationFrames {
    return sharedGetHitAnimationFrames;
}

static NSArray *sharedDeathAnimationFrames = nil;
- (NSArray *)deathAnimationFrames {
    return sharedDeathAnimationFrames;
}

static SKSpriteNode *sSharedDeathSplort = nil;
- (SKSpriteNode *)deathSplort {
    return sSharedDeathSplort;
}

@end
