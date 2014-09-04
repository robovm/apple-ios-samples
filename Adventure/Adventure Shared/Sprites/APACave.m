/*
     File: APACave.m
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

#import "APACave.h"
#import "APAGraphicsUtilities.h"
#import "APAMultiplayerLayeredCharacterScene.h"
#import "APAParallaxSprite.h"
#import "APAGoblin.h"
#import "APASpawnAI.h"

#define kCaveCollisionRadius 90
#define kCaveCapacity 50


@interface APACave ()
@property (nonatomic) NSMutableArray *activeGoblins;
@property (nonatomic) NSMutableArray *inactiveGoblins;
@property (nonatomic) SKEmitterNode *smokeEmitter;
@end

@implementation APACave

#pragma mark - Initialization
- (id)initAtPosition:(CGPoint)position {
    self = [super initWithSprites:@[ [[self caveBase] copy], [[self caveTop] copy]] atPosition:position usingOffset:50.0f];
    
    if (self) {
        _timeUntilNextGenerate = 5.0f + (APA_RANDOM_0_1() * 5.0f);
        
        _activeGoblins = [[NSMutableArray alloc] init];
        _inactiveGoblins = [[NSMutableArray alloc] init];
        
        for (int i = 0; i < kCaveCapacity; i++) {
            APAGoblin *goblin = [[APAGoblin alloc] initAtPosition:self.position];
            goblin.cave = self;
            [(NSMutableArray *)_inactiveGoblins addObject:goblin];
        }
        
        self.movementSpeed = 0.0f;

        [self pickRandomFacingForPosition:position];
        
        self.name = @"GoblinCave";
        
        // Make it AWARE!
        self.intelligence = [[APASpawnAI alloc] initWithCharacter:self target:nil];
    }
    
    return self;
}

- (void)pickRandomFacingForPosition:(CGPoint)position {
    APAMultiplayerLayeredCharacterScene *scene = [self characterScene];
    
    // Pick best random facing from 8 test rays.
    CGFloat maxDoorCanSee = 0.0;
    CGFloat preferredZRotation = 0.0;
    for (int i = 0; i < 8; i++) {
        CGFloat testZ = APA_RANDOM_0_1() * (M_PI * 2.0f);
        CGPoint pos2 = CGPointMake( -sinf(testZ)*1024 + position.x , cosf(testZ)*1024 + position.y );
        CGFloat dist = [scene distanceToWall:position from:pos2];
        if (dist > maxDoorCanSee) {
            maxDoorCanSee = dist;
            preferredZRotation = testZ;
        }
    }
    self.zRotation = preferredZRotation;
}

#pragma mark - Overridden Methods
- (void)configurePhysicsBody {
    self.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:kCaveCollisionRadius];
    self.physicsBody.dynamic = NO;
    
    self.animated = NO;
    self.zPosition = -0.85;
    
    // Our object type for collisions.
    self.physicsBody.categoryBitMask = APAColliderTypeCave;
    
    // Collides with these objects.
    self.physicsBody.collisionBitMask = APAColliderTypeProjectile | APAColliderTypeHero;
    
    // We want notifications for colliding with these objects.
    self.physicsBody.contactTestBitMask = APAColliderTypeProjectile;
}

- (void)reset {
    [super reset];
    
    self.animated = NO;
}

- (void)collidedWith:(SKPhysicsBody *)other {
    if (self.health > 0.0f) {
        if (other.categoryBitMask & APAColliderTypeProjectile) {
            CGFloat damage = 10.0f;
            BOOL killed = [self applyDamage:damage fromProjectile:other.node];
            if (killed) {
                [[self characterScene] addToScore:25 afterEnemyKillWithProjectile:other.node];
            }
        }
    }
}

- (BOOL)applyDamage:(CGFloat)damage {
    BOOL killed = [super applyDamage:damage];
    if (killed) {
        return YES;
    }
    
    // Show damage.
    [self updateSmokeForHealth];
    
    // Show damage on parallax stacks.
    for (SKNode *node in self.children) {
        [node runAction:[self damageAction]];
    }
    return NO;
}

- (void)performDeath {
    [super performDeath];
    
    SKNode *splort = [[self deathSplort] copy];
    splort.zPosition = -1.0;
    splort.zRotation = self.virtualZRotation;
    splort.position = self.position;
    splort.alpha = 0.1;
    [splort runAction:[SKAction fadeAlphaTo:1.0 duration:0.5]];
    
    APAMultiplayerLayeredCharacterScene *scene = [self characterScene];
    
    [scene addNode:splort atWorldLayer:APAWorldLayerBelowCharacter];
    
    [self runAction:[SKAction sequence:@[
                                         [SKAction fadeAlphaTo:0.0f duration:0.5f],
                                         [SKAction removeFromParent],
                                        ]]];
    
    [self.smokeEmitter runAction:[SKAction sequence:@[
                                                      [SKAction waitForDuration:2.0f],
                                                      [SKAction runBlock:^{
                                                          [self.smokeEmitter setParticleBirthRate:2.0f];
                                                      }],
                                                      [SKAction waitForDuration:2.0f],
                                                      [SKAction runBlock:^{
                                                          [self.smokeEmitter setParticleBirthRate:0.0f];
                                                      }],
                                                      [SKAction waitForDuration:10.0f],
                                                      [SKAction fadeAlphaTo:0.0f duration:0.5f],
                                                      [SKAction removeFromParent],
                                                     ]]];
    [(NSMutableArray *)self.inactiveGoblins removeAllObjects];
}

#pragma mark - Damage Smoke Emitter
- (void)updateSmokeForHealth {
    // Add smoke if health is < 75.
    if (self.health > 75.0f || self.smokeEmitter != nil) {
        return;
    }

    SKEmitterNode *emitter = [[self deathEmitter] copy];
    emitter.position = self.position;
    emitter.zPosition = -0.8;
    self.smokeEmitter = emitter;
    APAMultiplayerLayeredCharacterScene *scene = (id)[self scene];
    [scene addNode:emitter atWorldLayer:APAWorldLayerAboveCharacter];
}

#pragma mark - Loop Update
- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)interval {
    [super updateWithTimeSinceLastUpdate:interval]; // this will update the SpawnAI
    
    // Update our goblins.
    for (APAGoblin *goblin in self.activeGoblins) {
        [goblin updateWithTimeSinceLastUpdate:interval];
    }
}

#pragma mark - Goblin Targets
- (void)stopGoblinsFromTargettingHero:(APACharacter *)target {
    for (APAGoblin *goblin in self.activeGoblins) {
        [goblin.intelligence clearTarget:target];
    }
}

#pragma mark - Generating and Recycling
- (void)generate {
    if (sGlobalCap > 0 && sGlobalAllocation >= sGlobalCap) {
        return;
    }
    
    APACharacter *object = [self.inactiveGoblins lastObject];
    if (!object) {
        return;
    }
    
    CGFloat offset = kCaveCollisionRadius * 0.75f;
    CGFloat rot = APA_POLAR_ADJUST(self.virtualZRotation);
    object.position = APAPointByAddingCGPoints(self.position, CGPointMake(cos(rot)*offset, sin(rot)*offset));
    
    APAMultiplayerLayeredCharacterScene *scene = [self characterScene];
    [object addToScene:scene];

    object.zPosition = -1.0f;
    
    [object fadeIn:0.5f];
    
    [(NSMutableArray *)self.inactiveGoblins removeObject:object];
    [(NSMutableArray *)self.activeGoblins addObject:object];
    sGlobalAllocation++;
}

- (void)recycle:(APAGoblin *)goblin {
    [goblin reset];
    [(NSMutableArray *)self.activeGoblins removeObject:goblin];
    [(NSMutableArray *)self.inactiveGoblins addObject:goblin];
    
    sGlobalAllocation--;
}

#pragma mark - Cap on Generation
static int sGlobalCap = 0;

+ (int)globalGoblinCap {
    return sGlobalCap;
}

+ (void)setGlobalGoblinCap:(int)amount {
    sGlobalCap = amount;
}

static int sGlobalAllocation = 0;

#pragma mark - Shared Resources
+ (void)loadSharedAssets {
    [super loadSharedAssets];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:@"Environment"];

        SKEmitterNode *fire = [SKEmitterNode apa_emitterNodeWithEmitterNamed:@"CaveFire"];
        fire.zPosition = 1;
        
        SKEmitterNode *smoke = [SKEmitterNode apa_emitterNodeWithEmitterNamed:@"CaveFireSmoke"];
        
        SKNode *torch = [[SKNode alloc] init];
        [torch addChild:fire];
        [torch addChild:smoke];
        
        sSharedCaveBase = [SKSpriteNode spriteNodeWithTexture:[atlas textureNamed:@"cave_base.png"]];
        
        // Add two torches either side of the entrance.
        torch.position = CGPointMake(83, 83);
        [sSharedCaveBase addChild:torch];
        SKNode *torchB = [torch copy];
        torchB.position = CGPointMake(-83, 83);
        [sSharedCaveBase addChild:torchB];
        
        sSharedCaveTop = [SKSpriteNode spriteNodeWithTexture:[atlas textureNamed:@"cave_top.png"]];
        
        sSharedDeathSplort = [SKSpriteNode spriteNodeWithTexture:[atlas textureNamed:@"cave_destroyed.png"]];
        
        sSharedDamageEmitter = [SKEmitterNode apa_emitterNodeWithEmitterNamed:@"CaveDamage"];
        sSharedDeathEmitter = [SKEmitterNode apa_emitterNodeWithEmitterNamed:@"CaveDeathSmoke"];
        
        sSharedDamageAction = [SKAction sequence:@[
                                                   [SKAction colorizeWithColor:[SKColor redColor] colorBlendFactor:1.0 duration:0.0],
                                                   [SKAction waitForDuration:0.25],
                                                   [SKAction colorizeWithColorBlendFactor:0.0 duration:0.1],
                                                   ]];
    });
}

static SKNode *sSharedCaveBase = nil;
- (SKNode *)caveBase {
    return sSharedCaveBase;
}

static SKNode *sSharedCaveTop = nil;
- (SKNode *)caveTop {
    return sSharedCaveTop;
}

static SKSpriteNode *sSharedDeathSplort = nil;
- (SKSpriteNode *)deathSplort {
    return sSharedDeathSplort;
}

static SKEmitterNode *sSharedDamageEmitter = nil;
- (SKEmitterNode *)damageEmitter {
    return sSharedDamageEmitter;
}

static SKEmitterNode *sSharedDeathEmitter = nil;
- (SKEmitterNode *)deathEmitter {
    return sSharedDeathEmitter;
}

static SKAction *sSharedDamageAction = nil;
- (SKAction *)damageAction {
    return sSharedDamageAction;
}

@end
