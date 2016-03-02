/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This class manages most of the game logic.
*/

@import SpriteKit;
@import QuartzCore;
@import AVFoundation;

#import "AAPLGameViewControllerPrivate.h"

@implementation AAPLGameViewController

#pragma mark - Initialization

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create a new scene.
    SCNScene *scene = [SCNScene sceneNamed:@"game.scnassets/level.scn"];
    
    // Set the scene to the view and loop for the animation of the bamboos.
    self.gameView.scene = scene;
    self.gameView.playing = YES;
    self.gameView.loops = YES;
    
    // Various setup
    [self setupCamera];
    [self setupSounds];
    
    // Configure particle systems
    _collectFlowerParticleSystem = [SCNParticleSystem particleSystemNamed:@"collect.scnp" inDirectory:nil];
    _collectFlowerParticleSystem.loops = NO;
    _confettiParticleSystem = [SCNParticleSystem particleSystemNamed:@"confetti.scnp" inDirectory:nil];
    
    // Add the character to the scene.
    _character = [[AAPLCharacter alloc] init];
    [scene.rootNode addChildNode:_character.node];
    
    SCNNode *startPosition = [scene.rootNode childNodeWithName:@"startingPoint" recursively:YES];
    _character.node.transform = startPosition.transform;
    
    // Retrieve various game elements in one traversal
    NSMutableArray<SCNNode *> *flameNodes = [NSMutableArray array];
    NSMutableArray<SCNNode *> *enemyNodes = [NSMutableArray array];
    NSMutableArray<SCNNode *> *collisionNodes = [NSMutableArray array];
    
    [scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
        if (node.name.length) {
            if ([node.name isEqualToString:@"flame"]) {
                node.physicsBody.categoryBitMask = AAPLBitmaskEnemy;
                [flameNodes addObject:node];
            }
            else if ([node.name isEqualToString:@"enemy"]) {
                [enemyNodes addObject:node];
            }
            if ([node.name rangeOfString:@"collision"].length > 0) {
                [collisionNodes addObject:node];
            }
        }
    }];
    
    _flames = flameNodes;
    _enemies = enemyNodes;
    
    for (SCNNode *node in collisionNodes) {
        node.hidden = NO;
        [self setupCollisionNode:node];
    }
    
    // Setup delegates
    self.gameView.scene.physicsWorld.contactDelegate = self;
    self.gameView.delegate = self;
    
    [self setupAutomaticCameraPositions];
    [self setupGameControllers];
}

#pragma mark - Game view

- (AAPLGameView *)gameView {
    return (AAPLGameView *)self.view;
}

#pragma mark - Managing the Camera

- (void)panCamera:(CGPoint)direction {
    if (_lockCamera) {
        return;
    }
    
#if TARGET_OS_IOS || TARGET_OS_TV
    direction.y *= -1.0;
#endif
    
    static const CGFloat F = 0.005;
    
    // Make sure the camera handles are correctly reset (because automatic camera animations may have put the "rotation" in a weird state.
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:0.0];
    
    [_cameraYHandle removeAllActions];
    [_cameraXHandle removeAllActions];
    
    if (_cameraYHandle.rotation.y < 0) {
        _cameraYHandle.rotation = SCNVector4Make(0, 1, 0, -_cameraYHandle.rotation.w);
    }
    
    if (_cameraXHandle.rotation.x < 0) {
        _cameraXHandle.rotation = SCNVector4Make(1, 0, 0, -_cameraXHandle.rotation.w);
    }
    
    [SCNTransaction commit];
    
    // Update the camera position with some inertia.
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:0.5];
    [SCNTransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    
    _cameraYHandle.rotation = SCNVector4Make(0, 1, 0, _cameraYHandle.rotation.y * (_cameraYHandle.rotation.w - direction.x * F));
    _cameraXHandle.rotation = SCNVector4Make(1, 0, 0, (MAX(-M_PI_2, MIN(0.13, _cameraXHandle.rotation.w + direction.y * F))));
    
    [SCNTransaction commit];
}

- (void)updateCameraWithCurrentGround:(SCNNode *)node {
    if (_gameIsComplete) {
        return;
    }
    
    if (_currentGround == nil) {
        _currentGround = node;
        return;
    }
    
    // Automatically update the position of the camera when we move to another block.
    if (node != _currentGround) {
        _currentGround = node;
        
        NSValue *positionValue = [_groundToCameraPosition objectForKey:node];
        if (positionValue) {
            SCNVector3 position = positionValue.SCNVector3Value;
            
            if (node == _mainGround && _character.node.position.x < 2.5) {
                position = SCNVector3Make(-0.098175, 3.926991, 0.0);
            }
            
            SCNAction *actionY = [SCNAction rotateToX:0 y:position.y z:0 duration:3.0 shortestUnitArc:YES];
            actionY.timingMode = SCNActionTimingModeEaseInEaseOut;
            
            SCNAction *actionX = [SCNAction rotateToX:position.x y:0 z:0 duration:3.0 shortestUnitArc:YES];
            actionX.timingMode = SCNActionTimingModeEaseInEaseOut;
            
            [_cameraYHandle runAction:actionY];
            [_cameraXHandle runAction:actionX];
        }
    }
}

#pragma mark - Moving the Character

- (vector_float3)characterDirection {
    vector_float2 controllerDirection = self.controllerDirection;
    vector_float3 direction = {controllerDirection.x, 0.0, controllerDirection.y};
    
    SCNNode *pov = self.gameView.pointOfView;
    if (pov) {
        SCNVector3 p1 = [pov.presentationNode convertPosition:SCNVector3Make(direction.x, direction.y, direction.z) toNode:nil];
        SCNVector3 p0 = [pov.presentationNode convertPosition:SCNVector3Zero toNode:nil];
        direction = (vector_float3){p1.x - p0.x, 0.0, p1.z - p0.z};
        
        if (direction.x != 0.0 || direction.z != 0.0) {
            direction = vector_normalize(direction);
        }
    }
    
    return direction;
}

#pragma mark - SCNSceneRendererDelegate Conformance (Game Loop)

// SceneKit calls this method exactly once per frame, so long as the SCNView object (or other SCNSceneRenderer object) displaying the scene is not paused.
// Implement this method to add game logic to the rendering loop. Any changes you make to the scene graph during this method are immediately reflected in the displayed scene.

- (AAPLGroundType)groundTypeFromMaterial:(SCNMaterial *)material {
    if (material == _grassArea) {
        return AAPLGroundTypeGrass;
    }
    if (material == _waterArea) {
        return AAPLGroundTypeWater;
    }
    else {
        return AAPLGroundTypeRock;
    }
}

- (void)renderer:(id <SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time {
    // Reset some states every frame
    _replacementPositionIsValid = NO;
    _maxPenetrationDistance = 0;
    
    SCNScene *scene = self.gameView.scene;
    vector_float3 direction = self.characterDirection;
    
    SCNNode *groundNode = [_character walkInDirection:direction time:time scene:scene groundTypeFromMaterial:^AAPLGroundType(SCNMaterial *material) { return [self groundTypeFromMaterial:material]; }];
    if (groundNode) {
        [self updateCameraWithCurrentGround:groundNode];
    }
    
    // Flames are static physics bodies, but they are moved by an action - So we need to tell the physics engine that the transforms did change.
    for (SCNNode *flame in _flames) {
        [flame.physicsBody resetTransform];
    }
    
    // Adjust the volume of the enemy based on the distance with the character.
    float distanceToClosestEnemy = FLT_MAX;
    vector_float3 characterPosition = SCNVector3ToFloat3(_character.node.position);
    for (SCNNode *enemy in _enemies) {
        //distance to enemy
        SCNMatrix4 enemyTransform = enemy.worldTransform;
        vector_float3 enemyPosition = (vector_float3){enemyTransform.m41, enemyTransform.m42, enemyTransform.m43};
        float distance = vector_distance(characterPosition, enemyPosition);
        distanceToClosestEnemy = MIN(distanceToClosestEnemy, distance);
    }
    
    // Adjust sounds volumes based on distance with the enemy.
    if (!_gameIsComplete) {
        AVAudioMixerNode *mixer = (AVAudioMixerNode *)_flameThrowerSound.audioNode;
        mixer.volume = 0.3 * MAX(0, MIN(1, 1 - ((distanceToClosestEnemy - 1.2) / 1.6)));
    }
}

- (void)renderer:(id <SCNSceneRenderer>)renderer didSimulatePhysicsAtTime:(NSTimeInterval)time {
    // If we hit a wall, position needs to be adjusted
    if (_replacementPositionIsValid) {
        _character.node.position = _replacementPosition;
    }
}
    
#pragma mark - SCNPhysicsContactDelegate Conformance

// To receive contact messages, you set the contactDelegate property of an SCNPhysicsWorld object.
// SceneKit calls your delegate methods when a contact begins, when information about the contact changes, and when the contact ends.

- (void)physicsWorld:(SCNPhysicsWorld *)world didBeginContact:(SCNPhysicsContact *)contact {
    if (contact.nodeA.physicsBody.categoryBitMask == AAPLBitmaskCollision) {
        [self characterNode:contact.nodeB hitWall:contact.nodeA withContact:contact];
    }
    if (contact.nodeB.physicsBody.categoryBitMask == AAPLBitmaskCollision) {
        [self characterNode:contact.nodeA hitWall:contact.nodeB withContact:contact];
    }
    if (contact.nodeA.physicsBody.categoryBitMask == AAPLBitmaskCollectable) {
        [self collectPearl:contact.nodeA];
    }
    if (contact.nodeB.physicsBody.categoryBitMask == AAPLBitmaskCollectable) {
        [self collectPearl:contact.nodeB];
    }
    if (contact.nodeA.physicsBody.categoryBitMask == AAPLBitmaskSuperCollectable) {
        [self collectFlower:contact.nodeA];
    }
    if (contact.nodeB.physicsBody.categoryBitMask == AAPLBitmaskSuperCollectable) {
        [self collectFlower:contact.nodeB];
    }
    if (contact.nodeA.physicsBody.categoryBitMask == AAPLBitmaskEnemy) {
        [_character catchFire];
    }
    if (contact.nodeB.physicsBody.categoryBitMask == AAPLBitmaskEnemy) {
        [_character catchFire];
    }
}

- (void)physicsWorld:(SCNPhysicsWorld *)world didUpdateContact:(SCNPhysicsContact *)contact {
    if (contact.nodeA.physicsBody.categoryBitMask == AAPLBitmaskCollision) {
        [self characterNode:contact.nodeB hitWall:contact.nodeA withContact:contact];
    }
    if (contact.nodeB.physicsBody.categoryBitMask == AAPLBitmaskCollision) {
        [self characterNode:contact.nodeA hitWall:contact.nodeB withContact:contact];
    }
}

- (void)characterNode:(SCNNode *)characterNode hitWall:(SCNNode *)wall withContact:(SCNPhysicsContact *)contact {
    if (characterNode.parentNode != _character.node) {
        return;
    }
    
    if (_maxPenetrationDistance > contact.penetrationDistance) {
        return;
    }
    
    _maxPenetrationDistance = contact.penetrationDistance;
    
    vector_float3 characterPosition = SCNVector3ToFloat3(_character.node.position);
    vector_float3 positionOffset = SCNVector3ToFloat3(contact.contactNormal) * contact.penetrationDistance;
    positionOffset.y = 0;
    characterPosition += positionOffset;
    
    _replacementPosition = SCNVector3FromFloat3(characterPosition);
    _replacementPositionIsValid = YES;
}

#pragma mark - Scene Setup

- (void)setupCamera {
    static CGFloat const ALTITUDE = 1.0;
    static CGFloat const DISTANCE = 10.0;
    
    // We create 2 nodes to manipulate the camera:
    // The first node "_cameraXHandle" is at the center of the world (0, ALTITUDE, 0) and will only rotate on the X axis
    // The second node "_cameraYHandle" is a child of the first one and will ony rotate on the Y axis
    // The camera node is a child of the "_cameraYHandle" at a specific distance (DISTANCE).
    // So rotating _cameraYHandle and _cameraXHandle will update the camera position and the camera will always look at the center of the scene.
    
    SCNNode *pov = self.gameView.pointOfView;
    pov.eulerAngles = SCNVector3Zero;
    pov.position = SCNVector3Make(0.0, 0.0, DISTANCE);
    
    _cameraXHandle = [[SCNNode alloc] init];
    _cameraXHandle.rotation = SCNVector4Make(1.0, 0.0, 0.0, -M_PI_4 * 0.125);
    [_cameraXHandle addChildNode:pov];
    
    _cameraYHandle = [[SCNNode alloc] init];
    _cameraYHandle.position = SCNVector3Make(0.0, ALTITUDE, 0.0);
    _cameraYHandle.rotation = SCNVector4Make(0.0, 1.0, 0.0, M_PI_2 + M_PI_4 * 3.0);
    [_cameraYHandle addChildNode:_cameraXHandle];
    
    [self.gameView.scene.rootNode addChildNode:_cameraYHandle];
    
    // Animate camera on launch and prevent the user from manipulating the camera until the end of the animation.
    [SCNTransaction begin];
    [SCNTransaction setCompletionBlock:^{ _lockCamera = NO; }];
    
    _lockCamera = YES;
    
    // Create 2 additive animations that converge to 0
    // That way at the end of the animation, the camera will be at its default position.
    CABasicAnimation *cameraYAnimation = [CABasicAnimation animationWithKeyPath:@"rotation.w"];
    cameraYAnimation.fromValue = @(M_PI * 2.0 - _cameraYHandle.rotation.w);
    cameraYAnimation.toValue = @(0.0);
    cameraYAnimation.additive = YES;
    cameraYAnimation.beginTime = CACurrentMediaTime() + 3.0; // wait a little bit before stating
    cameraYAnimation.fillMode = kCAFillModeBoth;
    cameraYAnimation.duration = 5.0;
    cameraYAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [_cameraYHandle addAnimation:cameraYAnimation forKey:nil];
    
    CABasicAnimation *cameraXAnimation = [cameraYAnimation copy];
    cameraXAnimation.fromValue = @(-M_PI_2 + _cameraXHandle.rotation.w);
    [_cameraXHandle addAnimation:cameraXAnimation forKey:nil];
    
    [SCNTransaction commit];
}

- (void)setupAutomaticCameraPositions {
    SCNNode *rootNode = self.gameView.scene.rootNode;
    
    _mainGround = [rootNode childNodeWithName:@"bloc05_collisionMesh_02" recursively:YES];
    
    _groundToCameraPosition = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsOpaqueMemory valueOptions:NSPointerFunctionsStrongMemory];
    
    [_groundToCameraPosition setObject:[NSValue valueWithSCNVector3:SCNVector3Make(-0.188683, 4.719608, 0.0)] forKey:[rootNode childNodeWithName:@"bloc04_collisionMesh_02" recursively:YES]];
    [_groundToCameraPosition setObject:[NSValue valueWithSCNVector3:SCNVector3Make(-0.435909, 6.297167, 0.0)] forKey:[rootNode childNodeWithName:@"bloc03_collisionMesh" recursively:YES]];
    [_groundToCameraPosition setObject:[NSValue valueWithSCNVector3:SCNVector3Make( -0.333663, 7.868592, 0.0)] forKey:[rootNode childNodeWithName:@"bloc07_collisionMesh" recursively:YES]];
    [_groundToCameraPosition setObject:[NSValue valueWithSCNVector3:SCNVector3Make(-0.575011, 8.739003, 0.0)] forKey:[rootNode childNodeWithName:@"bloc08_collisionMesh" recursively:YES]];
    [_groundToCameraPosition setObject:[NSValue valueWithSCNVector3:SCNVector3Make( -1.095519, 9.425292, 0.0)] forKey:[rootNode childNodeWithName:@"bloc06_collisionMesh" recursively:YES]];
    [_groundToCameraPosition setObject:[NSValue valueWithSCNVector3:SCNVector3Make(-0.072051, 8.202264, 0.0)] forKey:[rootNode childNodeWithName:@"bloc05_collisionMesh_02" recursively:YES]];
    [_groundToCameraPosition setObject:[NSValue valueWithSCNVector3:SCNVector3Make(-0.072051, 8.202264, 0.0)] forKey:[rootNode childNodeWithName:@"bloc05_collisionMesh_01" recursively:YES]];
}

- (void)setupCollisionNode:(SCNNode *)node {
    if (node.geometry) {
        // Collision meshes must use a concave shape for intersection correctness.
        node.physicsBody = [SCNPhysicsBody staticBody];
        node.physicsBody.categoryBitMask = AAPLBitmaskCollision;
        node.physicsBody.physicsShape = [SCNPhysicsShape shapeWithNode:node options:@{SCNPhysicsShapeTypeKey : SCNPhysicsShapeTypeConcavePolyhedron}];
        
        // Get grass area to play the right sound steps
        if ([node.geometry.firstMaterial.name isEqualToString:@"grass-area"]) {
            if (_grassArea) {
                node.geometry.firstMaterial = _grassArea;
            } else {
                _grassArea = node.geometry.firstMaterial;
            }
        }
        
        // Get the water area
        if ([node.geometry.firstMaterial.name isEqualToString:@"water"]) {
            _waterArea = node.geometry.firstMaterial;
        }
        
        // Temporary workaround because concave shape created from geometry instead of node fails
        SCNNode *childNode = [SCNNode node];
        [node addChildNode:childNode];
        childNode.hidden = YES;
        childNode.geometry = node.geometry;
        node.geometry = nil;
        node.hidden = NO;
        
        if ([node.name isEqualToString:@"water"]) {
            node.physicsBody.categoryBitMask = AAPLBitmaskWater;
        }
    }
    
    for (SCNNode *childNode in node.childNodes) {
        if (childNode.hidden == NO) {
            [self setupCollisionNode:childNode];
        }
    }
}

- (void)setupSounds {
    // Get an arbitrary node to attach the sounds to.
    SCNNode *node = self.gameView.scene.rootNode;
    
    SCNAudioSource *musicSource = [SCNAudioSource audioSourceNamed:@"game.scnassets/sounds/music.m4a"];
    musicSource.loops = YES;
    musicSource.volume = 0.25;
    musicSource.positional = NO;
    musicSource.shouldStream = YES;
    [node addAudioPlayer:[SCNAudioPlayer audioPlayerWithSource:musicSource]];
    
    SCNAudioSource *windSource = [SCNAudioSource audioSourceNamed:@"game.scnassets/sounds/wind.m4a"];
    windSource.loops = YES;
    windSource.volume = 0.3;
    windSource.positional = NO;
    windSource.shouldStream = YES;
    [node addAudioPlayer:[SCNAudioPlayer audioPlayerWithSource:windSource]];
    
    SCNAudioSource *flameThrowerSource = [SCNAudioSource audioSourceNamed:@"game.scnassets/sounds/flamethrower.mp3"];
    flameThrowerSource.loops = YES;
    flameThrowerSource.volume = 0;
    flameThrowerSource.positional = NO;
    _flameThrowerSound = [SCNAudioPlayer audioPlayerWithSource:flameThrowerSource];
    [node addAudioPlayer:_flameThrowerSound];
    
    _collectPearlSound = [SCNAudioSource audioSourceNamed:@"game.scnassets/sounds/collect1.mp3"];
    _collectPearlSound.volume = 0.5;
    [_collectPearlSound load];
    
    _collectFlowerSound = [SCNAudioSource audioSourceNamed:@"game.scnassets/sounds/collect2.mp3"];
    [_collectFlowerSound load];
    
    _victoryMusic = [SCNAudioSource audioSourceNamed:@"game.scnassets/sounds/Music_victory.mp3"];
    _victoryMusic.volume = 0.5;
}

#pragma mark - Collecting Items

- (void)removeNode:(SCNNode *)node soundToPlay:(SCNAudioSource *)sound {
    SCNNode *parentNode = node.parentNode;
    if (parentNode) {
        SCNNode *soundEmitter = [SCNNode node];
        soundEmitter.position = node.position;
        [parentNode addChildNode:soundEmitter];
        
        [soundEmitter runAction:[SCNAction sequence:@[[SCNAction playAudioSource:sound waitForCompletion:YES],
                                                      [SCNAction removeFromParentNode]]]];
        
        [node removeFromParentNode];
    }
}

- (void)collectPearl:(SCNNode *)pearlNode {
    if (pearlNode.parentNode != nil) {
        [self removeNode:pearlNode soundToPlay:_collectPearlSound];
        self.gameView.collectedPearlsCount = ++_collectedPearlsCount;
    }
}

- (NSUInteger)collectedFlowersCount {
    return _collectedFlowersCount;
}

- (void)setCollectedFlowersCount:(NSUInteger)collectedFlowersCount {
    _collectedFlowersCount = collectedFlowersCount;
    
    self.gameView.collectedFlowersCount = _collectedFlowersCount;
    if (_collectedFlowersCount == 3) {
        [self showEndScreen];
    }
}

- (void)collectFlower:(SCNNode *)flowerNode {
    if (flowerNode.parentNode != nil) {
        // Emit particles.
        SCNMatrix4 particleSystemPosition = flowerNode.worldTransform;
        particleSystemPosition.m42 += 0.1;
        [self.gameView.scene addParticleSystem:_collectFlowerParticleSystem withTransform:particleSystemPosition];
        
        // Remove the flower from the scene.
        [self removeNode:flowerNode soundToPlay:_collectFlowerSound];
        self.collectedFlowersCount++;
    }
}

#pragma mark - Congratulating the Player

- (void)showEndScreen {
    _gameIsComplete = YES;
    
    // Add confettis
    SCNMatrix4 particleSystemPosition = SCNMatrix4MakeTranslation(0.0, 8.0, 0.0);
    [self.gameView.scene addParticleSystem:_confettiParticleSystem withTransform:particleSystemPosition];
    
    // Stop the music.
    [self.gameView.scene.rootNode removeAllAudioPlayers];
    
    // Play the congrat sound.
    [self.gameView.scene.rootNode addAudioPlayer:[SCNAudioPlayer audioPlayerWithSource:_victoryMusic]];
    
    // Animate the camera forever
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_cameraYHandle runAction:[SCNAction repeatActionForever:[SCNAction rotateByX:0 y:-1 z:0 duration:3]]];
        [_cameraXHandle runAction:[SCNAction rotateToX:-M_PI_4 y:0 z:0 duration:5.0]];
    });
    
    [self.gameView showEndScreen];
}

@end
