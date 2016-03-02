/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This class manages the main character, including its animations, sounds and direction.
*/

@import SceneKit;

#import "AAPLCharacter.h"
#import "AAPLGameViewController.h"

static CGFloat const AAPLCharacterSpeedFactor = 1.538;
static NSUInteger const AAPLCharacterStepsCount = 11;

@implementation AAPLCharacter {
    // Character handle
    SCNNode *_node;
    
    // Controlling the character
    AAPLGroundType _groundType;
    NSTimeInterval _previousUpdateTime;
    CGFloat _walkSpeed;
    CGFloat _accelerationY;
    CGFloat _directionAngle;
    BOOL _isWalking;
    BOOL _isBurning;
    BOOL _isInvincible;
    
    // Particle systems
    SCNNode *_fireEmitter;
    SCNNode *_smokeEmitter;
    SCNNode *_whiteSmokeEmitter;
    CGFloat _fireEmitterBirthRate;
    CGFloat _smokeEmitterBirthRate;
    CGFloat _whiteSmokeEmitterBirthRate;
 
    // Sound effects
    SCNAudioSource *_reliefSound;
    SCNAudioSource *_haltFireSound;
    SCNAudioSource *_catchFireSound;
    SCNAudioSource *_steps[AAPLCharacterStepsCount][AAPLGroundTypeCount];
    
    // Animations
    CAAnimation *_walkAnimation;
}

#pragma mark - Initialization

- (instancetype)init {
    if (self = [super init]) {
        
        /// Load character from external file
        
        _node = [SCNNode node];
        SCNScene *characterScene = [SCNScene sceneNamed:@"game.scnassets/panda.scn"];
        SCNNode *characterTopLevelNode = characterScene.rootNode.childNodes[0];
        [_node addChildNode:characterTopLevelNode];
        
        
        /// Configure collision capsule
        
        // Collisions are handled by the physics engine. The character is approximated by
        // a capsule that is configured to collide with collectables, enemies and walls
        
        SCNVector3 min, max;
        [_node getBoundingBoxMin:&min max:&max];
        CGFloat collisionCapsuleRadius = (max.x - min.x) * 0.4;
        CGFloat collisionCapsuleHeight = (max.y - min.y);
        
        SCNNode *characterCollisionNode = [SCNNode node];
        characterCollisionNode.name = @"collider";
        characterCollisionNode.position = SCNVector3Make(0.0, collisionCapsuleHeight * 0.51, 0.0);// a bit too high to not hit the floor
        characterCollisionNode.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeKinematic shape:[SCNPhysicsShape shapeWithGeometry:[SCNCapsule capsuleWithCapRadius:collisionCapsuleRadius height:collisionCapsuleHeight] options:nil]];
        characterCollisionNode.physicsBody.contactTestBitMask = AAPLBitmaskSuperCollectable | AAPLBitmaskCollectable | AAPLBitmaskCollision | AAPLBitmaskEnemy;
        [_node addChildNode:characterCollisionNode];
        
        
        /// Load particle systems
        
        // Particle systems were configured in the SceneKit Scene Editor
        // They are retrieved from the scene and their birth rate are stored for later use
        
        _fireEmitter = [characterTopLevelNode childNodeWithName:@"fire" recursively:YES];
        _fireEmitterBirthRate = _fireEmitter.particleSystems[0].birthRate;
        _fireEmitter.particleSystems[0].birthRate = 0;
        _fireEmitter.hidden = NO;
        
        _smokeEmitter = [characterTopLevelNode childNodeWithName:@"smoke" recursively:YES];
        _smokeEmitterBirthRate = _smokeEmitter.particleSystems[0].birthRate;
        _smokeEmitter.particleSystems[0].birthRate = 0;
        _smokeEmitter.hidden = NO;
        
        _whiteSmokeEmitter = [characterTopLevelNode childNodeWithName:@"whiteSmoke" recursively:YES];
        _whiteSmokeEmitterBirthRate = _whiteSmokeEmitter.particleSystems[0].birthRate;
        _whiteSmokeEmitter.particleSystems[0].birthRate = 0;
        _whiteSmokeEmitter.hidden = NO;
        
        
        /// Load sound effects

        _reliefSound = [SCNAudioSource audioSourceNamed:@"game.scnassets/sounds/aah_extinction.mp3"];
        _reliefSound.volume = 2.0;
        [_reliefSound load];
        
        _haltFireSound = [SCNAudioSource audioSourceNamed:@"game.scnassets/sounds/fire_extinction.mp3"];
        _haltFireSound.volume = 2.0;
        [_haltFireSound load];
        
        _catchFireSound = [SCNAudioSource audioSourceNamed:@"game.scnassets/sounds/ouch_firehit.mp3"];
        _catchFireSound.volume = 2.0;
        [_catchFireSound load];
        
        for (NSUInteger i = 0; i < AAPLCharacterStepsCount; i++) {
            _steps[i][AAPLGroundTypeGrass] = [SCNAudioSource audioSourceNamed:[NSString stringWithFormat:@"game.scnassets/sounds/Step_grass_0%d.mp3", (uint32_t)i]];
            _steps[i][AAPLGroundTypeGrass].volume = 0.5;
            [_steps[i][AAPLGroundTypeGrass] load];
            
            _steps[i][AAPLGroundTypeRock] = [SCNAudioSource audioSourceNamed:[NSString stringWithFormat:@"game.scnassets/sounds/Step_rock_0%d.mp3", (uint32_t)i]];
            [_steps[i][AAPLGroundTypeRock] load];
            
            _steps[i][AAPLGroundTypeWater] = [SCNAudioSource audioSourceNamed:[NSString stringWithFormat:@"game.scnassets/sounds/Step_splash_0%d.mp3", (uint32_t)i]];
            [_steps[i][AAPLGroundTypeWater] load];
        }
        
        
        /// Configure animations
        
        // Some animations are already there and can be retrieved from the scene
        // The "walk" animation is loaded from a file, it is configured to play foot steps at specific times during the animation

        [characterTopLevelNode enumerateChildNodesUsingBlock:^(SCNNode *child, BOOL *stop) {
            for(NSString *key in child.animationKeys) {               // for every animation key
                CAAnimation *animation = [child animationForKey:key]; // get the animation
                animation.usesSceneTimeBase = NO;                     // make it system time based
                animation.repeatCount = FLT_MAX;                      // make it repeat forever
                [child addAnimation:animation forKey:key];            // animations are copied upon addition, so we have to replace the previous animation
            }
        }];
        
        _walkAnimation = [self loadAnimationFromSceneNamed:@"game.scnassets/walk.scn"];
        _walkAnimation.usesSceneTimeBase = NO;
        _walkAnimation.fadeInDuration = 0.3;
        _walkAnimation.fadeOutDuration = 0.3;
        _walkAnimation.repeatCount = FLT_MAX;
        _walkAnimation.speed = AAPLCharacterSpeedFactor;
        _walkAnimation.animationEvents = @[[SCNAnimationEvent animationEventWithKeyTime:0.1 block:^(CAAnimation *animation, id animatedObject, BOOL playingBackward) { [self playFootStep]; }],
                                           [SCNAnimationEvent animationEventWithKeyTime:0.6 block:^(CAAnimation *animation, id animatedObject, BOOL playingBackward) { [self playFootStep]; }]];
        
    
        /// Misc
        
        _walkSpeed = 1.0;
    }
    
    return self;
}

#pragma mark - Retrieving nodes

- (SCNNode *)node {
    return _node;
}

#pragma mark - Controlling the character

- (void)setDirectionAngle:(CGFloat)directionAngle {
    _directionAngle = directionAngle;
    [_node runAction:[SCNAction rotateToX:0.0 y:directionAngle z:0.0 duration:0.1 shortestUnitArc:YES]];
}

- (SCNNode *)walkInDirection:(vector_float3)direction time:(NSTimeInterval)time scene:(SCNScene *)scene groundTypeFromMaterial:(AAPLGroundType(^)(SCNMaterial *))groundTypeFromMaterial {
    // delta time since last update
    if (_previousUpdateTime == 0.0) {
        _previousUpdateTime = time;
    }
    
    NSTimeInterval deltaTime = MIN(time - _previousUpdateTime, 1.0 / 60.0);
    CGFloat characterSpeed = deltaTime * AAPLCharacterSpeedFactor * 0.84;
    _previousUpdateTime = time;

    SCNVector3 initialPosition = _node.position;
    
    // move
    if (direction.x != 0.0 && direction.z != 0.0) {
        // move character
        vector_float3 position = SCNVector3ToFloat3(_node.position);
        _node.position = SCNVector3FromFloat3(position + direction * characterSpeed);
        
        // update orientation
        self.directionAngle = atan2(direction.x, direction.z);
     
        self.walking = YES;
    }
    else {
        self.walking = NO;
    }
    
    // Update the altitude of the character
    
    SCNVector3 position = _node.position;
    SCNVector3 p0 = position;
    SCNVector3 p1 = position;
    
    static CGFloat const kMaxRise = 0.08;
    static CGFloat const kMaxJump = 10.0;
    p0.y -= kMaxJump;
    p1.y += kMaxRise;
    
    // Do a vertical ray intersection
    SCNNode *groundNode = nil;
    NSArray<SCNHitTestResult *> *results = [scene.physicsWorld rayTestWithSegmentFromPoint:p1 toPoint:p0 options:@{SCNPhysicsTestCollisionBitMaskKey: @(AAPLBitmaskCollision | AAPLBitmaskWater), SCNPhysicsTestSearchModeKey : SCNPhysicsTestSearchModeClosest}];
    
    SCNHitTestResult *result = results.firstObject;
    if (result) {
        CGFloat groundAltitude = result.worldCoordinates.y;
        groundNode = result.node;
        
        SCNMaterial *groundMaterial = result.node.childNodes[0].geometry.firstMaterial;
        _groundType = groundTypeFromMaterial(groundMaterial);
        
        if (_groundType == AAPLGroundTypeWater) {
            if (_isBurning) {
                [self haltFire];
            }
            
            // do a new ray test without the water to get the altitude of the ground (under the water).
            results = [scene.physicsWorld rayTestWithSegmentFromPoint:p1 toPoint:p0 options:@{SCNPhysicsTestCollisionBitMaskKey : @(AAPLBitmaskCollision), SCNPhysicsTestSearchModeKey : SCNPhysicsTestSearchModeClosest}];
            
            result = results.firstObject;
            groundAltitude = result.worldCoordinates.y;
        }
        
        static CGFloat const kThreshold = 1e-5;
        static CGFloat const kGravityAcceleration = 0.18;
        
        if (groundAltitude < position.y - kThreshold) {
            _accelerationY += deltaTime * kGravityAcceleration; // approximation of acceleration for a delta time.
            if (groundAltitude < position.y - 0.2) {
                _groundType = AAPLGroundTypeInTheAir;
            }
        }
        else {
            _accelerationY = 0;
        }
        
        position.y -= _accelerationY;
        
        // reset acceleration if we touch the ground
        if (groundAltitude > position.y) {
            _accelerationY = 0;
            position.y = groundAltitude;
        }
        
        // Finally, update the position of the character.
        _node.position = position;
        
    }
    else {
        // no result, we are probably out the bounds of the level -> revert the position of the character.
        _node.position = initialPosition;
    }
    
    return groundNode;
}

#pragma mark - Animating the character

- (void)setWalking:(BOOL)walking {
    if (_isWalking != walking) {
        _isWalking = walking;
        
        // Update node animation.
        if (_isWalking) {
            [_node addAnimation:_walkAnimation forKey:@"walk"];
        }
        else {
            [_node removeAnimationForKey:@"walk" fadeOutDuration:0.2];
        }
    }
}

- (void)setWalkSpeed:(CGFloat)walkSpeed {
    _walkSpeed = walkSpeed;
    
    // remove current walk animation if any.
    BOOL wasWalking = _isWalking;
    if (wasWalking)
        self.walking = NO;
    
    _walkAnimation.speed = AAPLCharacterSpeedFactor * _walkSpeed;
    
    // restore walk animation if needed.
    if (wasWalking)
        self.walking = YES;
}

#pragma mark - Dealing with fire

- (void)catchFire {
    if (_isInvincible == NO) {
        _isInvincible = YES;
        [_node runAction:[SCNAction sequence:@[[SCNAction playAudioSource:_catchFireSound waitForCompletion:NO],
                                               [SCNAction repeatAction:[SCNAction sequence:@[[SCNAction fadeOpacityTo:0.01 duration:0.1],
                                                                                             [SCNAction fadeOpacityTo:1.0 duration:0.1]]]
                                                                 count:7],
                                               [SCNAction runBlock:^(SCNNode *node) { _isInvincible = NO; }]]]];
    }
    
    _isBurning = YES;
    
    // start fire + smoke
    _fireEmitter.particleSystems[0].birthRate = _fireEmitterBirthRate;
    _smokeEmitter.particleSystems[0].birthRate = _smokeEmitterBirthRate;
    
    // walk faster
    self.walkSpeed = 2.3;
}

- (void)haltFire {
    if (_isBurning) {
        _isBurning = NO;
        
        [_node runAction:[SCNAction sequence:@[[SCNAction playAudioSource:_haltFireSound waitForCompletion:true],
                                               [SCNAction playAudioSource:_reliefSound waitForCompletion:false]]]];

        // stop fire and smoke
        _fireEmitter.particleSystems[0].birthRate = 0;
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:1.0];
        _smokeEmitter.particleSystems[0].birthRate = 0;
        [SCNTransaction commit];
        
        // start white smoke
        _whiteSmokeEmitter.particleSystems[0].birthRate = _whiteSmokeEmitterBirthRate;
        
        // progressively stop white smoke
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:5.0];
        _whiteSmokeEmitter.particleSystems[0].birthRate = 0;
        [SCNTransaction commit];
        
        // walk normally
        self.walkSpeed = 1.0;
    }
}

#pragma mark - Dealing with sound

- (void)playFootStep {
    if (_groundType != AAPLGroundTypeInTheAir) { // We are in the air, no sound to play.
        // Play a random step sound.
        NSInteger stepSoundIndex = MIN(AAPLCharacterStepsCount - 1, (rand() / (float)RAND_MAX) * AAPLCharacterStepsCount);
        [_node runAction:[SCNAction playAudioSource:_steps[stepSoundIndex][_groundType] waitForCompletion:NO]];
    }
}

#pragma mark - Utils

- (CAAnimation *)loadAnimationFromSceneNamed:(NSString *)sceneName {
    SCNScene *scene = [SCNScene sceneNamed:sceneName];
    
    // find top level animation
    __block CAAnimation *animation = nil;
    [scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode *child, BOOL *stop) {
        if (child.animationKeys.count > 0) {
            animation = [child animationForKey:child.animationKeys[0]];
            *stop = YES;
        }
    }];
    
    return animation;
}

@end
