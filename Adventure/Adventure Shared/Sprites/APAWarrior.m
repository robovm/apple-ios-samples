/*
     File: APAWarrior.m
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

#import "APAWarrior.h"
#import "APAGraphicsUtilities.h"
#import "APAMultiplayerLayeredCharacterScene.h"

#define kWarriorIdleFrames 29
#define kWarriorThrowFrames 10
#define kWarriorGetHitFrames 20
#define kWarriorDeathFrames 90

@implementation APAWarrior

#pragma mark - Initialization
- (id)initAtPosition:(CGPoint)position withPlayer:(APAPlayer *)player {
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:@"Warrior_Idle"];
    SKTexture *texture = [atlas textureNamed:@"warrior_idle_0001.png"];
    
    return [super initWithTexture:texture atPosition:position withPlayer:player];
}

#pragma mark - Shared Assets
+ (void)loadSharedAssets {
    [super loadSharedAssets];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:@"Environment"];

        sSharedProjectile = [SKSpriteNode spriteNodeWithTexture:[atlas textureNamed:@"warrior_throw_hammer.png"]];
        sSharedProjectile.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:kProjectileCollisionRadius];
        sSharedProjectile.name = @"Projectile";
        sSharedProjectile.physicsBody.categoryBitMask = APAColliderTypeProjectile;
        sSharedProjectile.physicsBody.collisionBitMask = APAColliderTypeWall;
        sSharedProjectile.physicsBody.contactTestBitMask = sSharedProjectile.physicsBody.collisionBitMask;
        
        sSharedProjectileEmitter = [SKEmitterNode apa_emitterNodeWithEmitterNamed:@"WarriorProjectile"];
        sSharedIdleAnimationFrames = APALoadFramesFromAtlas(@"Warrior_Idle", @"warrior_idle_", kWarriorIdleFrames);
        sSharedWalkAnimationFrames = APALoadFramesFromAtlas(@"Warrior_Walk", @"warrior_walk_", kDefaultNumberOfWalkFrames);
        sharedAttackAnimationFrames = APALoadFramesFromAtlas(@"Warrior_Attack", @"warrior_attack_", kWarriorThrowFrames);
        sharedGetHitAnimationFrames = APALoadFramesFromAtlas(@"Warrior_GetHit", @"warrior_getHit_", kWarriorGetHitFrames);
        sharedDeathAnimationFrames = APALoadFramesFromAtlas(@"Warrior_Death", @"warrior_death_", kWarriorDeathFrames);
        sSharedDamageAction = [SKAction sequence:@[[SKAction colorizeWithColor:[SKColor redColor] colorBlendFactor:10.0 duration:0.0],
                                                   [SKAction waitForDuration:0.5],
                                                   [SKAction colorizeWithColorBlendFactor:0.0 duration:0.25]
                                                   ]];
    });
}

static SKSpriteNode *sSharedProjectile = nil;
- (SKSpriteNode *)projectile {
    return sSharedProjectile;
}

static SKEmitterNode *sSharedProjectileEmitter = nil;
- (SKEmitterNode *)projectileEmitter {
    return sSharedProjectileEmitter;
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

static SKAction *sSharedDamageAction = nil;
- (SKAction *)damageAction {
    return sSharedDamageAction;
}

@end
