/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This class manages most of the game logic.
*/

@import AVFoundation;
@import SpriteKit;

#import "AAPLGameViewController.h"
#import "AAPLCharacter.h"

#define GravityAcceleration (0.18)
#define MaxRise (.08)
#define MaxJump (10.0)

#define ENABLE_AUTOMATIC_CAMERA 1

@implementation AAPLGameViewController
{
    // Nodes to manipulate the camera
    SCNNode *_cameraYHandle;
    SCNNode *_cameraXHandle;
    
    // The character
    AAPLCharacter *_character;
    
    // Simulate gravity
    float _accelerationY;
    
    float _maxPenetrationDistance;
    bool  _positionNeedsAdjustment;
    SCNVector3 _replacementPosition;
    NSTimeInterval _previousUpdateTime;
    
    // Game states
    bool _gameIsComplete;
    bool _isInvincible;
    bool _lockCamera;
    
    SCNMaterial *_grassArea;
    SCNMaterial *_waterArea;
    NSArray *_flames;
    NSArray *_enemies;
    
    // Sounds
    SCNAudioPlayer *_flameThrowerSound;
    SCNAudioSource *_collectPearlSound;
    SCNAudioSource *_collectFlowerSound;
    SCNAudioSource *_hitSound;
    SCNAudioSource *_pshhhSound;
    SCNAudioSource *_aahSound;
    SCNAudioSource *_victoryMusic;
    
    // Particles
    SCNParticleSystem *_collectParticles;
    SCNParticleSystem *_confetti;
    
    // For automatic camera animation
    SCNNode *_currentGround;
    SCNNode *_mainGround;
    NSMapTable *_groundToCameraPosition;
}

- (void)setupCamera
{
    SCNNode *pov = self.gameView.pointOfView;
    
#define ALTITUDE 1.0
#define DISTANCE 10.0
    
    // We create 2 nodes to manipulate the camera:
    // The first node "_cameraXHandle" is at the center of the world (0, ALTITUDE, 0) and will only rotate on the X axis
    // The second node "_cameraYHandle" is a child of the first one and will ony rotate on the Y axis
    // The camera node is a child of the "_cameraYHandle" at a specific distance (DISTANCE).
    // So rotating _cameraYHandle and _cameraXHandle will update the camera position and the camera will always look at the center of the scene.
    
    _cameraYHandle = [SCNNode node];
    _cameraXHandle = [SCNNode node];
    _cameraYHandle.position = SCNVector3Make(0,ALTITUDE,0);
    [_cameraYHandle addChildNode:_cameraXHandle];
    [self.gameView.scene.rootNode addChildNode:_cameraYHandle];
    
    pov.eulerAngles = SCNVector3Make(0, 0, 0);
    pov.position = SCNVector3Make(0,0,DISTANCE);
    
    _cameraYHandle.rotation = SCNVector4Make(0, 1, 0, M_PI_2 + M_PI_4*3);
    _cameraXHandle.rotation = SCNVector4Make(1, 0, 0, -M_PI_4*0.125);

    [_cameraXHandle addChildNode:pov];

    // Animate camera on launch and prevent the user from manipulating the camera until the end of the animation.
    _lockCamera = YES;
    [SCNTransaction begin];
    [SCNTransaction setCompletionBlock:^{
        _lockCamera = NO;
    }];

    // Create 2 additive animations that converge to 0
    // That way at the end of the animation, the camera will be at its default position.
    CABasicAnimation *cameraYAnimation = [CABasicAnimation animationWithKeyPath:@"rotation.w"];
    cameraYAnimation.fromValue = @(M_PI*2 - _cameraYHandle.rotation.w);
    cameraYAnimation.toValue = @0.0;
    cameraYAnimation.additive = YES;
    cameraYAnimation.beginTime = CACurrentMediaTime()+3; // wait a little bit before stating
    cameraYAnimation.fillMode = kCAFillModeBoth;
    cameraYAnimation.duration = 5.0;
    cameraYAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [_cameraYHandle addAnimation:cameraYAnimation forKey:nil];
    
    CABasicAnimation *cameraXAnimation = [CABasicAnimation animationWithKeyPath:@"rotation.w"];
    cameraXAnimation.fromValue = @(-M_PI_2 + _cameraXHandle.rotation.w);
    cameraXAnimation.toValue = @0.0;
    cameraXAnimation.additive = YES;
    cameraXAnimation.fillMode = kCAFillModeBoth;
    cameraXAnimation.duration = 5.0;
    cameraXAnimation.beginTime = CACurrentMediaTime()+3;
    cameraXAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [_cameraXHandle addAnimation:cameraXAnimation forKey:nil];
    [SCNTransaction commit];
    
    // Add a look at constraint that will always be disable.
    // We will only progressively enable it while pinching to focus on the character.
    SCNLookAtConstraint *lookAtConstraint = [SCNLookAtConstraint lookAtConstraintWithTarget:[_character.node childNodeWithName:@"Bip001_Head" recursively:YES]];
    lookAtConstraint.influenceFactor = 0;
    pov.constraints = @[lookAtConstraint];
}


- (void)panCamera:(CGSize)dir
{
    if (_lockCamera == YES) {
        return;
    }
    
#define F 0.005
    
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
    
    _cameraYHandle.rotation = SCNVector4Make(0, 1, 0, _cameraYHandle.rotation.y * (_cameraYHandle.rotation.w - dir.width * F));
    _cameraXHandle.rotation = SCNVector4Make(1, 0, 0, (MAX(-M_PI_2, MIN(0.13, _cameraXHandle.rotation.w + dir.height * F))));
    
    [SCNTransaction commit];
}

- (void)setupCollisionNodes:(SCNNode *)node
{
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
        SCNNode *child = [SCNNode node];
        [node addChildNode:child];
        child.hidden = YES;
        child.geometry = node.geometry;
        node.geometry = nil;
        node.hidden = NO;
        
        if([node.name isEqualToString:@"water"]){
            node.physicsBody.categoryBitMask = AAPLBitmaskWater;
        }
    }
    
    for(SCNNode *child in node.childNodes) {
        if (child.hidden == NO) {
            [self setupCollisionNodes:child];
        }
    }
}

- (void)setupSounds
{
    // Get an arbitrary node to attach the sounds to.
    SCNNode *node = self.gameView.scene.rootNode;

    // The wind sound.
    SCNAudioSource *source = [SCNAudioSource audioSourceNamed:@"game.scnassets/sounds/wind.m4a"];
    source.volume = 0.3;
    SCNAudioPlayer *player = [SCNAudioPlayer audioPlayerWithSource:source];
    source.loops = YES;
    source.shouldStream = YES;
    source.positional = NO;
    [node addAudioPlayer:player];

    // fire
    source = [SCNAudioSource audioSourceNamed:@"game.scnassets/sounds/flamethrower.mp3"];
    source.loops = YES;
    source.volume = 0;
    source.positional = NO;
    _flameThrowerSound = [SCNAudioPlayer audioPlayerWithSource:source];
    [node addAudioPlayer:_flameThrowerSound];
    
    // hit
    _hitSound = [SCNAudioSource audioSourceNamed:@"game.scnassets/sounds/ouch_firehit.mp3"];
    _hitSound.volume = 2.0;
    [_hitSound load];
    
    _pshhhSound = [SCNAudioSource audioSourceNamed:@"game.scnassets/sounds/fire_extinction.mp3"];
    _pshhhSound.volume = 2.0;
    [_pshhhSound load];
    
    _aahSound = [SCNAudioSource audioSourceNamed:@"game.scnassets/sounds/aah_extinction.mp3"];
    _aahSound.volume = 2.0;
    [_aahSound load];
    
    // collectable
    _collectPearlSound = [SCNAudioSource audioSourceNamed:@"game.scnassets/sounds/collect1.mp3"];
    _collectPearlSound.volume = 0.5;
    [_collectPearlSound load];
    _collectFlowerSound = [SCNAudioSource audioSourceNamed:@"game.scnassets/sounds/collect2.mp3"];
    [_collectFlowerSound load];
    
    // victory
    _victoryMusic = [SCNAudioSource audioSourceNamed:@"game.scnassets/sounds/Music_victory.mp3"];
    _victoryMusic.volume = 0.5;
}

- (void)setupMusic
{
    // Get an arbitrary node to attach the sounds to.
    SCNNode *node = self.gameView.scene.rootNode;
    
    SCNAudioSource *source = [SCNAudioSource audioSourceNamed:@"game.scnassets/sounds/music.m4a"];
    source.loops = YES;
    source.volume = 0.25;
    source.shouldStream = YES;
    source.positional = NO;
    
    SCNAudioPlayer *player = [SCNAudioPlayer audioPlayerWithSource:source];

    [node addAudioPlayer:player];
}

- (void)setupAutomaticCameraPositions
{
    SCNNode *root = self.gameView.scene.rootNode;
    
    _mainGround = [root childNodeWithName:@"bloc05_collisionMesh_02" recursively:YES];
    
    _groundToCameraPosition = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsOpaqueMemory valueOptions:NSPointerFunctionsStrongMemory];
    
    [_groundToCameraPosition setObject:[NSValue valueWithSCNVector3:SCNVector3Make(-0.188683, 4.719608, 0)] forKey:[root childNodeWithName:@"bloc04_collisionMesh_02" recursively:YES]];
    [_groundToCameraPosition setObject:[NSValue valueWithSCNVector3:SCNVector3Make(-0.435909, 6.297167, 0)] forKey:[root childNodeWithName:@"bloc03_collisionMesh" recursively:YES]];
    [_groundToCameraPosition setObject:[NSValue valueWithSCNVector3:SCNVector3Make( -0.333663, 7.868592, 0)] forKey:[root childNodeWithName:@"bloc07_collisionMesh" recursively:YES]];
    [_groundToCameraPosition setObject:[NSValue valueWithSCNVector3:SCNVector3Make(-0.575011, 8.739003, 0)] forKey:[root childNodeWithName:@"bloc08_collisionMesh" recursively:YES]];
    [_groundToCameraPosition setObject:[NSValue valueWithSCNVector3:SCNVector3Make( -1.095519, 9.425292, 0)] forKey:[root childNodeWithName:@"bloc06_collisionMesh" recursively:YES]];
    [_groundToCameraPosition setObject:[NSValue valueWithSCNVector3:SCNVector3Make(-0.072051, 8.202264, 0)] forKey:[root childNodeWithName:@"bloc05_collisionMesh_02" recursively:YES]];
    [_groundToCameraPosition setObject:[NSValue valueWithSCNVector3:SCNVector3Make(-0.072051, 8.202264, 0)] forKey:[root childNodeWithName:@"bloc05_collisionMesh_01" recursively:YES]];
}

-(void)awakeFromNib
{ 
#if TARGET_OS_IPHONE
    self.gameView = (AAPLGameView *)self.view;
#endif
    
    // Create a new scene.
    SCNScene *scene = [SCNScene sceneNamed:@"game.scnassets/level.scn"];

    // Set the scene to the view and loops for the animation of the bamboos.
    self.gameView.scene = scene;
    self.gameView.playing = YES;
    self.gameView.loops = YES;
    
    // Create the character
    _character = [[AAPLCharacter alloc] init];
    
    // Various setup
    [self setupCamera];
    [self setupSounds];
    [self setupMusic];
    
    //setup particles
    _collectParticles = [SCNParticleSystem particleSystemNamed:@"collect.scnp" inDirectory:@"game.scnassets"];
    _collectParticles.loops = NO;
    _confetti = [SCNParticleSystem particleSystemNamed:@"confetti.scnp" inDirectory:@"game.scnassets"];
    
    // Add the character to the scene.
    [scene.rootNode addChildNode:_character.node];
    
    // Place it
    SCNNode *sp = [scene.rootNode childNodeWithName:@"startingPoint" recursively:YES];
    _character.node.transform = sp.transform;
    
    // Setup physics masks and physics shape
    NSArray *collisionNodes = [scene.rootNode childNodesPassingTest:^BOOL(SCNNode *node, BOOL *stop) {
        if ([node.name rangeOfString:@"collision"].length > 0) {
            return YES;
        }
        return NO;
    }];

    for(SCNNode *node in collisionNodes) {
        node.hidden = NO;
        [self setupCollisionNodes:node];
    }
    
    // Retrieve flames and enemies
    _flames = [scene.rootNode childNodesPassingTest:^BOOL(SCNNode *node, BOOL *stop) {
        if ([node.name isEqualToString:@"flame"]) {
            node.physicsBody.categoryBitMask = AAPLBitmaskEnemy;
            return YES;
        }
        return NO;
    }];
    
    _enemies = [scene.rootNode childNodesPassingTest:^BOOL(SCNNode *node, BOOL *stop) {
        return [node.name isEqualToString:@"enemy"];
    }];

    // Setup delegates
    self.gameView.scene.physicsWorld.contactDelegate = self;
    self.gameView.delegate = self;
    
    //setup view overlays
    [self.gameView setup];
    
#if ENABLE_AUTOMATIC_CAMERA
    [self setupAutomaticCameraPositions];
#endif
}

- (void)updateCameraWithCurrentGround:(SCNNode *)node
{
    if (_gameIsComplete) {
        return;
    }
    
    if (_currentGround == nil) {
        _currentGround = node;
        return;
    }
    
    // Automatically update the position of the camera when we move to another block.
    if (node && node != _currentGround) {
        _currentGround = node;
        
        NSValue *position = [_groundToCameraPosition objectForKey:node];

        if (position) {
            SCNVector3 p = [position SCNVector3Value];
            
            if (node == _mainGround && _character.node.position.x < 2.5) {
                p = SCNVector3Make(-0.098175, 3.926991, 0);
            }
            
            SCNAction *actionY = [SCNAction rotateToX:0 y:p.y z:0 duration:3.0 shortestUnitArc:YES];
            actionY.timingMode = SCNActionTimingModeEaseInEaseOut;

            SCNAction *actionX = [SCNAction rotateToX:p.x y:0 z:0 duration:3.0 shortestUnitArc:YES];
            actionX.timingMode = SCNActionTimingModeEaseInEaseOut;
            
            [_cameraYHandle runAction:actionY];
            [_cameraXHandle runAction:actionX];
        }
    }
}

// Game loop
- (void) renderer:(id<SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time
{
    // delta time since last update
    if (_previousUpdateTime == 0.0) {
        _previousUpdateTime = time;
    }
    
    NSTimeInterval deltaTime = MIN(MAX(1/60.0, time - _previousUpdateTime), 1.0);
    _previousUpdateTime = time;
    
    // Reset some states every frame
    _maxPenetrationDistance = 0;
    _positionNeedsAdjustment = false;
    
    SCNVector3 direction = self.gameView.direction;
    SCNVector3 initialPosition = _character.node.position;
    
    //move
    if (direction.x != 0 && direction.z != 0) {
#define CharacterSpeed (deltaTime * CharacterSpeedFactor * .84)
        //move character
        SCNVector3 position = _character.node.position;
        _character.node.position = SCNVector3Make(position.x+direction.x*CharacterSpeed, position.y+direction.y*CharacterSpeed, position.z+direction.z*CharacterSpeed);
        
        // update orientation
        double angle = atan2(direction.x, direction.z);
        _character.direction = angle;

        _character.walk = YES;
    }
    else {
        _character.walk = NO;
    }
    
    // Update the altitude of the character
    SCNScene *scene = self.gameView.scene;
    SCNVector3 position = _character.node.position;
    SCNVector3 p0 = position;
    SCNVector3 p1 = position;
    p0.y -= MaxJump;
    p1.y += MaxRise;
    
    // Do a vertical ray intersection
    NSArray *results = [scene.physicsWorld rayTestWithSegmentFromPoint:p1 toPoint:p0 options:@{SCNPhysicsTestCollisionBitMaskKey: @(AAPLBitmaskCollision | AAPLBitmaskWater), SCNPhysicsTestSearchModeKey : SCNPhysicsTestSearchModeClosest}];
    
    float groundY = -10;

    if (results.count > 0) {
        SCNHitTestResult *result = results[0];
        groundY = result.worldCoordinates.y;

        [self updateCameraWithCurrentGround:result.node];
        
        SCNMaterial *groundMaterial = result.node.childNodes[0].geometry.firstMaterial;
        if (_grassArea == groundMaterial) {
            _character.floorMaterial = AAPLFloorMaterialGrass;
        }
        else if (_waterArea == groundMaterial) {
            if(_character.isBurning){
                [_character pshhhh];
                [_character.node runAction:[SCNAction sequence:@[[SCNAction playAudioSource:_pshhhSound waitForCompletion:YES],[SCNAction playAudioSource:_aahSound waitForCompletion:NO]]]];
            }
            
            _character.floorMaterial = AAPLFloorMaterialWater;
            
            // do a new ray test without the water to get the altitude of the ground (under the water).
            NSArray *results = [scene.physicsWorld rayTestWithSegmentFromPoint:p1 toPoint:p0 options:@{SCNPhysicsTestCollisionBitMaskKey: @(AAPLBitmaskCollision), SCNPhysicsTestSearchModeKey : SCNPhysicsTestSearchModeClosest}];

            SCNHitTestResult *result = results[0];
            groundY = result.worldCoordinates.y;
        }
        else {
            _character.floorMaterial = AAPLFloorMaterialRock;
        }

    }
    else {
        // no result, we are probably out the bounds of the level -> revert the position of the character.
        _character.node.position = initialPosition;
        return;
    }
    
#define THRESHOLD 1e-5
    if (groundY < position.y - THRESHOLD) {
        _accelerationY += deltaTime * GravityAcceleration; // approximation of acceleration for a delta time.
        if (groundY < position.y - 0.2) {
            _character.floorMaterial = AAPLFloorMaterialInTheAir;
        }
    }
    else {
        _accelerationY = 0;
    }

    position.y -= _accelerationY;
 
    // reset acceleration if we touch the ground
    if (groundY > position.y) {
        _accelerationY = 0;
        position.y = groundY;
    }
    
    // Flames are static physics bodies, but they are moved by an action - So we need to tell the physics engine that the transforms did change.
    for(SCNNode *flame in _flames) {
        [flame.physicsBody resetTransform];
    }
    
    // Adjust the volume of the enemy based on the distance with the character.
    float distanceToClosestEnemy = MAXFLOAT;
    vector_float3 pos3 = SCNVector3ToFloat3(_character.node.position);
    for(SCNNode *enemy in _enemies) {
        //distance to enemy
        SCNMatrix4 enemyMat = enemy.worldTransform;
        vector_float3 enemyPos = (vector_float3) {enemyMat.m41, enemyMat.m42, enemyMat.m43};
        
        float distance = vector_distance(pos3, enemyPos);
        distanceToClosestEnemy = MIN(distanceToClosestEnemy, distance);
    }
    
    // Adjust sounds volumes based on distance with the enemy.
    if (!_gameIsComplete) {
        float fireVolume = 0.3 * MAX(0,MIN(1, 1 - ((distanceToClosestEnemy - 1.2) / 1.6)));
        ((AVAudioMixerNode*)_flameThrowerSound.audioNode).volume = fireVolume;
    }

    // Finally, update the position of the character.
    _character.node.position = position;
}

- (void) collectPearl:(SCNNode *)node
{
    if (node.parentNode != nil) {
        SCNNode *soundEmitter = [SCNNode node];
        soundEmitter.position = node.position;
        [node.parentNode addChildNode:soundEmitter];
        
        [soundEmitter runAction:[SCNAction sequence:@[
                                            [SCNAction playAudioSource:_collectPearlSound waitForCompletion:YES],
                                            [SCNAction removeFromParentNode]]]];
        
        [node removeFromParentNode];

        [self.gameView didCollectAPearl];
    }
}

- (void) collectFlower:(SCNNode *)node
{
    if (node.parentNode != nil) {
        SCNNode *soundEmitter = [SCNNode node];
        soundEmitter.position = node.position;
        [node.parentNode addChildNode:soundEmitter];

        [soundEmitter runAction:[SCNAction sequence:@[
                                                      [SCNAction playAudioSource:_collectFlowerSound waitForCompletion:YES],
                                                      [SCNAction removeFromParentNode]]]];
        
        [node removeFromParentNode];

        // Check if game is complete.
        BOOL gameComplete = [self.gameView didCollectAFlower];
        
        // Emit some particles.
        SCNMatrix4 particlePosition = soundEmitter.worldTransform;
        particlePosition.m42 += 0.1;
        [self.gameView.scene addParticleSystem:_collectParticles withTransform:particlePosition];
        
        if (gameComplete) {
            [self showEndScreen];
        }
    }
}

- (void)showEndScreen
{
    _gameIsComplete = YES;
    
    // Add confettis
    SCNMatrix4 particlePosition = SCNMatrix4MakeTranslation(0, 8, 0);
    [self.gameView.scene addParticleSystem:_confetti withTransform:particlePosition];
    
    // Congratulation title
    SKSpriteNode *congrat = [SKSpriteNode spriteNodeWithImageNamed:@"congratulations.png"];
    congrat.position = CGPointMake(self.gameView.bounds.size.width/2 , self.gameView.bounds.size.height/2);
    SKScene *overlay = self.gameView.overlaySKScene;
    congrat.xScale = congrat.yScale = 0;
    congrat.alpha = 0;
    [congrat runAction:[SKAction group:@[
                                         [SKAction fadeInWithDuration:0.25],
                                         [SKAction sequence:@[
                                         [SKAction scaleTo:0.55 duration:0.25],
                                         [SKAction scaleTo:0.45 duration:0.1]]
                                         ]]]];
    
    // Panda Image
    SKSpriteNode *congratPanda = [SKSpriteNode spriteNodeWithImageNamed:@"congratulations_pandaMax.png"];
    congratPanda.position = CGPointMake(self.gameView.bounds.size.width/2 , self.gameView.bounds.size.height/2 - 90);
    congratPanda.anchorPoint = CGPointMake(0.5, 0);
    congratPanda.xScale = congratPanda.yScale = 0;
    congratPanda.alpha = 0;
    [congratPanda runAction:[SKAction sequence:@[[SKAction waitForDuration:0.5],[SKAction group:@[
                                         [SKAction fadeInWithDuration:0.5],
                                         [SKAction sequence:@[
                                                              [SKAction scaleTo:0.5 duration:0.25],
                                                              [SKAction scaleTo:0.4 duration:0.1]]
                                          ]
                                         ]]]]];

    [overlay addChild:congratPanda];
    [overlay addChild:congrat];

    // Stop the music.
    [self.gameView.scene.rootNode removeAllAudioPlayers];
    
    // Play the congrat sound.
    [self.gameView.scene.rootNode addAudioPlayer:[SCNAudioPlayer audioPlayerWithSource:_victoryMusic]];
    
    // Animate the camera forever
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_cameraYHandle runAction:[SCNAction repeatActionForever:[SCNAction rotateByX:0 y:-1 z:0 duration:3]]];
        [_cameraXHandle runAction:[SCNAction rotateToX:-M_PI_4 y:0 z:0 duration:5.0]];
    });
}

- (void) renderer:(id<SCNSceneRenderer>)renderer didSimulatePhysicsAtTime:(NSTimeInterval)time
{
    // If we hit a wall, position needs to be adjusted
    if (_positionNeedsAdjustment) {
        _character.node.position = _replacementPosition;
    }
}

- (void)characterNode:(SCNNode *)capsule hitWall:(SCNNode *)wall withContact:(SCNPhysicsContact *)contact
{
    if (capsule.parentNode != _character.node) {
        return;
    }
    
    if (_maxPenetrationDistance > contact.penetrationDistance) {
        return;
    }
    
    _maxPenetrationDistance = contact.penetrationDistance;
    
    vector_float3 charPos = SCNVector3ToFloat3(_character.node.position);
    vector_float3 n = SCNVector3ToFloat3(contact.contactNormal);

    n *= contact.penetrationDistance;
    
    n.y = 0;
    charPos += n;
    
    _replacementPosition = SCNVector3FromFloat3(charPos);
    _positionNeedsAdjustment = YES;
}


- (void)physicsWorld:(SCNPhysicsWorld *)world didUpdateContact:(SCNPhysicsContact *)contact
{
    if (contact.nodeA.physicsBody.categoryBitMask == AAPLBitmaskCollision) {
        [self characterNode:contact.nodeB hitWall:contact.nodeA withContact:contact];
    }
    if (contact.nodeB.physicsBody.categoryBitMask == AAPLBitmaskCollision) {
        [self characterNode:contact.nodeA hitWall:contact.nodeB withContact:contact];
    }
}

- (void)wasHit
{
    if (_isInvincible == NO) {
        _isInvincible = YES;

        [self.character hit];
        
        [self.character.node runAction:
         [SCNAction sequence:@[
                               [SCNAction playAudioSource:_hitSound waitForCompletion:NO],
                               [SCNAction repeatAction:[SCNAction sequence:@[
                                                                             [SCNAction fadeOpacityTo:0.01 duration:0.1],
                                                                             [SCNAction fadeOpacityTo:1 duration:0.1]]]
                                                                     count:7],
                               [SCNAction runBlock:^(SCNNode *node) {
             _isInvincible = NO;
         }]]]];
    }
}

- (void)physicsWorld:(SCNPhysicsWorld *)world didBeginContact:(SCNPhysicsContact *)contact
{
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
        [self wasHit];
    }
    if (contact.nodeB.physicsBody.categoryBitMask == AAPLBitmaskEnemy) {
        [self wasHit];
    }
}

@end
