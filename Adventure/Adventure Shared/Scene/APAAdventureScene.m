/*
     File: APAAdventureScene.m
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

#import "APAAdventureScene.h"
#import "APAGraphicsUtilities.h"
#import "APATree.h"
#import "APACharacter.h"
#import "APAWarrior.h"
#import "APAArcher.h"
#import "APACave.h"
#import "APABoss.h"
#import "APAGoblin.h"
#import "APAPlayer.h"


// Uncomment this to cheat and move yourself near the boss for testing.
//#define MOVE_NEAR_TO_BOSS 1


@interface APAAdventureScene () <SKPhysicsContactDelegate>

@property (nonatomic) NSMutableArray *players;            // array of player objects or NSNull for no player
@property (nonatomic) APAPlayer *defaultPlayer;           // player '1' controlled by keyboard/touch

@property (nonatomic, readwrite) NSMutableArray *heroes;  // our fearless adventurers
@property (nonatomic) NSMutableArray *goblinCaves;        // whence cometh goblins

@property (nonatomic) APADataMapRef levelMap;             // locations of caves/spawn points/etc
@property (nonatomic) APATreeMapRef treeMap;              // locations of trees

@property (nonatomic) APABoss *levelBoss;                 // the big boss character
@property (nonatomic) NSMutableArray *particleSystems;    // particle emitter nodes
@property (nonatomic) NSMutableArray *parallaxSprites;    // all the parallax sprites in this scene
@property (nonatomic) NSMutableArray *trees;              // all the trees in the scene
@end

@implementation APAAdventureScene

@synthesize heroes = _heroes;

#pragma mark - Initialization and Deallocation
- (id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    if (self) {
        _heroes = [[NSMutableArray alloc] init];
        _goblinCaves = [[NSMutableArray alloc] init];
        
        _particleSystems = [[NSMutableArray alloc] init];
        _parallaxSprites = [[NSMutableArray alloc] init];
        _trees = [[NSMutableArray alloc] init];
        
        // Build level and tree maps from map_collision.png and map_foliage.png respectively.
        _levelMap = APACreateDataMap(@"map_level.png");
        _treeMap = APACreateDataMap(@"map_trees.png");
                
        [APACave setGlobalGoblinCap:32];
        
        [self buildWorld];
                
        // Center the camera on the hero spawn point.
        CGPoint startPosition = self.defaultSpawnPoint;
        [self centerWorldOnPosition:startPosition];
    }
    return self;
}

- (void)dealloc {
    free(_levelMap);
    _levelMap = NULL;
}

#pragma mark - World Building
- (void)buildWorld {
    NSLog(@"Building the world");
    
    // Configure physics for the world.
    self.physicsWorld.gravity = CGVectorMake(0.0f, 0.0f); // no gravity
    self.physicsWorld.contactDelegate = self;
    
    [self addBackgroundTiles];
    
    [self addSpawnPoints];
    
    [self addTrees];
    
    [self addCollisionWalls];
}

- (void)addBackgroundTiles {
    // Tiles should already have been pre-loaded in +loadSceneAssets.
    for (SKNode *tileNode in [self backgroundTiles]) {
        [self addNode:tileNode atWorldLayer:APAWorldLayerGround];
    }
}

- (void)addSpawnPoints {
    // Add goblin caves and set hero/boss spawn points.
    for (int y = 0; y < kLevelMapSize; y++) {
        for (int x = 0; x < kLevelMapSize; x++) {
            CGPoint location = CGPointMake(x, y);
            APADataMap spot = [self queryLevelMap:location];
            
            // Get the world space point for this level map pixel.
            CGPoint worldPoint = [self convertLevelMapPointToWorldPoint:location];
            
            if (spot.bossLocation <= 200) {
                self.levelBoss = [[APABoss alloc] initAtPosition:worldPoint];
                [self.levelBoss addToScene:self];
                
            } else if (spot.goblinCaveLocation >= 200) {
                
                APACave *cave = [[APACave alloc] initAtPosition:worldPoint];
                [self.goblinCaves addObject:cave];
                [self.parallaxSprites addObject:cave];
                [cave addToScene:self];

            } else if (spot.heroSpawnLocation >= 200) {
                
                self.defaultSpawnPoint = worldPoint; // there's only one
            }
        }
    }
}

- (void)addTrees {
    for (int y = 0; y < kLevelMapSize; y++) {
        for (int x = 0; x < kLevelMapSize; x++) {
            CGPoint location = CGPointMake(x, y);
            APATreeMap spot = [self queryTreeMap:location];
            
            CGPoint treePos = [self convertLevelMapPointToWorldPoint:location];
            APAWorldLayer treeLayer = APAWorldLayerTop;
            APATree *tree = nil;
            
            if (spot.smallTreeLocation >= 200) {
                // Create small tree at this location.
                treeLayer = APAWorldLayerAboveCharacter;
                tree = [[self sharedSmallTree] copy];
                
            } else if (spot.bigTreeLocation >= 200) {
                // Create big tree with leaf emitters at this position.
                tree = [[self sharedBigTree] copy];
                
                SKEmitterNode *emitter = nil;
                // Pick one of the two leaf emitters for this tree.
                if (arc4random_uniform(2) == 1) {
                    emitter = [[self sharedLeafEmitterA] copy];
                } else {
                    emitter = [[self sharedLeafEmitterB] copy];
                }
                
                emitter.position = treePos;
                emitter.paused = YES;
                [self addNode:emitter atWorldLayer:APAWorldLayerAboveCharacter];
                [self.particleSystems addObject:emitter];
            } else {
                continue;
            }
            
            tree.position = treePos;
            tree.zRotation = APA_RANDOM_0_1() * (M_PI * 2.0f);
            [self addNode:tree atWorldLayer:treeLayer];
            [self.parallaxSprites addObject:tree];
            [self.trees addObject:tree];
        }
    }
    
    free(self.treeMap);
    self.treeMap = NULL;
}

- (void)addCollisionWalls {
    NSDate *startDate = [NSDate date];
    unsigned char *filled = alloca(kLevelMapSize * kLevelMapSize);
    memset(filled, 0, kLevelMapSize * kLevelMapSize);
    
    int numVolumes = 0;
    int numBlocks = 0;
    
    // Add horizontal collision walls.
    for (int y = 0; y < kLevelMapSize; y++) { // iterate in horizontal rows
        for (int x = 0; x < kLevelMapSize; x++) {
            CGPoint location = CGPointMake(x, y);
            APADataMap spot = [self queryLevelMap:location];
            
            // Get the world space point for this pixel.
            CGPoint worldPoint = [self convertLevelMapPointToWorldPoint:location];
            
            if (spot.wall < 200) {
                continue; // no wall
            }
            
            int horizontalDistanceFromLeft = x;
            APADataMap nextSpot = spot;
            while (horizontalDistanceFromLeft < kLevelMapSize && nextSpot.wall >= 200 && !filled[(y * kLevelMapSize) + horizontalDistanceFromLeft]) {
                horizontalDistanceFromLeft++;
                nextSpot = [self queryLevelMap:CGPointMake(horizontalDistanceFromLeft, y)];
            }
            
            int wallWidth = (horizontalDistanceFromLeft - x);
            int verticalDistanceFromTop = y;
            
            if (wallWidth > 8) {
                nextSpot = spot;
                while (verticalDistanceFromTop < kLevelMapSize && nextSpot.wall >= 200) {
                    verticalDistanceFromTop++;
                    nextSpot = [self queryLevelMap:CGPointMake(x + (wallWidth / 2), verticalDistanceFromTop)];
                }
                
                int wallHeight = (verticalDistanceFromTop - y);
                for (int j = y; j < verticalDistanceFromTop; j++) {
                    for (int i = x; i < horizontalDistanceFromLeft; i++) {
                        filled[(j * kLevelMapSize) + i] = 255;
                        numBlocks++;
                    }
                }
                
                [self addCollisionWallAtWorldPoint:worldPoint withWidth:kLevelMapDivisor * wallWidth height:kLevelMapDivisor * wallHeight];
                numVolumes++;
            }
        }
    }
    
    // Add vertical collision walls.
    for (int x = 0; x < kLevelMapSize; x++) { // iterate in vertical rows
        for (int y = 0; y < kLevelMapSize; y++) {
            CGPoint location = CGPointMake(x, y);
            APADataMap spot = [self queryLevelMap:location];
            
            // Get the world space point for this pixel.
            CGPoint worldPoint = [self convertLevelMapPointToWorldPoint:location];
            
            if (spot.wall < 200 || filled[(y * kLevelMapSize) + x]) {
                continue; // no wall, or already filled from X collision walls
            }

            int verticalDistanceFromTop = y;
            APADataMap nextSpot = spot;
            while (verticalDistanceFromTop < kLevelMapSize && nextSpot.wall >= 200 && !filled[(verticalDistanceFromTop * kLevelMapSize) + x]) {
                verticalDistanceFromTop++;
                nextSpot = [self queryLevelMap:CGPointMake(x, verticalDistanceFromTop)];
            };
            
            int wallHeight = (verticalDistanceFromTop - y);
            int horizontalDistanceFromLeft = x;
            
            if (wallHeight > 8) {
                nextSpot = spot;
                while (horizontalDistanceFromLeft < kLevelMapSize && nextSpot.wall >= 200) {
                    horizontalDistanceFromLeft++;
                    nextSpot = [self queryLevelMap:CGPointMake(horizontalDistanceFromLeft, y + (wallHeight / 2))];
                };
                
                int wallLength = (horizontalDistanceFromLeft - x);
                for (int j = y; j < verticalDistanceFromTop; j++) {
                    for (int i = x; i < horizontalDistanceFromLeft; i++) {
                        filled[(j * kLevelMapSize) + i] = 255;
                        numBlocks++;
                    }
                }
                
                [self addCollisionWallAtWorldPoint:worldPoint withWidth:kLevelMapDivisor * wallLength height:kLevelMapDivisor * wallHeight];
                numVolumes++;
            }
        }
    }
    
    NSLog(@"converted %d collision blocks into %d volumes in %f seconds", numBlocks, numVolumes, [[NSDate date] timeIntervalSinceDate:startDate]);
}

- (void)addCollisionWallAtWorldPoint:(CGPoint)worldPoint withWidth:(CGFloat)width height:(CGFloat)height {
    CGRect rect = CGRectMake(0, 0, width, height);
    
    SKNode *wallNode = [SKNode node];
    wallNode.position = CGPointMake(worldPoint.x + rect.size.width * 0.5, worldPoint.y - rect.size.height * 0.5);
    wallNode.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:rect.size];
    wallNode.physicsBody.dynamic = NO;
    wallNode.physicsBody.categoryBitMask = APAColliderTypeWall;
    wallNode.physicsBody.collisionBitMask = 0;
    
    [self addNode:wallNode atWorldLayer:APAWorldLayerGround];
}

#pragma mark - Level Start
- (void)startLevel {
    APAHeroCharacter *hero = [self addHeroForPlayer:self.defaultPlayer];
    
#ifdef MOVE_NEAR_TO_BOSS
    CGPoint bossPosition = self.levelBoss.position; // set earlier from buildWorld in addSpawnPoints
    bossPosition.x += 128;
    bossPosition.y += 512;
    hero.position = bossPosition;
#endif
    
    [self centerWorldOnCharacter:hero];
}

#pragma mark - Heroes
- (void)setDefaultPlayerHeroType:(APAHeroType)heroType {
    switch (heroType) {
        case APAHeroTypeArcher:
            self.defaultPlayer.heroClass = [APAArcher class];
            break;
            
        case APAHeroTypeWarrior:
            self.defaultPlayer.heroClass = [APAWarrior class];
            break;
    }
}

- (void)heroWasKilled:(APAHeroCharacter *)hero {
    for (APACave *cave in self.goblinCaves) {
        [cave stopGoblinsFromTargettingHero:hero];
    }
    
    [super heroWasKilled:hero];
}

#pragma mark - Loop Update
- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)timeSinceLast {
    // Update all players' heroes.
    for (APAHeroCharacter *hero in self.heroes) {
        [hero updateWithTimeSinceLastUpdate:timeSinceLast];
    }
    
    // Update the level boss.
    [self.levelBoss updateWithTimeSinceLastUpdate:timeSinceLast];
    
    // Update the caves (and in turn, their goblins).
    for (APACave *cave in self.goblinCaves) {
        [cave updateWithTimeSinceLastUpdate:timeSinceLast];
    }
}

- (void)didSimulatePhysics {
    [super didSimulatePhysics];
    
    // Get the position either of the default hero or the hero spawn point.
    APAHeroCharacter *defaultHero = self.defaultPlayer.hero;
    CGPoint position = CGPointZero;
    if (defaultHero && [self.heroes containsObject:defaultHero]) {
        position = defaultHero.position;
    } else {
        position = self.defaultSpawnPoint;
    }
    
    // Update the alphas of any trees that are near the hero (center of the camera) and therefore visible or soon to be visible.
    for (APATree *tree in self.trees) {
        if (APADistanceBetweenPoints(tree.position, position) < 1024) {
            [tree updateAlphaWithScene:self];
        }
    }
    
    if (!self.worldMovedForUpdate) {
        return;
    }
    
    // Show any nearby hidden particle systems and hide those that are too far away to be seen.
    for (SKEmitterNode *particles in self.particleSystems) {
        BOOL particlesAreVisible = APADistanceBetweenPoints(particles.position, position) < 1024;
        
        if (!particlesAreVisible && !particles.paused) {
            particles.paused = YES;
        } else if (particlesAreVisible && particles.paused) {
            particles.paused = NO;
        }
    }
    
    // Update nearby parallax sprites.
    for (APAParallaxSprite *sprite in self.parallaxSprites) {
        if (APADistanceBetweenPoints(sprite.position, position) >= 1024) {
            continue;
        };
        
        [sprite updateOffset];
    }
}

#pragma mark - Physics Delegate
- (void)didBeginContact:(SKPhysicsContact *)contact {
    // Either bodyA or bodyB in the collision could be a character.
    SKNode *node = contact.bodyA.node;
    if ([node isKindOfClass:[APACharacter class]]) {
        [(APACharacter *)node collidedWith:contact.bodyB];
    }
    
    // Check bodyB too.
    node = contact.bodyB.node;
    if ([node isKindOfClass:[APACharacter class]]) {
        [(APACharacter *)node collidedWith:contact.bodyA];
    }
    
    // Handle collisions with projectiles.
    if (contact.bodyA.categoryBitMask & APAColliderTypeProjectile || contact.bodyB.categoryBitMask & APAColliderTypeProjectile) {
        SKNode *projectile = (contact.bodyA.categoryBitMask & APAColliderTypeProjectile) ? contact.bodyA.node : contact.bodyB.node;

        [projectile runAction:[SKAction removeFromParent]];
        
        // Build up a "one shot" particle to indicate where the projectile hit.
        SKEmitterNode *emitter = [[self sharedProjectileSparkEmitter] copy];
        [self addNode:emitter atWorldLayer:APAWorldLayerAboveCharacter];
        emitter.position = projectile.position;
        APARunOneShotEmitter(emitter, 0.15f);
    }
}

#pragma mark - Mapping
- (APADataMap)queryLevelMap:(CGPoint)point {
    // Grab the level map pixel for a given x,y (upper left).
    return self.levelMap[((int)point.y) * kLevelMapSize + ((int)point.x)];
}

- (APATreeMap)queryTreeMap:(CGPoint)point {
    // Grab the tree map pixel for a given x,y (upper left).
    return self.treeMap[((int)point.y) * kLevelMapSize + ((int)point.x)];
}

- (float)distanceToWall:(CGPoint)pos0 from:(CGPoint)pos1 {
    CGPoint a = [self convertWorldPointToLevelMapPoint:pos0];
    CGPoint b = [self convertWorldPointToLevelMapPoint:pos1];
    
    CGFloat deltaX = b.x - a.x;
    CGFloat deltaY = b.y - a.y;
    CGFloat dist = APADistanceBetweenPoints(a, b);
    CGFloat inc = 1.0 / dist;
    CGPoint p = CGPointZero;
    
    for (CGFloat i = 0; i <= 1; i += inc) {
        p.x = a.x + i * deltaX;
        p.y = a.y + i * deltaY;
        
        APADataMap point = [self queryLevelMap:p];
        if (point.wall > 200) {
            CGPoint wpos2 = [self convertLevelMapPointToWorldPoint:p];
            return APADistanceBetweenPoints(pos0, wpos2);
        }
    }
    return MAXFLOAT;
}

- (BOOL)canSee:(CGPoint)pos0 from:(CGPoint)pos1 {
    CGPoint a = [self convertWorldPointToLevelMapPoint:pos0];
    CGPoint b = [self convertWorldPointToLevelMapPoint:pos1];
    
    CGFloat deltaX = b.x - a.x;
    CGFloat deltaY = b.y - a.y;
    CGFloat dist = APADistanceBetweenPoints(a, b);
    CGFloat inc = 1.0 / dist;
    CGPoint p = CGPointZero;
    
    for (CGFloat i = 0; i <= 1; i += inc) {
        p.x = a.x + i * deltaX;
        p.y = a.y + i * deltaY;
        
        APADataMap point = [self queryLevelMap:p];
        if (point.wall > 200) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - Point Conversion
- (CGPoint)convertLevelMapPointToWorldPoint:(CGPoint)location {
    // Given a level map pixel point, convert up to a world point.
    // This determines which "tile" the point falls in and centers within that tile.
    int x =   (location.x * kLevelMapDivisor) - (kWorldCenter + (kWorldTileSize/2));
    int y = -((location.y * kLevelMapDivisor) - (kWorldCenter + (kWorldTileSize/2)));
    return CGPointMake(x, y);
}

- (CGPoint)convertWorldPointToLevelMapPoint:(CGPoint)location {
    // Given a world based point, resolve to a pixel location in the level map.
    int x = (location.x + kWorldCenter) / kLevelMapDivisor;
    int y = (kWorldSize - (location.y + kWorldCenter)) / kLevelMapDivisor;
    return CGPointMake(x, y);
}

#pragma mark - Shared Assets
+ (void)loadSceneAssets {
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:@"Environment"];

    // Load archived emitters and create copyable sprites.
    sSharedProjectileSparkEmitter = [SKEmitterNode apa_emitterNodeWithEmitterNamed:@"ProjectileSplat"];
    sSharedSpawnEmitter = [SKEmitterNode apa_emitterNodeWithEmitterNamed:@"Spawn"];
    
    sSharedSmallTree = [[APATree alloc] initWithSprites:@[
                                              [SKSpriteNode spriteNodeWithTexture:[atlas textureNamed:@"small_tree_base.png"]],
                                              [SKSpriteNode spriteNodeWithTexture:[atlas textureNamed:@"small_tree_middle.png"]],
                                              [SKSpriteNode spriteNodeWithTexture:[atlas textureNamed:@"small_tree_top.png"]]] usingOffset:25.0f];
    sSharedBigTree = [[APATree alloc] initWithSprites:@[
                                                  [SKSpriteNode spriteNodeWithTexture:[atlas textureNamed:@"big_tree_base.png"]],
                                                  [SKSpriteNode spriteNodeWithTexture:[atlas textureNamed:@"big_tree_middle.png"]],
                                                  [SKSpriteNode spriteNodeWithTexture:[atlas textureNamed:@"big_tree_top.png"]]] usingOffset:150.0f];
    sSharedBigTree.fadeAlpha = YES;
    sSharedLeafEmitterA = [SKEmitterNode apa_emitterNodeWithEmitterNamed:@"Leaves_01"];
    sSharedLeafEmitterB = [SKEmitterNode apa_emitterNodeWithEmitterNamed:@"Leaves_02"];
    
    // Load the tiles that make up the ground layer.
    [self loadWorldTiles];
    
    // Load assets for all the sprites within this scene.
    [APACave loadSharedAssets];
    [APAArcher loadSharedAssets];
    [APAWarrior loadSharedAssets];
    [APAGoblin loadSharedAssets];
    [APABoss loadSharedAssets];
}

+ (void)loadWorldTiles {
    NSLog(@"Loading world tiles");
    NSDate *startDate = [NSDate date];
    
    SKTextureAtlas *tileAtlas = [SKTextureAtlas atlasNamed:@"Tiles"];
    
    sBackgroundTiles = [[NSMutableArray alloc] initWithCapacity:1024];
    for (int y = 0; y < kWorldTileDivisor; y++) {
        for (int x = 0; x < kWorldTileDivisor; x++) {
            int tileNumber = (y * kWorldTileDivisor) + x;
            SKSpriteNode *tileNode = [SKSpriteNode spriteNodeWithTexture:[tileAtlas textureNamed:[NSString stringWithFormat:@"tile%d.png", tileNumber]]];
            CGPoint position = CGPointMake((x * kWorldTileSize) - kWorldCenter,
                                           (kWorldSize - (y * kWorldTileSize)) - kWorldCenter);
            tileNode.position = position;
            tileNode.zPosition = -1.0f;
            tileNode.blendMode = SKBlendModeReplace;
            [(NSMutableArray *)sBackgroundTiles addObject:tileNode];
        }
    }
    NSLog(@"Loaded all world tiles in %f seconds", [[NSDate date] timeIntervalSinceDate:startDate]);
}

+ (void)releaseSceneAssets {
    // Get rid of everything unique to this scene (but not the characters, which might appear in other scenes).
    sBackgroundTiles = nil;
    sSharedProjectileSparkEmitter = nil;
    sSharedSpawnEmitter = nil;
    sSharedLeafEmitterA = nil;
    sSharedLeafEmitterB = nil;
}

static SKEmitterNode *sSharedProjectileSparkEmitter = nil;
- (SKEmitterNode *)sharedProjectileSparkEmitter {
    return sSharedProjectileSparkEmitter;
}

static SKEmitterNode *sSharedSpawnEmitter = nil;
- (SKEmitterNode *)sharedSpawnEmitter {
    return sSharedSpawnEmitter;
}

static APATree *sSharedSmallTree = nil;
- (APATree *)sharedSmallTree {
    return sSharedSmallTree;
}

static APATree *sSharedBigTree = nil;
- (APATree *)sharedBigTree {
    return sSharedBigTree;
}

static SKEmitterNode *sSharedLeafEmitterA = nil;
- (SKEmitterNode *)sharedLeafEmitterA {
    return sSharedLeafEmitterA;
}

static SKEmitterNode *sSharedLeafEmitterB = nil;
- (SKEmitterNode *)sharedLeafEmitterB {
    return sSharedLeafEmitterB;
}

static NSArray *sBackgroundTiles = nil;
- (NSArray *)backgroundTiles {
    return sBackgroundTiles;
}

@end
