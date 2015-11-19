/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This class manages the main character, including its animations, sounds and direction.
*/

@import SceneKit;

#import "AAPLGameViewController.h"
#import "AAPLCharacter.h"

#define StepsSoundCount 10
#define StepsInWaterSoundCount 4

@implementation AAPLCharacter
{
    SCNNode *_node;
    float _direction;
    BOOL _walk;
    BOOL _burning;

    CGFloat _fireBirthRate;
    CGFloat _smokeBirthRate;
    CGFloat _whiteSmokeBirthRate;
    
    SCNNode *_fireEmitter;
    SCNNode *_smokeEmitter;
    SCNNode *_whiteSmokeEmitter;
    
    CAAnimation *_walkAnimation;

    SCNAudioSource *_steps[StepsSoundCount][AAPLFloorMaterialCount];
}

- (void) setWalk:(BOOL)walk
{
    if (walk != _walk) {
        _walk = walk;
        
        // Update node animation.
        if (_walk) {
            [_node addAnimation:_walkAnimation forKey:@"walk"];
        }
        else {
            [_node removeAnimationForKey:@"walk" fadeOutDuration:0.2];
        }
    }
}

- (void) setDirection:(float)dir
{
    if (_direction != dir) {
        _direction = dir;
        [_node runAction:[SCNAction rotateToX:0 y:dir z:0 duration:0.1 shortestUnitArc:YES]];
    }
}

- (void)playFootStep
{
    if (_floorMaterial == AAPLFloorMaterialInTheAir) {
        return; // We are in the air, no sound to play.
    }

    // Play a random step sound.
    NSInteger stepSoundIndex = MIN(StepsSoundCount-1, (rand() / (float)RAND_MAX) * StepsSoundCount);
    [_node runAction:[SCNAction playAudioSource:_steps[stepSoundIndex][_floorMaterial] waitForCompletion:NO]];
}

- (instancetype)init
{
    if ((self = [super init])) {

        // Load steps sounds.
        for (int i=0; i < StepsSoundCount; i++) {
            _steps[i][AAPLFloorMaterialGrass] = [SCNAudioSource audioSourceNamed:[NSString stringWithFormat:@"game.scnassets/sounds/Step_grass_0%d.mp3", i]];
            _steps[i][AAPLFloorMaterialGrass].volume = 0.5;
            _steps[i][AAPLFloorMaterialRock] = [SCNAudioSource audioSourceNamed:[NSString stringWithFormat:@"game.scnassets/sounds/Step_rock_0%d.mp3", i]];
            if( i < StepsInWaterSoundCount ){
                _steps[i][AAPLFloorMaterialWater] = [SCNAudioSource audioSourceNamed:[NSString stringWithFormat:@"game.scnassets/sounds/Step_splash_0%d.mp3", i]];
                [_steps[i][AAPLFloorMaterialWater] load];
            }
            else{
                _steps[i][AAPLFloorMaterialWater] = _steps[i%StepsInWaterSoundCount][AAPLFloorMaterialWater];
            }
            
            [_steps[i][AAPLFloorMaterialRock] load];
            [_steps[i][AAPLFloorMaterialGrass] load];
        }
        
        // Load the character.
        SCNScene *characterScene = [SCNScene sceneNamed:@"game.scnassets/panda.scn"];
        SCNNode *characterTopLevelNode = characterScene.rootNode.childNodes[0];
        
        // Create an intermediate node to manipulate the whole group at once.
        _node = [SCNNode node];
        [_node addChildNode:characterTopLevelNode];
        
        // Configure the "idle" animation to repeat forever.
        [characterTopLevelNode enumerateChildNodesUsingBlock:^(SCNNode *child, BOOL *stop) {
            for(NSString *key in child.animationKeys) { //for every animation keys
                CAAnimation *animation = [child animationForKey:key]; //get the animation
                
                animation.usesSceneTimeBase = NO; //make it systemTime based
                animation.repeatCount = INFINITY; //repeat forever
                
                [child addAnimation:animation forKey:key]; //replace the previous animation
            }
        }];
        
        // retrieve some particle systems and save their birth rate
        _fireEmitter = [characterTopLevelNode childNodeWithName:@"fire" recursively:YES];
        _fireBirthRate = _fireEmitter.particleSystems[0].birthRate;
        _fireEmitter.particleSystems[0].birthRate = 0;
        _fireEmitter.hidden = NO;

        _smokeEmitter = [characterTopLevelNode childNodeWithName:@"smoke" recursively:YES];
        _smokeBirthRate = _smokeEmitter.particleSystems[0].birthRate;
        _smokeEmitter.particleSystems[0].birthRate = 0;
        _smokeEmitter.hidden = NO;
        
        _whiteSmokeEmitter = [characterTopLevelNode childNodeWithName:@"whiteSmoke" recursively:YES];
        _whiteSmokeBirthRate = _whiteSmokeEmitter.particleSystems[0].birthRate;
        _whiteSmokeEmitter.particleSystems[0].birthRate = 0;
        _whiteSmokeEmitter.hidden = NO;

        // Configure the physics body of the character.
        SCNVector3 min,max;
        [_node getBoundingBoxMin:&min max:&max];
        
        CGFloat radius = (max.x - min.x) * 0.4;
        CGFloat height = (max.y - min.y);
        
        // Create a kinematic with capsule.
        SCNNode *colliderNode = [SCNNode node];
        colliderNode.name = @"collider";
        colliderNode.position = SCNVector3Make(0, height * 0.51, 0);// a bit too high to not hit the floor
        colliderNode.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeKinematic shape:[SCNPhysicsShape shapeWithGeometry:[SCNCapsule capsuleWithCapRadius:radius height:height] options:nil]];
        
        // We want contact notifications with the collectables, enemies and walls.
        colliderNode.physicsBody.contactTestBitMask = AAPLBitmaskSuperCollectable | AAPLBitmaskCollectable | AAPLBitmaskCollision | AAPLBitmaskEnemy;
        [_node addChildNode:colliderNode];
        
        // Load and configure the walk animation
        _walkAnimation = [self loadAnimationFromSceneNamed:@"game.scnassets/walk.scn"];
        _walkAnimation.usesSceneTimeBase = NO;
        _walkAnimation.fadeInDuration = 0.3;
        _walkAnimation.fadeOutDuration = 0.3;
        _walkAnimation.repeatCount = INFINITY;
        _walkAnimation.speed = CharacterSpeedFactor;
        
        // Play foot steps at specific times in the animation.
        _walkAnimation.animationEvents = @[
                                           [SCNAnimationEvent animationEventWithKeyTime:0.1 block:^(CAAnimation *animation, id animatedObject, BOOL playingBackward) {
                                               [self playFootStep];
                                           }],
                                           [SCNAnimationEvent animationEventWithKeyTime:0.6 block:^(CAAnimation *animation, id animatedObject, BOOL playingBackward) {
                                               [self playFootStep];
                                           }]
                                           ];
    }
    
    return self;
}

// utility to load the first found animation in a scene at the specified scene
- (CAAnimation *)loadAnimationFromSceneNamed:(NSString *)path
{
    SCNScene *scene = [SCNScene sceneNamed:path];
    
    __block CAAnimation *animation = nil;
    
    //find top level animation
    [scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode *child, BOOL *stop) {
        if (child.animationKeys.count > 0) {
            animation = [child animationForKey:child.animationKeys[0]];
            *stop = YES;
        }
    }];
    
    return animation;
}

- (SCNNode *)physicsNode
{
    return _node.childNodes[0];
}

- (SCNNode *)node
{
    return _node;
}

- (void)updateWalkSpeed:(CGFloat)speedFactor
{
    BOOL wasWalking = _walk;
    
    // remove current walk animation if any.
    if(wasWalking)
        self.walk = NO;
    
    _walkAnimation.speed = CharacterSpeedFactor * speedFactor;
    
    // restore walk animation if needed.
    if(wasWalking)
        self.walk = YES;

}

- (void)hit
{
    _burning = YES;
    
    //start fire + smoke
    _fireEmitter.particleSystems[0].birthRate = _fireBirthRate;
    _smokeEmitter.particleSystems[0].birthRate = _smokeBirthRate;
    
    //walk faster
    [self updateWalkSpeed:2.3];
}

- (void)pshhhh
{
    if (_burning) {
        _burning = NO;
        
        //stop fire and smoke
        _fireEmitter.particleSystems[0].birthRate = 0;
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:1.0];
        _smokeEmitter.particleSystems[0].birthRate = 0;
        [SCNTransaction commit];
        
        // start white smoke
        _whiteSmokeEmitter.particleSystems[0].birthRate = _whiteSmokeBirthRate;
        
        // progressively stop white smoke
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:5.0];
        _whiteSmokeEmitter.particleSystems[0].birthRate = 0;
        [SCNTransaction commit];
        
        // walk normally
        [self updateWalkSpeed:1.0];
    }
}

@end
