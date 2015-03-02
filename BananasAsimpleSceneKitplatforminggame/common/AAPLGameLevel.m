/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  This class manages most of the game logic, including setting up the scene and keeping score.
  
 */

#import <GLKit/GLKit.h>
#import <SpriteKit/SpriteKit.h>
#import <SceneKit/SceneKit.h>
#import <GameKit/GameKit.h>

#import "AAPLMathUtils.h"
#import "AAPLGameLevel.h"
#import "AAPLPlayerCharacter.h"
#import "AAPLMonkeyCharacter.h"
#import "AAPLAppDelegate.h"
#import "AAPLSceneView.h"
#import "AAPLGameSimulation.h"
#import "AAPLCoconut.h"
#import "AAPLInGameScene.h"

typedef enum {
	AAPLShadowReceiverCategory = 2,
} AAPLCategoryBitMasks;

#define BANANA_SCALE_LARGE 0.5 * 10./4.
#define BANANA_SCALE 0.5

@interface AAPLGameLevel () {
	SCNVector3 _lightOffsetFromCharacter;
	SCNVector3 _screenSpaceplayerPosition;
	SCNVector3 _worldSpaceLabelScorePosition;
}

@property (strong, nonatomic) SCNNode *rootNode;
@property (strong, nonatomic) SCNNode *sunLight;
@property (strong, nonatomic) SCNAction *bananaIdleAction;
@property (strong, nonatomic) SCNAction *hoverAction;
@property (strong, nonatomic) NSMutableArray *pathPositions;
@property (strong, nonatomic) SCNNode *bananaCollectable;
@property (strong, nonatomic) SCNNode *largeBananaCollectable;
@property (strong, nonatomic) AAPLSkinnedCharacter *monkeyProtoObject;
@property (strong, nonatomic) SCNNode *coconutProtoObject;
@property (strong, nonatomic) SCNNode *palmTreeProtoObject;
@property (strong, nonatomic) NSMutableArray *monkeys;

@end

@implementation AAPLGameLevel

- (BOOL)isHighEnd
{
	//todo: return YES on OSX, iPad air, iphone 5s - NO otherwie
	return YES;
}

/*! Helper Method for creating a large banana
 Create model, Add particle system, Add persistent SKAction, Add / Setup collision
 */
- (SCNNode *)createLargeBanana
{
	if (self.largeBananaCollectable == nil) {
		NSString *bananaPath = [AAPLGameSimulation pathForArtResource:@"level/banana.dae"];
		SCNNode *node = [AAPLGameSimulation loadNodeWithName:@"banana"
											 fromSceneNamed:bananaPath];

		node.scale = SCNVector3Make(BANANA_SCALE_LARGE, BANANA_SCALE_LARGE, BANANA_SCALE_LARGE);

		SCNSphere *sphereGeometry = [SCNSphere sphereWithRadius:100];
		SCNPhysicsShape *physicsShape = [SCNPhysicsShape shapeWithGeometry:sphereGeometry options:nil];
		node.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeKinematic shape:physicsShape];

		// Only collide with player and ground
		node.physicsBody.collisionBitMask = GameCollisionCategoryPlayer | GameCollisionCategoryGround;

		// Declare self in the coin category
		node.physicsBody.categoryBitMask = GameCollisionCategoryCoin;

		// Rotate forever.
		SCNAction *rotateCoin = [SCNAction rotateByX:0 y:8 z:0 duration:2.0f];
		SCNAction *repeat = [SCNAction repeatActionForever:rotateCoin];

		node.rotation = SCNVector4Make(0, 1, 0, M_PI_2);
		[node runAction:repeat];

		self.largeBananaCollectable = node;
	}

	SCNNode *node = [self.largeBananaCollectable clone];

	SCNParticleSystem *newSystem = [AAPLGameSimulation loadParticleSystemWithName:@"sparkle"];
	[node addParticleSystem:newSystem];

	return node;
}

/*! Helper Method for creating a small banana
 */
- (SCNNode *)createBanana
{
	//Create model
	if (self.bananaCollectable == nil) {
		self.bananaCollectable = [AAPLGameSimulation loadNodeWithName:@"banana" fromSceneNamed:[AAPLGameSimulation pathForArtResource:@"level/banana.dae"]];

		self.bananaCollectable.scale = SCNVector3Make(BANANA_SCALE, BANANA_SCALE, BANANA_SCALE);

		SCNSphere *sphereGeometry = [SCNSphere sphereWithRadius:40];
		SCNPhysicsShape *physicsShape = [SCNPhysicsShape shapeWithGeometry:sphereGeometry options:nil];

		self.bananaCollectable.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeKinematic shape:physicsShape];

		// Only collide with player and ground
		self.bananaCollectable.physicsBody.collisionBitMask = GameCollisionCategoryPlayer | GameCollisionCategoryGround;
		// Declare self in the banana category
		self.bananaCollectable.physicsBody.categoryBitMask = GameCollisionCategoryBanana;

		// Rotate and Hover forever.
		self.bananaCollectable.rotation = SCNVector4Make(0.5, 1, 0.5, -M_PI_4);
		SCNAction *idleHoverGroupAction = [SCNAction group:@[self.bananaIdleAction, self.hoverAction]];
		SCNAction *repeatForeverAction = [SCNAction repeatActionForever:idleHoverGroupAction];
		[self.bananaCollectable runAction:repeatForeverAction];
	}

	return [self.bananaCollectable clone];
}

- (void)setupPathColliders
{
	// Collect all the nodes that start with path_ under the dummy_front object.
	// Set those objects as Physics category ground and create a static concave mesh collider.
	// The simulation will use these as the ground to walk on.
	SCNNode *front = [self.rootNode childNodeWithName:@"dummy_front" recursively:YES];
	[front enumerateChildNodesUsingBlock:^(SCNNode *child, BOOL *stop) {
		if ([child.name hasPrefix:@"path_"]) {
			SCNNode *path = child.childNodes.firstObject; //the geometry is attached to the first child node of the node named path_*

			path.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeStatic shape:[SCNPhysicsShape shapeWithGeometry:path.geometry options:@{SCNPhysicsShapeTypeKey : SCNPhysicsShapeTypeConcavePolyhedron}]];
			path.physicsBody.categoryBitMask = GameCollisionCategoryGround;
		}
	}];
}

- (NSArray *)collectSortedPathNodes
{
	// Gather all the children under the dummy_master
	// Sort left to right, in the world.
	SCNNode *pathNodes = [self.rootNode childNodeWithName:@"dummy_master" recursively:YES];

	NSArray *sortedNodes = [pathNodes.childNodes sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		SCNNode *dummyA = obj1;
		SCNNode *dummyB = obj2;

		if (dummyA.position.x > dummyB.position.x) {
			return NSOrderedDescending;
		}
		return NSOrderedAscending;
	}];
	return sortedNodes;
}

- (void)convertPathNodesIntoPathPositions
{
	// Walk the path, sampling every little bit, creating a path to follow.
	// We use this path to move along left to right and right to left.
	NSArray *sortedNodes;
	sortedNodes = [self collectSortedPathNodes];

	self.pathPositions = [[NSMutableArray alloc] init];
	[self.pathPositions addObject:[NSValue valueWithSCNVector3:SCNVector3Make(0, 0, 0)]];

	for (SCNNode *d in sortedNodes) {
		if ([d.name hasPrefix:@"dummy_path_"] == NO) {
			continue;
		}
		[self.pathPositions addObject:[NSValue valueWithSCNVector3:d.position]];
	}
	[self.pathPositions addObject:[NSValue valueWithSCNVector3:SCNVector3Make(0, 0, 0)]];
}

- (void)resamplePathPositions
{
	// Calc the phatom end control point.
	SCNVector3 controlPointA = [self.pathPositions[self.pathPositions.count - 2] SCNVector3Value];
	SCNVector3 controlPointB = [self.pathPositions[self.pathPositions.count - 3] SCNVector3Value];
	SCNVector3 controlPoint;

	controlPoint.x = controlPointA.x + (controlPointA.x - controlPointB.x);
	controlPoint.y = controlPointA.y + (controlPointA.y - controlPointB.y);
	controlPoint.z = controlPointA.z + (controlPointA.z - controlPointB.z);

	self.pathPositions[self.pathPositions.count - 1] = [NSValue valueWithSCNVector3:controlPoint];

	// Calc the phatom begin control point.
	controlPointA = [self.pathPositions[1] SCNVector3Value];
	controlPointB = [self.pathPositions[2] SCNVector3Value];

	controlPoint.x = controlPointA.x + (controlPointA.x - controlPointB.x);
	controlPoint.y = controlPointA.y + (controlPointA.y - controlPointB.y);
	controlPoint.z = controlPointA.z + (controlPointA.z - controlPointB.z);
	self.pathPositions[0] = [NSValue valueWithSCNVector3:controlPoint];

	NSMutableArray *newPath = [[NSMutableArray alloc] init];
	SCNVector3 lastPosition;
	CGFloat minDistanceBetweenPoints = 10.0;
	NSUInteger steps = 10000;
	for (NSInteger i = 0; i < steps; i++) {
		CGFloat t = (CGFloat)i / (CGFloat)steps;
		SCNVector3 currentPostion = [self locationAlongPath:t];
		if (i == 0) {
			[newPath addObject:[NSValue valueWithSCNVector3:currentPostion]];
			lastPosition = currentPostion;
		} else {
			CGFloat dist = GLKVector3Distance(SCNVector3ToGLKVector3(currentPostion), SCNVector3ToGLKVector3(lastPosition));
			if (dist > minDistanceBetweenPoints) {
				[newPath addObject:[NSValue valueWithSCNVector3:currentPostion]];
				lastPosition = currentPostion;
			}
		}
	}

	// Last Step. Return the path position array for our pathing system to query.
	self.pathPositions = newPath;
}

- (void)calculatePathPositions
{

	[self setupPathColliders];

	[self convertPathNodesIntoPathPositions];

	[self resamplePathPositions];
}

/*! Given a relative percent along the path, return back the world location vector.
 */
- (SCNVector3)locationAlongPath:(CGFloat)percent
{
	if (self.pathPositions.count <= 3) {
		return SCNVector3Make(0, 0, 0);
	}

	NSUInteger numSections = self.pathPositions.count - 3;
	CGFloat dist = percent * (CGFloat)numSections;

	NSUInteger currentPointIndex = MIN((NSUInteger)floorf(dist), numSections - 1);
	dist -= (CGFloat)currentPointIndex;
	GLKVector3 a = SCNVector3ToGLKVector3([self.pathPositions[currentPointIndex] SCNVector3Value]);
	GLKVector3 b = SCNVector3ToGLKVector3([self.pathPositions[currentPointIndex + 1] SCNVector3Value]);
	GLKVector3 c = SCNVector3ToGLKVector3([self.pathPositions[currentPointIndex + 2] SCNVector3Value]);
	GLKVector3 d = SCNVector3ToGLKVector3([self.pathPositions[currentPointIndex + 3] SCNVector3Value]);

	SCNVector3 location;

#define CatmullRomValue(a, b, c, d, dist) \
(((-a + 3.0 * b - 3.0 * c + d) * (dist * dist * dist)) + \
((2.0 * a - 5.0 * b + 4.0 * c - d) * (dist * dist)) + \
((-a + c) * dist) + \
(2.0 * b)) * 0.5; \

	location.x = CatmullRomValue(a.x, b.x, c.x, d.x, dist);
	location.y = CatmullRomValue(a.y, b.y, c.y, d.y, dist);
	location.z = CatmullRomValue(a.z, b.z, c.z, d.z, dist);

	return location;
}

/*! Direction player facing given the current walking direction.
 */
- (SCNVector4)getDirectionFromPosition:(SCNVector3)currentPosition
{

	SCNVector3 target = [self locationAlongPath:self.timeAlongPath - 0.05];

	GLKMatrix4 lookat = GLKMatrix4MakeLookAt(currentPosition.x, currentPosition.y, currentPosition.z, target.x, target.y, target.z, 0, 1, 0);
	GLKQuaternion q = GLKQuaternionMakeWithMatrix4(lookat);

	CGFloat angle = GLKQuaternionAngle(q);
	if (self.playerCharacter.walkDirection == WalkDirectionLeft) {
		angle -= M_PI;
	}
	return SCNVector4Make(0, 1, 0, angle);
}

/* Helper method for getting main player's direction
 */
- (SCNVector4)getPlayerDirectionFromCurrentPosition
{
	return [self getDirectionFromPosition:self.playerCharacter.position];
}

// Helper Method for loading the Swinging Torch
//
// Load the dae from disk
// Attach to origin
- (void)createSwingingTorch
{

	SCNNode *torchSwing = [AAPLGameSimulation loadNodeWithName:@"dummy_master" fromSceneNamed:[AAPLGameSimulation pathForArtResource:@"level/torch.dae"]];
	[self.rootNode addChildNode:torchSwing];
}

// createLavaAnimation
//
// Find the lava nodes in the scene.
// Add a concave collider to each lava mesh
// UV animate the lava texture in the vertex shader.
- (void)createLavaAnimation
{
	NSArray *lavaNodes = [self.rootNode childNodesPassingTest:^BOOL(SCNNode *child, BOOL *stop) {
		if ([child.name hasPrefix:@"lava_0"] == YES) {
			return YES;
		}
		return NO;
	}];

	for (SCNNode *lava in lavaNodes) {
		NSArray *childrenWithGeometry = [lava childNodesPassingTest:^BOOL(SCNNode *child, BOOL *stop) {
			if (child.geometry != nil) {
				*stop = YES;
				return YES;
			}

			return NO;
		}];

		SCNNode *lavaGeometry = childrenWithGeometry[0];

		lavaGeometry.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeStatic shape:[SCNPhysicsShape shapeWithGeometry:lavaGeometry.geometry options:@{SCNPhysicsShapeTypeKey : SCNPhysicsShapeTypeConcavePolyhedron}]];
		lavaGeometry.physicsBody.categoryBitMask = GameCollisionCategoryLava;
		lavaGeometry.categoryBitMask = NodeCategoryLava;

		NSString *shaderCode =
		@"uniform float speed;\n"
		@"#pragma body\n"
		@"_geometry.texcoords[0] += vec2(sin(_geometry.position.z*0.1 + u_time * 0.1) * 0.1, -1.0* 0.05 * u_time);\n";
		lavaGeometry.geometry.shaderModifiers = @{ SCNShaderModifierEntryPointGeometry : shaderCode};
	}
}

/*! Create an action that rotates back and forth.
 */
- (SCNAction *)bananaIdleAction
{
	if (_bananaIdleAction == nil) {
		SCNAction *rotateAction = [SCNAction rotateByX:0 y:M_PI_2 z:0 duration:1.0f];
		rotateAction.timingMode = SCNActionTimingModeEaseInEaseOut;
		SCNAction *reversed = [rotateAction reversedAction];
		_bananaIdleAction = [SCNAction sequence:@[rotateAction, reversed]];
	}
	return _bananaIdleAction;
}

/*! Create an action that hovers up and down slightly.
 */
- (SCNAction *)hoverAction
{
	if (_hoverAction == nil) {
		SCNAction *floatAction = [SCNAction moveByX:0 y:10.0f z:0 duration:1.0f];
		SCNAction *floatAction2 = [floatAction reversedAction];
		floatAction.timingMode = SCNActionTimingModeEaseInEaseOut;
		floatAction2.timingMode = SCNActionTimingModeEaseInEaseOut;
		_hoverAction = [SCNAction sequence:@[floatAction, floatAction2]];
	}
	return _hoverAction;
}

/*! Create an action that pulses the opacity of a node.
 */
- (SCNAction *)pulseAction
{
	CGFloat duration = 8.0f / 6.0f;
	SCNAction *pulseAction = [SCNAction repeatActionForever:
							  [SCNAction sequence:@[[SCNAction fadeOpacityTo:0.3 duration:duration],
													[SCNAction fadeOpacityTo:0.5 duration:duration],
													[SCNAction fadeOpacityTo:1.0 duration:duration],
													[SCNAction fadeOpacityTo:0.7 duration:duration],
													[SCNAction fadeOpacityTo:0.4 duration:duration],
													[SCNAction fadeOpacityTo:0.8 duration:duration]]]];
	return pulseAction;
}

/* Create a simple point light
 */
- (SCNLight *)torchLight
{
	SCNLight *light = [SCNLight light];
	light.type = SCNLightTypeOmni;
	light.color = [SKColor orangeColor];
	light.attenuationStartDistance = 350;
	light.attenuationEndDistance = 400;
	light.attenuationFalloffExponent = 1;
	return light;
}

/*! Create a torch node that has a particle effect and point light attached.
 */
- (SCNNode *)createTorchNode
{
	static SCNNode *template;

	if (template == nil) {
		template = [SCNNode node];

		SCNGeometry *geometry = [SCNBox boxWithWidth:20 height:100 length:20 chamferRadius:0];
		geometry.firstMaterial.diffuse.contents = [SKColor brownColor];
		template.geometry = geometry;

		SCNNode *particleEmitter = [SCNNode node];
		particleEmitter.position = SCNVector3Make(0, 50, 0);

		SCNParticleSystem *fire = [SCNParticleSystem particleSystemNamed:@"torch.scnp"
															 inDirectory:@"art.scnassets/level/effects"];
		[particleEmitter addParticleSystem:fire];

		particleEmitter.light = [self torchLight];

		[template addChildNode:particleEmitter];
	}

	return [template clone];
}

// CreateLevel
//
// Load the level dae from disk
// Setup and construct the level. ( Should really be done offline in an editor ).
- (SCNNode *)createLevel
{

	self.rootNode = [SCNNode node];

	// load level dae and add all root children to the scene.
	SCNScene *scene = [SCNScene sceneNamed:@"level.dae" inDirectory:[AAPLGameSimulation pathForArtResource:@"level/"] options: @{SCNSceneSourceConvertToYUpKey : @YES}];
	for (SCNNode *node in scene.rootNode.childNodes) {
		[self.rootNode addChildNode:node];
	}

	// retrieve the main camera
	self.camera = [self.rootNode childNodeWithName:@"camera_game" recursively:YES];

	// create our path that the player character will follow.
	[self calculatePathPositions];

	//-- Sun/Moon light
	self.sunLight = [self.rootNode childNodeWithName:@"FDirect001" recursively:YES];
	self.sunLight.eulerAngles = SCNVector3Make(7.1 * M_PI_4, M_PI_4, 0);
	self.sunLight.light.shadowSampleCount = 1; //to match iOS while testing: to be removed from the sample code
	_lightOffsetFromCharacter = SCNVector3Make(1500, 2000, 1000);

	//workaround directional light deserialization issue
	self.sunLight.light.zNear = 100;
	self.sunLight.light.zFar = 5000;
	self.sunLight.light.orthographicScale = 1000;

	if (![self isHighEnd]) {
		//use blob shadows on low end devices
		self.sunLight.light.shadowMode = SCNShadowModeModulated;
		self.sunLight.light.categoryBitMask = 0x2;
		self.sunLight.light.orthographicScale = 60;
		self.sunLight.eulerAngles = SCNVector3Make(M_PI_2, 0, 0);
		_lightOffsetFromCharacter = SCNVector3Make(0, 2000, 0);

		self.sunLight.light.gobo.contents = @"art.scnassets/techniques/blobShadow.jpg";
		self.sunLight.light.gobo.intensity = 0.5;

		SCNNode *middle = [self.rootNode childNodeWithName:@"dummy_front" recursively:YES];
		[middle enumerateChildNodesUsingBlock:^(SCNNode *child, BOOL *stop) {
			child.categoryBitMask = 0x2;
		}];
	}

	//-- Torches
	float torchesPos[8] = {0, -1, 0.092467, -1, -1, 0.5, 0.7920, 0.953830};

	for (int i = 0; i < 8; i++) {
		if (torchesPos[i] == -1) continue;
		SCNVector3 location = [self locationAlongPath:torchesPos[i]];
		location.y += 50;
		location.z += 150;

		SCNNode *node = [self createTorchNode];

		node.position = location;
		[self.rootNode addChildNode:node];
	}

	// After load, we add nodes that are dynamic / animated / or otherwise not static.
	[self createLavaAnimation];
	[self createSwingingTorch];
	[self animateDynamicNodes];

	// Create our player character
	SCNNode *characterRoot = [AAPLGameSimulation loadNodeWithName:nil fromSceneNamed:@"art.scnassets/characters/explorer/explorer_skinned.dae"];
	self.playerCharacter = [[AAPLPlayerCharacter alloc] initWithNode:characterRoot];
	self.timeAlongPath = 0;
	self.playerCharacter.position = [self locationAlongPath:self.timeAlongPath];
	self.playerCharacter.rotation = [self getPlayerDirectionFromCurrentPosition];
	[self.rootNode addChildNode:self.playerCharacter];

	// Optimize lighting and shadows
	// only the charadcter should cast shadows
	[self.rootNode enumerateChildNodesUsingBlock:^(SCNNode *child, BOOL *stop) {
		child.castsShadow = NO;
	}];
	[self.playerCharacter enumerateChildNodesUsingBlock:^(SCNNode *child, BOOL *stop) {
		child.castsShadow = YES;
	}];

	// Add some monkeys to the scene.
	[self addMonkeyAtPosition:SCNVector3Make(0, -30, -400) andRotation:0];
	[self addMonkeyAtPosition:SCNVector3Make(3211, 146, -400) andRotation:-M_PI_4];
	[self addMonkeyAtPosition:SCNVector3Make(5200, 330, 600) andRotation:0];

	//- Volcano
	SCNNode *oldVolcano = [self.rootNode childNodeWithName:@"volcano" recursively:YES];
	NSString *volcanoDaeName = [AAPLGameSimulation pathForArtResource:@"level/volcano_effects.dae"];
	SCNNode *newVolcano = [AAPLGameSimulation loadNodeWithName:@"dummy_master"
											   fromSceneNamed:volcanoDaeName];
	[oldVolcano addChildNode:newVolcano];
	oldVolcano.geometry = nil;
	oldVolcano = [newVolcano childNodeWithName:@"volcano" recursively:YES];
	oldVolcano = oldVolcano.childNodes[0];

	//-- Animate our dynamic volcano node.
	NSString *shaderCode =
	@"uniform float speed;\n"
	@"_geometry.color = vec4(a_color.r, a_color.r, a_color.r, a_color.r);\n"
	@"_geometry.texcoords[0] += (vec2(0.0, 1.0) * 0.05 * u_time);\n";

	NSString *fragmentShaderCode =
	@"#pragma transparent\n";

	//dim background
	SCNNode *back = [self.rootNode childNodeWithName:@"dumy_rear" recursively:YES];
	[back enumerateChildNodesUsingBlock:^(SCNNode *child, BOOL *stop) {
		child.castsShadow = NO;

		for (SCNMaterial *material in child.geometry.materials) {
			material.lightingModelName = SCNLightingModelConstant;
			material.multiply.contents = [SKColor colorWithWhite:0.3 alpha:1.0];
			material.multiply.intensity = 1;
		}
	}];

	//remove lighting from middle plane
	{
		SCNNode *back = [self.rootNode childNodeWithName:@"dummy_middle" recursively:YES];
		[back enumerateChildNodesUsingBlock:^(SCNNode *child, BOOL *stop) {
			for (SCNMaterial *material in child.geometry.materials) {
				material.lightingModelName = SCNLightingModelConstant;
			}
		}];
	}

	[newVolcano enumerateChildNodesUsingBlock:^(SCNNode *child, BOOL *stop) {
		if (child != oldVolcano && child.geometry != nil) {
			child.geometry.firstMaterial.lightingModelName = SCNLightingModelConstant;
			child.geometry.firstMaterial.multiply.contents = [SKColor whiteColor];
			child.geometry.shaderModifiers = @{ SCNShaderModifierEntryPointGeometry : shaderCode,
												SCNShaderModifierEntryPointFragment : fragmentShaderCode };
		}
	}];


	if (![self isHighEnd]) {
		[self.rootNode enumerateChildNodesUsingBlock:^(SCNNode *child, BOOL *stop) {
			for (SCNMaterial *m in child.geometry.materials) {
				m.lightingModelName = SCNLightingModelConstant;
			}
		}];

		[self.playerCharacter enumerateChildNodesUsingBlock:^(SCNNode *child, BOOL *stop) {
			for (SCNMaterial *material in child.geometry.materials) {
				material.lightingModelName = SCNLightingModelLambert;
			}
		}];
	}

	self.coconuts = [[NSMutableArray alloc] init];
	return self.rootNode;
}

/*! Given a world position and rotation, load the monkey dae and place it into the world.
 */
- (void)addMonkeyAtPosition:(SCNVector3)worldPos andRotation:(CGFloat)rotation
{
	if (self.monkeys == nil) {
		self.monkeys = [[NSMutableArray alloc] init];
	}

	SCNNode *palmTree = [self createMonkeyPalmTree];
	palmTree.position = worldPos;
	palmTree.rotation = SCNVector4Make(0, 1, 0, rotation);
	[self.rootNode addChildNode:palmTree];

	AAPLSkinnedCharacter *monkey = (AAPLSkinnedCharacter *)[palmTree childNodeWithName:@"monkey" recursively:YES];
	if (monkey != nil) {
		[self.monkeys addObject:monkey];
	}
}

/*! Load the palm tree that the monkey is attached to.
 */
- (SCNNode *)createMonkeyPalmTree
{
	static SCNNode *s_palmTreeProtoObject = nil;

	if (s_palmTreeProtoObject == nil) {
		NSString *palmTreeDae = [AAPLGameSimulation pathForArtResource:@"characters/monkey/monkey_palm_tree.dae"];
		s_palmTreeProtoObject = [AAPLGameSimulation loadNodeWithName:@"PalmTree"
													 fromSceneNamed:palmTreeDae];
	}

	SCNNode *monkeyNode = [AAPLGameSimulation loadNodeWithName:nil fromSceneNamed:@"art.scnassets/characters/monkey/monkey_skinned.dae"];

	AAPLMonkeyCharacter *monkey = [[AAPLMonkeyCharacter alloc] initWithNode:monkeyNode];
	[monkey createAnimations];

	SCNNode *palmTree = [s_palmTreeProtoObject clone];
	[palmTree addChildNode:monkey];

	return palmTree;
}

- (void)animateDynamicNodes
{

	NSMutableArray *dynamicNodesWithVertColorAnimation = [NSMutableArray array];

	[self.rootNode enumerateChildNodesUsingBlock:^(SCNNode *child, BOOL *stop) {
		NSRange range = [child.parentNode.name rangeOfString:@"vine"];
		if ([child.geometry geometrySourcesForSemantic:SCNGeometrySourceSemanticColor] == nil) {
		} else if (range.location != NSNotFound) {
			[dynamicNodesWithVertColorAnimation addObject:child];
		}
	}];

	//-- Animate our dynamic node.
	NSString *shaderCode =
	@"uniform float timeOffset;\n"
	@"#pragma body\n"
	@"float speed = 20.05;\n"
	@"_geometry.position.xyz += (speed * sin(u_time + timeOffset) * _geometry.color.rgb);\n"
	;

	for (SCNNode *dynamicNode in dynamicNodesWithVertColorAnimation) {
		dynamicNode.geometry.shaderModifiers = @{ SCNShaderModifierEntryPointGeometry : shaderCode};
		CABasicAnimation *explodeAnimation = [CABasicAnimation animationWithKeyPath:@"timeOffset"];
		explodeAnimation.duration = 2.0;
		explodeAnimation.repeatCount = FLT_MAX;
		explodeAnimation.autoreverses = YES;
		explodeAnimation.toValue = @(AAPLRandomPercent());
		explodeAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
		[dynamicNode.geometry addAnimation:explodeAnimation forKey:@"sway"];
	}
}

/*! Reset the game simulation for the start of the game or restart after you have completed the level.
 */
- (void)resetLevel
{
	_score = 0;
	_secondsRemaining = 120;
	_coinsCollected = 0;
	_bananasCollected = 0;

	self.timeAlongPath = 0;
	self.playerCharacter.position = [self locationAlongPath:self.timeAlongPath];
	self.playerCharacter.rotation = [self getPlayerDirectionFromCurrentPosition];
	self.hitByLavaReset = NO;

	// Remove dynamic objects from the level.
	[SCNTransaction begin];

	for (SCNNode *b in self.coconuts) {
		[b removeFromParentNode];
	}

	for (SCNNode *b in self.bananas) {
		[b removeFromParentNode];
	}

	for (SCNNode *largeBanana in self.largeBananas) {
		[largeBanana removeFromParentNode];
	}
	[SCNTransaction commit];

	// Add dynamic objects to the level, like bananas and large bananas
	self.bananas = [[NSMutableSet alloc] init];
	self.coconuts = [[NSMutableArray alloc] init];

	for (int i = 0; i < 10; i++) {
		SCNNode *banana = [self createBanana];
		[self.rootNode addChildNode:banana];
		SCNVector3 location = [self locationAlongPath:(i + 1) / 20.0 - 0.01];
		location.y += 50;
		banana.position = location;

		[self.bananas addObject:banana];
	}

	self.largeBananas = [[NSMutableSet alloc] init];

	for (int i = 0; i < 6; i++) {
		SCNNode *largeBanana = [self createLargeBanana];
		[self.rootNode addChildNode:largeBanana];
		SCNVector3 location = [self locationAlongPath: AAPLRandomPercent()];
		location.y += 50;
		largeBanana.position = location;
		[self.largeBananas addObject:largeBanana];
	}

	[[AAPLGameSimulation sim] playMusic:@"music.caf"];
	[[AAPLGameSimulation sim] playMusic:@"night.caf"];
}

/*! Change the game state to the postgame.
 */
- (void)doGameOver
{
	self.playerCharacter.inRunAnimation = NO;
	[[AAPLGameSimulation sim] setGameState:AAPLGameStatePostGame];
}

- (void)collideWithLava
{
	if (self.hitByLavaReset == YES)
		return;

	self.playerCharacter.inRunAnimation = NO;

	[[AAPLGameSimulation sim] playSound:@"ack.caf"];

	// Blink for a second
	SCNAction *blinkOffAction = [SCNAction fadeOutWithDuration:0.15f];
	SCNAction *blinkOnAction = [SCNAction fadeInWithDuration:0.15f];
	SCNAction *cycle = [SCNAction sequence:@[blinkOffAction, blinkOnAction]];
	SCNAction *repeatCycle = [SCNAction repeatAction:cycle count:7];

	self.hitByLavaReset = YES;

	[self.playerCharacter runAction:repeatCycle completionHandler:^{
		self.timeAlongPath = 0;
		self.playerCharacter.position = [self locationAlongPath:self.timeAlongPath];
		self.playerCharacter.rotation = [self getPlayerDirectionFromCurrentPosition];
		self.hitByLavaReset = NO;
	}];
}

- (void)moveCharacterAlongPathWith:(NSTimeInterval)deltaTime currentState:(AAPLGameState)currentState
{
	if (self.playerCharacter.isRunning == YES) {
		if (currentState == AAPLGameStateInGame) {
			CGFloat walkSpeed = self.playerCharacter.walkSpeed;
			if (self.playerCharacter.isJumping == YES) {
				walkSpeed += self.playerCharacter.jumpBoost;
			}

			self.timeAlongPath += (deltaTime * walkSpeed * (self.playerCharacter.walkDirection == WalkDirectionRight ? 1 : -1));

			// limit how far the player can go in left and right directions.
			if (self.timeAlongPath < 0.0f) {
				self.timeAlongPath = 0.0f;
			} else if (self.timeAlongPath > 1.0f) {
				self.timeAlongPath = 1.0f;
			}

			SCNVector3 newPosition = [self locationAlongPath:self.timeAlongPath];
			self.playerCharacter.position = SCNVector3Make(newPosition.x, self.playerCharacter.position.y, newPosition.z);
			if (self.timeAlongPath >= 1.0) {
				[self doGameOver];
			}
		} else {
			self.playerCharacter.inRunAnimation = NO;
		}
	}
}

- (void)updateSunLightPosition
{
	SCNVector3 lightPos = _lightOffsetFromCharacter;
	SCNVector3 charPos = self.playerCharacter.position;
	lightPos.x += charPos.x;
	lightPos.y += charPos.y;
	lightPos.z += charPos.z;
	self.sunLight.position = lightPos;
}

/*! Main game logic
 */
- (void)update:(NSTimeInterval)deltaTime withRenderer:(id <SCNSceneRenderer>)aRenderer {

	// Based on gamestate:
	// ingame: Move the character if running.
	// ingame: prevent movement of the character past our level bounds.
	// ingame: perform logic for the player character.
	// any: move the directional light with any player movement.
	// ingame: update the coconuts kinematically.
	// ingame: perform logic for each monkey.
	// ingame: because our camera could have moved, update the transforms needs to fly
	//         collected bananas from the player (world space) to score (screen space)
	//

	AAPLAppDelegate *appDelegate = [AAPLAppDelegate sharedAppDelegate];
	AAPLGameState currentState = [[AAPLGameSimulation sim] gameState];

	// Move character along path if walking.
	[self moveCharacterAlongPathWith:deltaTime currentState:currentState];

	// Based on the time along path, rotation the character to face the correct direction.
	self.playerCharacter.rotation = [self getPlayerDirectionFromCurrentPosition];
	if (currentState == AAPLGameStateInGame) {
		[self.playerCharacter update:deltaTime];
	}

	// Move the light
	[self updateSunLightPosition];

	if (currentState == AAPLGameStatePreGame ||
		currentState == AAPLGameStatePostGame ||
		currentState == AAPLGameStatePaused)
		return;

	for (AAPLSkinnedCharacter *monkey in self.monkeys) {
		[monkey update:deltaTime];
	}

	// Update timer and check for Game Over.
	_secondsRemaining -= deltaTime;
	if (_secondsRemaining < 0.0) {
		[self doGameOver];
	}

	// update the player's SP position.
	SCNVector3 playerPosition = AAPLMatrix4GetPosition(self.playerCharacter.worldTransform);
	_screenSpaceplayerPosition = [appDelegate.scnView projectPoint:playerPosition];

	// Update the SP position of the score label
	CGPoint pt = self.scoreLabelLocation;
#if TARGET_OS_IPHONE
    // Unflip coordinate system on iOS.
    pt.y = appDelegate.scnView.frame.size.height - pt.y;
#endif
	_worldSpaceLabelScorePosition = [appDelegate.scnView unprojectPoint:SCNVector3Make(pt.x, pt.y, _screenSpaceplayerPosition.z)];
}

- (void)collectBanana:(SCNNode *)banana
{
	// Flyoff the banana to the screen space position score label.
	// Don't increment score until the banana hits the score label.

	// ignore collisions
	banana.physicsBody = nil;
	_bananasCollected++;

	NSInteger variance = 60;
	CGFloat apexY = ((_worldSpaceLabelScorePosition.y * 0.8f)) + ((rand() % variance) - (variance / 2));
	_worldSpaceLabelScorePosition.z = banana.position.z;
	SCNVector3 apex = SCNVector3Make(banana.position.x + 10 + ((rand() % variance) - (variance / 2)), apexY, banana.position.z);

	SCNAction *startFlyOff = [SCNAction moveTo:apex duration:0.25f];
	startFlyOff.timingMode = SCNActionTimingModeEaseOut;

	CGFloat duration = 0.25f;
	SCNAction *endFlyOff = [SCNAction customActionWithDuration:duration actionBlock:^(SCNNode *node, CGFloat elapsedTime) {

		CGFloat t = elapsedTime / duration;
		SCNVector3 v = {
			apex.x + ((_worldSpaceLabelScorePosition.x - apex.x) * t),
			apex.y + ((_worldSpaceLabelScorePosition.y - apex.y) * t),
			apex.z + ((_worldSpaceLabelScorePosition.z - apex.z) * t)};
		node.position = v;
	}];

	endFlyOff.timingMode = SCNActionTimingModeEaseInEaseOut;
	SCNAction *flyoffSequence = [SCNAction sequence:@[startFlyOff, endFlyOff]];

	[banana runAction:flyoffSequence completionHandler:^{
		[self.bananas removeObject:banana];
		[banana removeFromParentNode];
		// Add to score.
		_score++;
		[[AAPLGameSimulation sim] playSound:@"deposit.caf"];
		if (self.bananas.count == 0) {
			// Game Over
			[self doGameOver];
		}
	}];
}

- (void)collectLargeBanana:(SCNNode *)largeBanana
{
	// When the player hits a large banana, explode it into smaller bananas.
	// We explode into a predefined pattern: square, diamond, letterA, letterB

	// ignore collisions
	largeBanana.physicsBody = nil;
	_coinsCollected++;

	[self.largeBananas removeObject:largeBanana];
	[largeBanana removeAllParticleSystems];
	[largeBanana removeFromParentNode];

	// Add to score.
	_score+=100;
	NSArray *square = @[@1, @1, @1, @1, @1,
						@1, @1, @1, @1, @1,
						@1, @1, @1, @1, @1,
						@1, @1, @1, @1, @1,
						@1, @1, @1, @1, @1];
	NSArray *diamond = @[@0, @0, @1, @0, @0,
						 @0, @1, @1, @1, @0,
						 @1, @1, @1, @1, @1,
						 @0, @1, @1, @1, @0,
						 @0, @0, @1, @0, @0];
	NSArray *letterA = @[@1, @0, @0, @1, @0,
						 @1, @0, @0, @1, @0,
						 @1, @1, @1, @1, @0,
						 @1, @0, @0, @1, @0,
						 @0, @1, @1, @0, @0];

	NSArray *letterB = @[@1, @1, @0, @0, @0,
						 @1, @0, @1, @0, @0,
						 @1, @1, @0, @0, @0,
						 @1, @0, @1, @0, @0,
						 @1, @1, @0, @0, @0];
	NSArray *choices = @[square, diamond, letterA, letterB];

	CGFloat vertSpacing = 40;
	CGFloat spacing = 0.0075;
	NSArray *choice = choices[rand() % choices.count];
	for (int y = 0; y < 5; y++) {
		for (int x = 0; x < 5; x++) {
			int place = [choice[(y * 5) + x] intValue];
			if (place != 1)
				continue;

			SCNNode *banana = [self createBanana];

			[self.rootNode addChildNode:banana];
			banana.position = largeBanana.position;
			banana.physicsBody.categoryBitMask = GameCollisionCategoryNoCollide;
			banana.physicsBody.collisionBitMask = GameCollisionCategoryGround;

			SCNVector3 endPoint = [self locationAlongPath:self.timeAlongPath + (spacing * (x + 1))];
			endPoint.y += (vertSpacing * (y + 1));

			SCNAction *flyoff = [SCNAction moveTo:endPoint duration:AAPLRandomPercent() * 0.25f];
			flyoff.timingMode = SCNActionTimingModeEaseInEaseOut;

			// Prevent collision until the banana gets to the final resting spot.
			[banana runAction:flyoff completionHandler:^{
				banana.physicsBody.categoryBitMask = GameCollisionCategoryBanana;
				banana.physicsBody.collisionBitMask = GameCollisionCategoryGround | GameCollisionCategoryPlayer;
				[[AAPLGameSimulation sim] playSound:@"deposit.caf"];
			}];
			[self.bananas addObject:banana];
		}
	}
}

- (void)collideWithCoconut:(SCNNode *)coconut point:(SCNVector3)contactPoint
{

	// No more collisions. Let it bounce away and fade out.
	coconut.physicsBody.collisionBitMask = 0;
	[coconut runAction:[SCNAction sequence:@[
											 [SCNAction waitForDuration:1.0],
											 [SCNAction fadeOutWithDuration:1.0],
											 [SCNAction removeFromParentNode],
											 ]]
	 completionHandler:^{
		 [self.coconuts removeObject:coconut];
	 }];

	// Decrement score
	NSUInteger amountToDrop = self.score / 10;
	if (amountToDrop < 1)
		amountToDrop = 1;
	if (amountToDrop > 10)
		amountToDrop = 10;
	if (amountToDrop > _score)
		amountToDrop = _score;
	_score -= amountToDrop;

	// Throw bananas
	CGFloat spacing = 40;
	for (int x = 0; x < amountToDrop; x++) {
		SCNNode *banana = [self createBanana];

		[self.rootNode addChildNode:banana];
		banana.position = contactPoint;
		banana.physicsBody.categoryBitMask = GameCollisionCategoryNoCollide;
		banana.physicsBody.collisionBitMask = GameCollisionCategoryGround;
		SCNVector3 endPoint = SCNVector3Make(0, 0, 0);
		endPoint.x -= (spacing * x) + spacing;

		SCNAction *flyoff = [SCNAction moveBy:endPoint duration:AAPLRandomPercent() * 0.750f];
		flyoff.timingMode = SCNActionTimingModeEaseInEaseOut;

		[banana runAction:flyoff completionHandler:^{
			banana.physicsBody.categoryBitMask = GameCollisionCategoryBanana;
			banana.physicsBody.collisionBitMask = GameCollisionCategoryGround | GameCollisionCategoryPlayer;
		}];
		[self.bananas addObject:banana];
	}

	[self.playerCharacter setInHitAnimation:YES];
}

@end
