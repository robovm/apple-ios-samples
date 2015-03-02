/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

*/

#import <GLKit/GLKit.h>
#import <SceneKit/SceneKit.h>
#import <SpriteKit/SpriteKit.h>


#import "AAPLGameViewController.h"

#define SLIDE_COUNT 10

#define TEXT_SCALE 0.75
#define TEXT_Z_SPACING 200

#define MAX_FIRE 25.0
#define MAX_SMOKE 20.0

// utility function
static CGFloat randFloat(CGFloat min, CGFloat max)
{
    return min + (max - min) * (CGFloat)rand() / RAND_MAX;
}

// SpriteKit overlays
@interface AAPLSpriteKitOverlayScene : SKScene

@property (readonly) SKNode *nextButton;
@property (readonly) SKNode *previousButton;
@property (readonly) SKNode *buttonGroup;

- (void)showLabel:(NSString *)label;

@end

@implementation AAPLGameViewController {
@private
    //steps of the demo
    NSUInteger _introductionStep;
    NSUInteger _step;
    
    //scene
    SCNScene *_scene;

    // save spot light transform
    SCNMatrix4 _originalSpotTransform;

    //references to nodes for manipulation
    SCNNode *_cameraHandle;
    SCNNode *_cameraOrientation;
    SCNNode *_cameraNode;
    SCNNode *_spotLightParentNode;
    SCNNode *_spotLightNode;
    SCNNode *_ambientLightNode;
    SCNNode *_floorNode;
    SCNNode *_sceneKitLogo;
    SCNNode *_mainWall;
    SCNNode *_invisibleWallForPhysicsSlide;
    
    //ship
    SCNNode *_shipNode;
    SCNNode *_shipPivot;
    SCNNode *_shipHandle;
    SCNNode *_introNodeGroup;
    
    //physics slide
    NSMutableArray *_boxes;
    
    //particles slide
    SCNNode *_fireTruck;
    SCNNode *_collider;
    SCNNode *_emitter;
    SCNNode *_fireContainer;
    SCNNode *_handle;
    SCNParticleSystem *_fire;
    SCNParticleSystem *_smoke;
    SCNParticleSystem *_plok;
    BOOL _hitFire;
    
    //physics fields slide
    SCNNode *_fieldEmitter;
    SCNNode *_fieldOwner;
    SCNNode *_interactiveField;
    
    //SpriteKit integration slide
    SCNNode *_torus;
    SCNNode *_splashNode;
    
    //shaders slide
    SCNNode *_shaderGroupNode;
    SCNNode *_shadedNode;
    int      _shaderStage;
    
    // shader modifiers
    NSString *_geomModifier;
    NSString *_surfModifier;
    NSString *_fragModifier;
    NSString *_lightModifier;
    
    //camera manipulation
    SCNVector3 _cameraBaseOrientation;
    CGPoint    _initialOffset, _lastOffset;
    SCNMatrix4 _cameraHandleTransforms[SLIDE_COUNT];
    SCNMatrix4 _cameraOrientationTransforms[SLIDE_COUNT];
    dispatch_source_t _timer;

    
    BOOL _preventNext;
}

#if TARGET_OS_IPHONE
- (void)viewDidAppear:(BOOL)animated
{
    [self setup];
    [super viewDidLoad];
}
#else
- (void)awakeFromNib
{
    [self setup];
}
#endif

#pragma mark - Setup

- (void)setup
{
    SCNView *sceneView = (SCNView *)self.view;
    
    //redraw forever
    sceneView.playing = YES;
    sceneView.loops = YES;
    sceneView.showsStatistics = YES;

    sceneView.backgroundColor = [SKColor blackColor];
    
    //setup ivars
    _boxes = [NSMutableArray array];
    
    //setup the scene
    [self setupScene];
    
    //present it
    sceneView.scene = _scene;
    
    //tweak physics
    sceneView.scene.physicsWorld.speed = 2.0;
    
    //let's be the delegate of the SCNView
    sceneView.delegate = self;
    
    //initial point of view
    sceneView.pointOfView = _cameraNode;
    
    //setup overlays
    AAPLSpriteKitOverlayScene *overlay = [[AAPLSpriteKitOverlayScene alloc] initWithSize:sceneView.bounds.size];
    sceneView.overlaySKScene = overlay;
    
#if TARGET_OS_IPHONE
    NSMutableArray *gestureRecognizers = [NSMutableArray array];
    [gestureRecognizers addObjectsFromArray:sceneView.gestureRecognizers];
    
    // add a tap gesture recognizer
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    
    // add a pan gesture recognizer
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    
    // add a double tap gesture recognizer
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    
    [tapGesture requireGestureRecognizerToFail:panGesture];
    
    [gestureRecognizers addObject:doubleTapGesture];
    [gestureRecognizers addObject:tapGesture];
    [gestureRecognizers addObject:panGesture];
    
    //register gesture recognizers
    sceneView.gestureRecognizers = gestureRecognizers;
#endif
    
    if (!_introductionStep)
        [overlay showLabel:@"Go!"];
}

- (void)setupScene
{
    _scene = [SCNScene scene];
    
    [self setupEnvironment];
    [self setupSceneElements];
    [self setupIntroEnvironment];
}

- (void) setupEnvironment
{
    // |_   cameraHandle
    //   |_   cameraOrientation
    //     |_   cameraNode
    
    //create a main camera
    _cameraNode = [SCNNode node];
    _cameraNode.position = SCNVector3Make(0, 0, 120);
    
    //create a node to manipulate the camera orientation
    _cameraHandle = [SCNNode node];
    _cameraHandle.position = SCNVector3Make(0, 60, 0);
    
    _cameraOrientation = [SCNNode node];
   
    [_scene.rootNode addChildNode:_cameraHandle];
    [_cameraHandle addChildNode:_cameraOrientation];
    [_cameraOrientation addChildNode:_cameraNode];
    
    _cameraNode.camera = [SCNCamera camera];
    _cameraNode.camera.zFar = 800;
#if TARGET_OS_IPHONE
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        _cameraNode.camera.yFov = 55;
    }
    else
#endif    
    {
        _cameraNode.camera.xFov = 75;
    }

    _cameraHandleTransforms[0] = _cameraNode.transform;
    
    // add an ambient light
    _ambientLightNode = [SCNNode node];
    _ambientLightNode.light = [SCNLight light];
    
    _ambientLightNode.light.type = SCNLightTypeAmbient;
    _ambientLightNode.light.color = [SKColor colorWithWhite:0.3 alpha:1.0];
    
    [_scene.rootNode addChildNode:_ambientLightNode];
    
    
    //add a key light to the scene
    _spotLightParentNode = [SCNNode node];
    _spotLightParentNode.position = SCNVector3Make(0, 90, 20);
    
    _spotLightNode = [SCNNode node];
    _spotLightNode.rotation = SCNVector4Make(1,0,0,-M_PI_4);
    
    _spotLightNode.light = [SCNLight light];
    _spotLightNode.light.type = SCNLightTypeSpot;
    _spotLightNode.light.color = [SKColor colorWithWhite:1.0 alpha:1.0];
    _spotLightNode.light.castsShadow = YES;
    _spotLightNode.light.shadowColor = [SKColor colorWithWhite:0 alpha:0.5];
    _spotLightNode.light.zNear = 30;
    _spotLightNode.light.zFar = 800;
    _spotLightNode.light.shadowRadius = 1.0;
    _spotLightNode.light.spotInnerAngle = 15;
    _spotLightNode.light.spotOuterAngle = 70;
    
    [_cameraNode addChildNode:_spotLightParentNode];
    [_spotLightParentNode addChildNode:_spotLightNode];
    
    //save spotlight transform
    _originalSpotTransform = _spotLightNode.transform;

    //floor
    SCNFloor *floor = [SCNFloor floor];
    floor.reflectionFalloffEnd = 0;
    floor.reflectivity = 0;
    
    _floorNode = [SCNNode node];
    _floorNode.geometry = floor;
    _floorNode.geometry.firstMaterial.diffuse.contents = @"wood.png";
    _floorNode.geometry.firstMaterial.locksAmbientWithDiffuse = YES;
    _floorNode.geometry.firstMaterial.diffuse.wrapS = SCNWrapModeRepeat;
    _floorNode.geometry.firstMaterial.diffuse.wrapT = SCNWrapModeRepeat;
    _floorNode.geometry.firstMaterial.diffuse.mipFilter = SCNFilterModeNearest;
    _floorNode.geometry.firstMaterial.doubleSided = NO;
    
    _floorNode.physicsBody = [SCNPhysicsBody staticBody];
    _floorNode.physicsBody.restitution = 1.0;
    
    [_scene.rootNode addChildNode:_floorNode];
}

- (void)setupSceneElements
{
    // create the wall geometry
    SCNPlane *wallGeometry = [SCNPlane planeWithWidth:800 height:200];
    wallGeometry.firstMaterial.diffuse.contents = @"wallPaper.png";
    wallGeometry.firstMaterial.diffuse.contentsTransform = SCNMatrix4Mult(SCNMatrix4MakeScale(8, 2, 1), SCNMatrix4MakeRotation(M_PI_4, 0, 0, 1));
    wallGeometry.firstMaterial.diffuse.wrapS = SCNWrapModeRepeat;
    wallGeometry.firstMaterial.diffuse.wrapT = SCNWrapModeRepeat;
    wallGeometry.firstMaterial.doubleSided = NO;
    wallGeometry.firstMaterial.locksAmbientWithDiffuse = YES;
    
    SCNNode *wallWithBaseboardNode = [SCNNode nodeWithGeometry:wallGeometry];
    wallWithBaseboardNode.position = SCNVector3Make(200, 100, -20);
    wallWithBaseboardNode.physicsBody = [SCNPhysicsBody staticBody];
    wallWithBaseboardNode.physicsBody.restitution = 1.0;
    wallWithBaseboardNode.castsShadow = NO;
    
    SCNNode *baseboardNode = [SCNNode nodeWithGeometry:[SCNBox boxWithWidth:800 height:8 length:0.5 chamferRadius:0]];
    baseboardNode.geometry.firstMaterial.diffuse.contents = @"baseboard.jpg";
    baseboardNode.geometry.firstMaterial.diffuse.wrapS = SCNWrapModeRepeat;
    baseboardNode.geometry.firstMaterial.doubleSided = NO;
    baseboardNode.geometry.firstMaterial.locksAmbientWithDiffuse = YES;
    baseboardNode.position = SCNVector3Make(0, -wallWithBaseboardNode.position.y + 4, 0.5);
    baseboardNode.castsShadow = NO;
    baseboardNode.renderingOrder = -3; //render before others

    [wallWithBaseboardNode addChildNode:baseboardNode];
    
    //front walls
    _mainWall = wallWithBaseboardNode;
    [_scene.rootNode addChildNode:wallWithBaseboardNode];
    _mainWall.renderingOrder = -3; //render before others

    //back
    SCNNode *wallNode = [wallWithBaseboardNode clone];
    wallNode.opacity = 0;
    wallNode.physicsBody = [SCNPhysicsBody staticBody];
    wallNode.physicsBody.restitution = 1.0;
    wallNode.physicsBody.categoryBitMask = 1 << 2;
    wallNode.castsShadow = NO;
    
    wallNode.position = SCNVector3Make(0, 100, 40);
    wallNode.rotation = SCNVector4Make(0, 1, 0, M_PI);
    [_scene.rootNode addChildNode:wallNode];
    
    //left
    wallNode = [wallWithBaseboardNode clone];
    wallNode.position = SCNVector3Make(-120, 100, 40);
    wallNode.rotation = SCNVector4Make(0, 1, 0, M_PI_2);
    [_scene.rootNode addChildNode:wallNode];
    
    
    //right (an invisible wall to keep the bodies in the visible area when zooming in the Physics slide)
    wallNode = [wallNode clone];
    wallNode.opacity = 0;
    wallNode.position = SCNVector3Make(120, 100, 40);
    wallNode.rotation = SCNVector4Make(0, 1, 0, -M_PI_2);
    _invisibleWallForPhysicsSlide = wallNode;
    
    //right (the actual wall on the right)
    wallNode = [wallWithBaseboardNode clone];
    wallNode.physicsBody = nil;
    wallNode.position = SCNVector3Make(600, 100, 40);
    wallNode.rotation = SCNVector4Make(0, 1, 0, -M_PI_2);
    [_scene.rootNode addChildNode:wallNode];
    
    //top
    wallNode = [wallWithBaseboardNode copy];
    wallNode.geometry = [wallNode.geometry copy];
    wallNode.geometry.firstMaterial = [SCNMaterial material];
    wallNode.opacity = 1;
    wallNode.position = SCNVector3Make(200, 200, 0);
    wallNode.scale = SCNVector3Make(1, 10, 1);
    wallNode.rotation = SCNVector4Make(1, 0, 0, M_PI_2);
    [_scene.rootNode addChildNode:wallNode];
    
    _mainWall.hidden = YES; //hide at first (save some milliseconds)
}

- (void)setupIntroEnvironment
{
    _introductionStep = 1;
    
    // configure the lighting for the introduction (dark lighting)
    _ambientLightNode.light.color = [SKColor blackColor];
    _spotLightNode.light.color = [SKColor blackColor];
    _spotLightNode.position = SCNVector3Make(50, 90, -50);
    _spotLightNode.eulerAngles = SCNVector3Make(-M_PI_2*0.75, M_PI_4*0.5, 0);
    
    //put all texts under this node to remove all at once later
    _introNodeGroup = [SCNNode node];
    
    //Slide 1
#define LOGO_SIZE 70
#define TITLE_SIZE (TEXT_SCALE*0.45)
    SCNNode *sceneKitLogo = [SCNNode nodeWithGeometry:[SCNPlane planeWithWidth:LOGO_SIZE height:LOGO_SIZE]];
    sceneKitLogo.geometry.firstMaterial.doubleSided = YES;
    sceneKitLogo.geometry.firstMaterial.diffuse.contents = @"SceneKit.png";
    sceneKitLogo.geometry.firstMaterial.emission.contents = @"SceneKit.png";
    _sceneKitLogo = sceneKitLogo;
    
    _sceneKitLogo.renderingOrder = -1;
    _floorNode.renderingOrder = -2;

    [_introNodeGroup addChildNode:sceneKitLogo];
    sceneKitLogo.position = SCNVector3Make(200, LOGO_SIZE/2, 200);

    SCNVector3 position = SCNVector3Make(200, 0, 200);
    
    _cameraNode.position = SCNVector3Make(200, -20, position.z+150);
    _cameraNode.eulerAngles = SCNVector3Make(-M_PI_2*0.06, 0, 0);
    
    /* hierarchy
     shipHandle
     |_ shipXTranslate
     |_ shipPivot
     |_ ship */
    SCNScene *modelScene = [SCNScene sceneNamed:@"ship.dae" inDirectory:@"assets.scnassets/models" options:nil];
    _shipNode = [modelScene.rootNode childNodeWithName:@"Aircraft" recursively:YES];

    SCNNode*shipMesh = _shipNode.childNodes[0];
    // shipMesh.geometry.firstMaterial.fresnelExponent = 1.0;
    shipMesh.geometry.firstMaterial.emission.intensity = 0.5;
    shipMesh.renderingOrder = -3;
    
    _shipPivot = [SCNNode node];
    SCNNode *shipXTranslate = [SCNNode node];
    _shipHandle = [SCNNode node];
    
    _shipHandle.position =  SCNVector3Make(200 - 500, 0, position.z + 30);
    _shipNode.position = SCNVector3Make(50, 30, 0);
    
    [_shipPivot addChildNode:_shipNode];
    [shipXTranslate addChildNode:_shipPivot];
    [_shipHandle addChildNode:shipXTranslate];
    [_introNodeGroup addChildNode:_shipHandle];
    
    //animate ship
    [_shipNode removeAllActions];
    _shipNode.rotation = SCNVector4Make(0, 0, 1, M_PI_4*0.5);
    
    //make spotlight relative to the ship
    SCNVector3 newPosition = SCNVector3Make(50, 100, 0);
    SCNMatrix4 oldTransform = [_shipPivot convertTransform:SCNMatrix4Identity fromNode:_spotLightNode];
    
    [_spotLightNode removeFromParentNode];
    _spotLightNode.transform = oldTransform;
    [_shipPivot addChildNode:_spotLightNode];

    _spotLightNode.position = newPosition; // will animate implicitly
    _spotLightNode.eulerAngles = SCNVector3Make(-M_PI_2, 0, 0);
    _spotLightNode.light.spotOuterAngle = 120;
    
    _shipPivot.eulerAngles = SCNVector3Make(0, M_PI_2, 0);
    SCNAction *action = [SCNAction sequence:@[[SCNAction repeatActionForever:[SCNAction rotateByX:0 y:M_PI z:0 duration:2]]]];
    [_shipPivot runAction:action];

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position.x"];
    animation.fromValue = @(-50);
    animation.toValue =  @(+50);
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.autoreverses = YES;
    animation.duration = 2;
    animation.repeatCount = MAXFLOAT;
    animation.timeOffset = -animation.duration*0.5;
    [shipXTranslate addAnimation:animation forKey:nil];

    SCNNode *emitter = [_shipNode childNodeWithName:@"emitter" recursively:YES];
    SCNParticleSystem *ps = [SCNParticleSystem particleSystemNamed:@"reactor.scnp" inDirectory:@"assets.scnassets/particles"];
    [emitter addParticleSystem:ps];
    _shipHandle.position = SCNVector3Make(_shipHandle.position.x, _shipHandle.position.y, _shipHandle.position.z-50);

    [_scene.rootNode addChildNode:_introNodeGroup];
    
    //wait, then fade in light
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:1.0];
    [SCNTransaction setCompletionBlock:^{
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:2.5];
        
        _shipHandle.position = SCNVector3Make(_shipHandle.position.x+500, _shipHandle.position.y, _shipHandle.position.z);
        
        _spotLightNode.light.color = [SKColor colorWithWhite:1 alpha:1];
        sceneKitLogo.geometry.firstMaterial.emission.intensity = 0.80;

        [SCNTransaction commit];
    }];
    
    _spotLightNode.light.color = [SKColor colorWithWhite:0.001 alpha:1];
    
    [SCNTransaction commit];
}

#pragma mark -

// the material to use for text
- (SCNMaterial *)textMaterial {
    static SCNMaterial *material = nil;
    if (!material) {
        material = [SCNMaterial material];
        material.specular.contents   = [SKColor colorWithWhite:0.6 alpha:1];
        material.reflective.contents = @"color_envmap.png";
        material.shininess           = 0.1;
    }
    return material;
}

// switch to the next introduction step
- (void) nextIntroductionStep
{
    _introductionStep++;
    
    //show wall
    _mainWall.hidden = NO;
    
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:1.0];
    [SCNTransaction setCompletionBlock:^{
        
        if (_introductionStep == 0) {
            //We did finish introduction step

            [_shipHandle removeFromParentNode];
            _shipHandle = nil;
            _shipPivot = nil;
            _shipNode = nil;
            
            _floorNode.renderingOrder = 0;

            //We did finish the whole introduction
            [_introNodeGroup removeFromParentNode];
            _introNodeGroup = nil;
            [self next];
        }
    }];
    
    if (_introductionStep == 2) {
        _sceneKitLogo.renderingOrder = 0;

        //restore spot light config
        _spotLightNode.light.spotOuterAngle = 70;
        SCNMatrix4 oldTransform = [_spotLightParentNode convertTransform:SCNMatrix4Identity fromNode:_spotLightNode];
        [_spotLightNode removeFromParentNode];
        _spotLightNode.transform = oldTransform;
        
        [_spotLightParentNode addChildNode:_spotLightNode];
        
        _cameraNode.position = SCNVector3Make(_cameraNode.position.x, _cameraNode.position.y, _cameraNode.position.z-TEXT_Z_SPACING);

        _spotLightNode.transform = _originalSpotTransform;
        _ambientLightNode.light.color = [SKColor colorWithWhite:0.3 alpha:1.0];
        _cameraNode.position = SCNVector3Make(0, 0, 120);
        _cameraNode.eulerAngles = SCNVector3Make(0, 0, 0);

        _introductionStep = 0;//introduction is over
    }
    else {
        _cameraNode.position = SCNVector3Make(_cameraNode.position.x, _cameraNode.position.y, _cameraNode.position.z-TEXT_Z_SPACING);
    }
    
    [SCNTransaction commit];
}

//restore the default camera orientation and position
- (void)restoreCameraAngle
{
    //reset drag offset
    _initialOffset = CGPointMake(0, 0);
    _lastOffset = _initialOffset;
    
    //restore default camera
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:0.5];
    [SCNTransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    _cameraHandle.eulerAngles = SCNVector3Make(0, 0, 0);
    [SCNTransaction commit];
}

// tilt the camera based on an offset
- (void)tiltCameraWithOffset:(CGPoint) offset
{
    if (_introductionStep != 0)
        return;
    
    offset.x += _initialOffset.x;
    offset.y += _initialOffset.y;
    
    CGPoint tr;
    tr.x = offset.x - _lastOffset.x;
    tr.y = offset.y - _lastOffset.y;
    
    _lastOffset = offset;
    
    offset.x *= 0.1;
    offset.y *= 0.1;
    float rx = offset.y; //offset.y > 0 ? log(1 + offset.y * offset.y) : -log(1 + offset.y * offset.y);
    float ry = offset.x; //offset.x > 0 ? log(1 + offset.x * offset.x) : -log(1 + offset.x * offset.x);

    ry *= 0.05;
    rx *= 0.05;
    
#if TARGET_OS_IPHONE
    rx = -rx; //on iOS, invert rotation on the X axis
#endif
    
    if (rx > 0.5) {
        rx = 0.5;
        _initialOffset.y -=tr.y;
        _lastOffset.y -= tr.y;
    }
    if (rx < -M_PI_2) {
        rx = -M_PI_2;
        _initialOffset.y -=tr.y;
        _lastOffset.y -= tr.y;
    }
    
#define MAX_RY (M_PI_4*1.5)
    if (ry > MAX_RY) {
        ry = MAX_RY;
        _initialOffset.x -=tr.x;
        _lastOffset.x -= tr.x;
    }
    if (ry < -MAX_RY) {
        ry = -MAX_RY;
        _initialOffset.x -=tr.x;
        _lastOffset.x -= tr.x;

    }

    ry = -ry;

    _cameraHandle.eulerAngles = SCNVector3Make(rx, ry, 0);
}

#pragma mark -
#pragma mark UIKit configuration

#if TARGET_OS_IPHONE
- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}
#endif

#pragma mark -
#pragma mark Physics

#define BOX_W 8

// return a new physically based box at the specified position
// sometimes generate a ball instead of a box for more variety
- (SCNNode *) boxAtPosition:(SCNVector3) position
{
    static NSMutableArray *boxes;
    static int count = 0;
    
    if (boxes == NULL) {
        boxes = [NSMutableArray arrayWithCapacity:4];
        
        SCNNode *box = [SCNNode node];
        box.geometry = [SCNBox boxWithWidth:BOX_W height:BOX_W length:BOX_W chamferRadius:0.1];
        box.geometry.firstMaterial.diffuse.contents = @"WoodCubeA.jpg";
        box.geometry.firstMaterial.diffuse.mipFilter = SCNFilterModeLinear;
        box.physicsBody = [SCNPhysicsBody dynamicBody];
        
        [boxes addObject:box];
        
        box = box.clone;
        box.geometry = box.geometry.copy;
        box.geometry.firstMaterial = [box.geometry.firstMaterial copy];
        box.geometry.firstMaterial.diffuse.contents = @"WoodCubeB.jpg";
        [boxes addObject:box];
        
        box = box.clone;
        box.geometry = box.geometry.copy;
        box.geometry.firstMaterial = [box.geometry.firstMaterial copy];
        box.geometry.firstMaterial.diffuse.contents = @"WoodCubeC.jpg";
        [boxes addObject:box];
        
        SCNNode *ball = [SCNNode node];
        SCNSphere *sphere = [SCNSphere sphereWithRadius:BOX_W * 0.75];
        ball.geometry = sphere;
        ball.geometry.firstMaterial.diffuse.wrapS = SCNWrapModeRepeat;
        ball.geometry.firstMaterial.diffuse.contents = @"ball.jpg";
        ball.geometry.firstMaterial.reflective.contents = @"envmap.jpg";
        ball.geometry.firstMaterial.fresnelExponent = 1.0;
        ball.physicsBody = [SCNPhysicsBody dynamicBody];
        ball.physicsBody.restitution = 0.9;
        [boxes addObject:ball];
    }
    
    count++;
    
    int index = count % 3;
    if (count == 1 || (count&7) == 7)
        index = 3;
    
    SCNNode *item = [boxes[index] clone];
    item.position = position;
    
    return item;
}

#define FACTOR 2.2

//apply an explosion force at the specified location to the specified nodes
//remove from the nodes from the scene graph is removeOnCompletion is set to yes
- (void) explosionAt:(SCNVector3) center receivers:(NSArray *)nodes removeOnCompletion:(BOOL) removeOnCompletion
{
    GLKVector3 c = SCNVector3ToGLKVector3(center);
    
    for(SCNNode *node in nodes) {
        GLKVector3 p = SCNVector3ToGLKVector3(node.presentationNode.position);
        
        c.y = removeOnCompletion ? -20 : -90;
        c.z = removeOnCompletion ? 0 : 50;
        GLKVector3 direction = GLKVector3Subtract(p, c);
        
        c.y = 0;
        c.z = 0;
        GLKVector3 dist = GLKVector3Subtract(p, c);
        
        float force = removeOnCompletion ? 2000 : 1000 * (1.0 + fabs(c.x) / 100.0);
        float distance = GLKVector3Length(dist);
        
        if (removeOnCompletion) {
            if (direction.x < 500.0 && direction.x > 0) direction.x += 500;
            if (direction.x > -500.0 && direction.x < 0) direction.x -= 500;
            node.physicsBody.collisionBitMask = 0x0;
        }
        
        //normalise
        direction = GLKVector3Normalize(direction);
        direction = GLKVector3MultiplyScalar(direction, FACTOR * force / MAX(20.0, distance));
        
        [node.physicsBody applyForce:SCNVector3FromGLKVector3(direction) atPosition:removeOnCompletion ? SCNVector3Zero : SCNVector3Make(randFloat(-0.2, 0.2), randFloat(-0.2, 0.2), randFloat(-0.2, 0.2)) impulse:YES];
        
        if (removeOnCompletion) {
            [node runAction:[SCNAction sequence:@[[SCNAction waitForDuration:1.0],[SCNAction fadeOutWithDuration:0.125], [SCNAction removeFromParentNode]]]];
        }
    }
}

// present physics slide
- (void) showPhysicsSlide
{
    NSUInteger count = 80;
    float spread = 6;
    
    SCNScene *scene =  ((SCNView*)self.view).scene;
    
    //tweak physics
    scene.physicsWorld.gravity = SCNVector3Make(0, -70, 0);
    
    //add invisible wall
    [scene.rootNode addChildNode:_invisibleWallForPhysicsSlide];
    
    // drop rigid bodies cubes
    uint64_t intervalTime = NSEC_PER_SEC * 10.0 / count;
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), intervalTime, 0); // every ms
    
    __block NSInteger remainingCount = count;
    __block BOOL right = NO;
    
    dispatch_source_set_event_handler(_timer, ^{
        
        if (_step > 1) {
            dispatch_source_cancel(_timer);
            return;
        }
        
        [SCNTransaction begin];
        
        SCNVector3 pos = SCNVector3Make(right ? 100 : -100, 50, 0);
        
        SCNNode *box = [self boxAtPosition:pos];
        
        //add to scene
        [_scene.rootNode addChildNode:box];
        
        
        [box.physicsBody setVelocity:SCNVector3Make(FACTOR * (right ? -50 : 50), FACTOR * (30+randFloat(-spread, spread)), FACTOR * (randFloat(-spread, spread)))];
        [box.physicsBody setAngularVelocity:SCNVector4Make(randFloat(-1, 1),randFloat(-1, 1),randFloat(-1, 1),randFloat(-3, 3))];
        [SCNTransaction commit];
        
        [_boxes addObject:box];
        
        // ensure we stop firing
        if (--remainingCount < 0)
            dispatch_source_cancel(_timer);
        
        right = 1-right;
    });
    
    dispatch_resume(_timer);
}

//remove physics slide
- (void)orderOutPhysics
{
    //move physics out
    [self explosionAt:SCNVector3Make(0, 0, 0) receivers:_boxes removeOnCompletion:YES];
    [_boxes removeAllObjects];
    
    //add invisible wall
    SCNScene *scene = ((SCNView*)self.view).scene;
    [scene.rootNode addChildNode:_invisibleWallForPhysicsSlide];
}

#pragma mark - Particles

//present particle slide
- (void)showParticlesSlide
{
    //restore defaults
    ((SCNView*)self.view).scene.physicsWorld.gravity = SCNVector3Make(0, -9.8, 0);
    
    //add truck
    SCNScene *fireTruckScene = [SCNScene sceneNamed:@"firetruck.dae" inDirectory:@"assets.scnassets/models/" options:nil];
    SCNNode *fireTruck = [fireTruckScene.rootNode childNodeWithName:@"firetruck" recursively:YES];
    SCNNode *emitter = [fireTruck childNodeWithName:@"emitter" recursively:YES];
    _handle = [fireTruck childNodeWithName:@"handle" recursively:YES];
    
    fireTruck.position = SCNVector3Make(120, 10, 0);
    fireTruck.scale = SCNVector3Make(0.2, 0.2, 0.2);
    fireTruck.rotation = SCNVector4Make(0, 1, 0, M_PI_2);
    
    [_scene.rootNode addChildNode:fireTruck];
    
    //add fire container
    SCNScene *fireContainerScene = [SCNScene sceneNamed:@"bac.dae" inDirectory:@"assets.scnassets/models/" options:nil];
    _fireContainer = [fireContainerScene.rootNode childNodeWithName:@"box" recursively:YES];
    _fireContainer.scale = SCNVector3Make(0.5, 0.25, 0.25);
    [_scene.rootNode addChildNode:_fireContainer];
    
    //preload it to avoid frame drop
    [(SCNView*)self.view prepareObject:_scene shouldAbortBlock:nil];
    
    _fireTruck = fireTruck;
    
    //collider
    SCNNode *colliderNode = [SCNNode node];
    colliderNode.geometry = [SCNBox boxWithWidth:50 height:2 length:25 chamferRadius:0];
    colliderNode.geometry.firstMaterial.diffuse.contents = @"assets.scnassets/textures/train_wood.jpg";
    colliderNode.position = SCNVector3Make(60, 260, 5);
    [_scene.rootNode addChildNode:colliderNode];
    
    SCNAction *moveIn = [SCNAction moveByX:0 y:-215 z:0 duration:1.0];
    moveIn.timingMode = SCNActionTimingModeEaseOut;
    [colliderNode runAction:[SCNAction sequence:@[[SCNAction waitForDuration:2],moveIn]]];
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"eulerAngles"];
    animation.fromValue = [NSValue valueWithSCNVector3:SCNVector3Make(0, 0, 0)];
    animation.toValue = [NSValue valueWithSCNVector3:SCNVector3Make(0, 0, 2*M_PI)];
    animation.beginTime = CACurrentMediaTime() + 0.5;
    animation.duration = 2;
    animation.repeatCount = MAXFLOAT;
    [colliderNode addAnimation:animation forKey:nil];
    _collider = colliderNode;
    
    SCNParticleSystem *ps;
    
    //add fire
    SCNNode *fireHolder = [SCNNode node];
    _emitter = fireHolder;
    fireHolder.position = SCNVector3Make(0,0,0);
    ps = [SCNParticleSystem particleSystemNamed:@"fire.scnp" inDirectory:@"assets.scnassets/particles/"];
    _smoke = [SCNParticleSystem particleSystemNamed:@"smoke.scnp" inDirectory:@"assets.scnassets/particles/"];
    _smoke.birthRate = 0;
    [fireHolder addParticleSystem:ps];
    
    SCNNode *smokeEmitter = [SCNNode node];
    smokeEmitter.position = SCNVector3Make(0, 0, 0.5);
    [smokeEmitter addParticleSystem:_smoke];
    [fireHolder addChildNode:smokeEmitter];
    [_scene.rootNode addChildNode:fireHolder];
    
    _fire = ps;
    
    //add water
    ps = [SCNParticleSystem particleSystemNamed:@"sparks.scnp" inDirectory:@"assets.scnassets/particles/"];
    ps.birthRate = 0;
    ps.speedFactor = 3.0;
    ps.colliderNodes = @[_floorNode, colliderNode];
    [emitter addParticleSystem:ps];
    
    SCNAction *tr = [SCNAction moveBy:SCNVector3Make(60, 0, 0) duration:1];
    tr.timingMode = SCNActionTimingModeEaseInEaseOut;
    
    [_cameraHandle runAction:[SCNAction sequence:@[[SCNAction waitForDuration:2],tr,[SCNAction runBlock:^(SCNNode *node){
        ps.birthRate = 300;
    }]]]];
}

//remove particle slide
- (void)orderOutParticles
{
    //remove fire truck
    [_fireTruck removeFromParentNode];
    [_emitter removeFromParentNode];
    [_collider removeFromParentNode];
    [_fireContainer removeFromParentNode];
    _fireContainer = nil;
    _collider = nil;
    _emitter = nil;
    _fireTruck = nil;
}

#pragma mark -
#pragma mark PhysicsFields

- (void) moveEmitterTo:(CGPoint) p
{
    SCNView *scnView = (SCNView *) self.view;
    SCNVector3 pTmp = [scnView projectPoint:SCNVector3Make(0, 0, 50)];
    SCNVector3 p3d = [scnView unprojectPoint:SCNVector3Make(p.x, p.y, pTmp.z)];
    p3d.z = 50;
    p3d.y = MAX(p3d.y, 5);
    _fieldOwner.position = p3d;
    _fieldOwner.physicsField.strength = 200000.0;
}


//present physics field slide
- (void)showPhysicsFields
{
    CGFloat dz = 50;
    
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:0.75];
    _spotLightNode.light.color = [SKColor colorWithWhite:0.5 alpha:1.0];
    _ambientLightNode.light.color = [SKColor blackColor];
    [SCNTransaction commit];

    //remove gravity for this slide
    _scene.physicsWorld.gravity = SCNVector3Zero;
    
    //move camera
    SCNAction *tr = [SCNAction moveBy:SCNVector3Make(0, 0, dz) duration:1];
    tr.timingMode = SCNActionTimingModeEaseInEaseOut;
    [_cameraHandle runAction:tr];
    
    //add particles
    _fieldEmitter = [SCNNode node];
    _fieldEmitter.position = SCNVector3Make(_cameraHandle.position.x, 5, dz);
    
    SCNParticleSystem *ps = [SCNParticleSystem particleSystemNamed:@"bubbles.scnp" inDirectory:@"assets.scnassets/particles/"];
    
    ps.particleColor = [SKColor colorWithRed:0.8 green:0. blue:0. alpha:1.0];
    ps.particleColorVariation = SCNVector4Make(0.3, 0.2, 0.3, 0.);
    ps.sortingMode = SCNParticleSortingModeDistance;
    ps.blendMode = SCNParticleBlendModeAlpha;
    NSArray *cubeMap = @[@"right.jpg", @"left.jpg", @"top.jpg", @"bottom.jpg", @"front.jpg", @"back.jpg"];
    ps.particleImage = cubeMap;
    ps.fresnelExponent = 2;
    ps.colliderNodes = @[_floorNode, _mainWall];
    
    ps.emitterShape = [SCNBox boxWithWidth:200 height:0 length:100 chamferRadius:0];
    
    [_fieldEmitter addParticleSystem:ps];
    [_scene.rootNode addChildNode:_fieldEmitter];
    
    //field
    _fieldOwner = [SCNNode node];
    _fieldOwner.position = SCNVector3Make(_cameraHandle.position.x, 50, dz+5);
    
    SCNPhysicsField *field = [SCNPhysicsField radialGravityField];
    field.halfExtent = SCNVector3Make(100, 100, 100);
    field.minimumDistance = 20.0;
    field.falloffExponent = 0;
    _fieldOwner.physicsField.strength = 0.0;
    _fieldOwner.physicsField = field;
    [_scene.rootNode addChildNode:_fieldOwner];
}

//remove physics field slide
- (void) orderOutPhysicsFields
{
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:0.75];
    _spotLightNode.light.color = [SKColor colorWithWhite:1.0 alpha:1.0];
    _ambientLightNode.light.color = [SKColor colorWithWhite:0.3 alpha:1.0];
    [SCNTransaction commit];
    
    //move camera
    CGFloat dz = 50;
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:0.75];
    _cameraHandle.position = SCNVector3Make(_cameraHandle.position.x, _cameraHandle.position.y, _cameraHandle.position.z - dz);
    [SCNTransaction commit];
    
    [_fieldEmitter removeFromParentNode];
    [_fieldOwner removeFromParentNode];
    _fieldEmitter = nil;
    _fieldOwner = nil;
}

#pragma mark -
#pragma mark SpriteKit

#define SPRITE_SIZE 256

// add a color "splash" at the specified location in the SKScene used as a material
- (void) addPaintAtLocation:(CGPoint) p color:(SKColor *) color
{
    SKScene *skScene = _torus.geometry.firstMaterial.diffuse.contents;
    
    if ([skScene isKindOfClass:[SKScene class]]) {
        //update the contents of skScene by adding a splash of "color" at p (normalized [0, 1])
        p.x *= SPRITE_SIZE;
        p.y *= SPRITE_SIZE;
        
        SKNode *node = [SKSpriteNode node];
        node.position = p;
        node.xScale = 0.33;
        
        SKSpriteNode *subNode = [SKSpriteNode spriteNodeWithImageNamed:@"splash.png"];
        subNode.zRotation = randFloat(0.0, 2.0 * M_PI);
        subNode.color = color;
        subNode.colorBlendFactor = 1;
        
        [node addChild:subNode];
        [skScene addChild:node];
        
        if (p.x < 16) {
            node = [node copy];
            p.x = SPRITE_SIZE + p.x;
            node.position = p;
            [skScene addChild:node];
        }
        else if (p.x > SPRITE_SIZE-16) {
            node = [node copy];
            p.x = (p.x - SPRITE_SIZE);
            node.position = p;
            [skScene addChild:node];
        }
    }
}

// physics contact delegate
- (void)physicsWorld:(SCNPhysicsWorld *)world didBeginContact:(SCNPhysicsContact *)contact
{
    SCNNode *ball = nil;
    SCNNode *other = nil;

    if (contact.nodeA.physicsBody.type == SCNPhysicsBodyTypeDynamic) {
        ball = contact.nodeA;
        other = contact.nodeB;
    }
    else if(contact.nodeB.physicsBody.type == SCNPhysicsBodyTypeDynamic){
        ball = contact.nodeB;
        other = contact.nodeA;
    }
    
    if (ball) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [ball removeFromParentNode];
        });
        
        SCNParticleSystem *plokCopy = [_plok copy];
        plokCopy.particleImage = _plok.particleImage; // to workaround an bug in seed #1
        plokCopy.particleColor = ball.geometry.firstMaterial.diffuse.contents;
        [_scene addParticleSystem:plokCopy withTransform:SCNMatrix4MakeTranslation(contact.contactPoint.x, contact.contactPoint.y, contact.contactPoint.z)];
        
        if (other != _torus) {
            SCNNode *node = [_splashNode clone];
            node.geometry = [node.geometry copy];
            node.geometry.firstMaterial = [node.geometry.firstMaterial copy];
            node.geometry.firstMaterial.diffuse.contents = plokCopy.particleColor;
            node.castsShadow = NO;
            //node.geometry.firstMaterial.readsFromDepthBuffer = NO;
            node.geometry.firstMaterial.writesToDepthBuffer = NO;
            
            static float eps = 1;
            eps += 0.0002;
            node.position = SCNVector3Make(contact.contactPoint.x, contact.contactPoint.y, _mainWall.position.z + eps);
            
            [node runAction:[SCNAction sequence:@[[SCNAction waitForDuration:6.],
                                                  [SCNAction fadeOutWithDuration:1.5],
                                                  [SCNAction removeFromParentNode]
                                                  ]]];
            [_scene.rootNode addChildNode:node];
            
        } else {
            //compute texture coordinate
            SCNView *scnview = (SCNView*)self.view;
            SCNVector3 pointA = SCNVector3Make(contact.contactPoint.x, contact.contactPoint.y, contact.contactPoint.z+20);
            SCNVector3 pointB = SCNVector3Make(contact.contactPoint.x, contact.contactPoint.y, contact.contactPoint.z-20);
            
            NSArray *results = [scnview.scene.rootNode hitTestWithSegmentFromPoint:pointA toPoint:pointB options:@{SCNHitTestRootNodeKey : _torus}];
            
            if ([results count]>0) {
                SCNHitTestResult *hit = results[0];
                [self addPaintAtLocation:[hit textureCoordinatesWithMappingChannel:0] color:plokCopy.particleColor];
                
            }
        }
    }
}

//present spritekit integration slide
- (void)showSpriteKitSlide
{
    //place camera
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:2.0];
    _cameraHandle.position = SCNVector3Make(_cameraHandle.position.x+200, 60, 0);
    [SCNTransaction commit];

    
    //load plok particles
    _plok = [SCNParticleSystem particleSystemNamed:@"plok.scnp" inDirectory:@"assets.scnassets/particles"];
    
#define W 50
    
    //create a spinning object
    _torus = [SCNNode node];
    _torus.position = SCNVector3Make(_cameraHandle.position.x, 60, 10);
    _torus.geometry = [SCNTorus torusWithRingRadius:W/2 pipeRadius:W/6];
    _torus.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeStatic shape:[SCNPhysicsShape shapeWithGeometry:_torus.geometry options:@{SCNPhysicsShapeTypeKey : SCNPhysicsShapeTypeConcavePolyhedron}]];
    _torus.opacity = 0.0;
    
    // create a splash
    _splashNode = [SCNNode node];
    _splashNode.geometry = [SCNPlane planeWithWidth:10 height:10];
    _splashNode.geometry.firstMaterial.transparent.contents = @"splash.png";

    
    SCNMaterial *material = _torus.geometry.firstMaterial;
    material.specular.contents = [SKColor colorWithWhite:0.5 alpha:1];
    material.shininess = 2.0;
    
    material.normal.contents = @"wood-normal.png";
    
    [_scene.rootNode addChildNode:_torus];
    [_torus runAction:[SCNAction repeatActionForever:[SCNAction rotateByAngle:M_PI*2 aroundAxis:SCNVector3Make(0.4, 1, 0) duration:8]]];
    
    //preload it to avoid frame drop
    [(SCNView*)self.view prepareObject:_scene shouldAbortBlock:nil];
    
    _scene.physicsWorld.contactDelegate = self;
    
    //setup material
    SKScene *skScene = [SKScene sceneWithSize:CGSizeMake(SPRITE_SIZE, SPRITE_SIZE)];
    skScene.backgroundColor = [SKColor whiteColor];
    material.diffuse.contents = skScene;
    
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:1.0];
    [SCNTransaction setCompletionBlock:^{
        [self startLaunchingColors];
    }];
    
    _torus.opacity = 1.0;
    
    [SCNTransaction commit];
}


- (void)startLaunchingColors
{
    //tweak physics
    ((SCNView*)self.view).scene.physicsWorld.gravity = SCNVector3Make(0, -70, 0);
    
    // drop rigid bodies
    uint64_t intervalTime = NSEC_PER_SEC * 0.1;
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), intervalTime, 0); // every ms
    
    __block BOOL right = NO;
    
    dispatch_source_set_event_handler(_timer, ^{
        
        if (_step != 4) {
            dispatch_source_cancel(_timer);
            return;
        }
        
        SCNNode *ball = [SCNNode node];
        SCNSphere *sphere = [SCNSphere sphereWithRadius:2];
        ball.geometry = sphere;
        ball.geometry.firstMaterial.diffuse.contents = [SKColor colorWithHue:rand()/(float)RAND_MAX saturation:1 brightness:1 alpha:1];
        ball.geometry.firstMaterial.reflective.contents = @"envmap.jpg";
        ball.geometry.firstMaterial.fresnelExponent = 1.0;
        ball.physicsBody = [SCNPhysicsBody dynamicBody];
        ball.physicsBody.restitution = 0.9;
        ball.physicsBody.categoryBitMask = 0x4;
        ball.physicsBody.collisionBitMask = ~(0x4);
        
        [SCNTransaction begin];
        
        ball.position = SCNVector3Make(_cameraHandle.position.x, 20, 100);
        
        //add to scene
        [_scene.rootNode addChildNode:ball];
        
#define PAINT_FACTOR 2
        
        [ball.physicsBody setVelocity:SCNVector3Make(PAINT_FACTOR * randFloat(-10, 10),
                                                     (75+randFloat(0, 35)),
                                                     PAINT_FACTOR * -30.0)];
        [SCNTransaction commit];
        
        right = 1-right;
    });
    
    dispatch_resume(_timer);
}

- (void)orderOutSpriteKit
{
    [_torus removeFromParentNode];
    _scene.physicsWorld.contactDelegate = nil;
}

#pragma mark - Shaders

- (void)showNextShaderStage
{
    _shaderStage++;

    //retrieve the node that owns the shader modifiers
    SCNNode *node = _shadedNode;
    
    switch(_shaderStage){
        case 1: // Geometry
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:1.];
            node.geometry.shaderModifiers = @{SCNShaderModifierEntryPointGeometry : _geomModifier,
                                              SCNShaderModifierEntryPointLightingModel : _lightModifier };

            [node.geometry setValue:@3.0 forKey:@"Amplitude"];
            [node.geometry setValue:@0.25 forKey:@"Frequency"];
            [node.geometry setValue:@0.0 forKey:@"lightIntensity"];
            [SCNTransaction commit];
            break;
        case 2: // Surface
        {
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:0.5];
            [node.geometry setValue:@0.0 forKey:@"Amplitude"];
            [SCNTransaction setCompletionBlock:^{
                [SCNTransaction begin];
                [SCNTransaction setAnimationDuration:1.5];
                node.geometry.shaderModifiers = @{SCNShaderModifierEntryPointSurface : _surfModifier,
                                                  SCNShaderModifierEntryPointLightingModel : _lightModifier };
                [node.geometry setValue:@1.0 forKey:@"surfIntensity"];
                [SCNTransaction commit];
            }];
            [SCNTransaction commit];
        } break;
        case 3: // Fragment
        {
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:0.5];

            [node.geometry setValue:@0.0 forKey:@"surfIntensity"];
            [SCNTransaction setCompletionBlock:^{
                [SCNTransaction begin];
                [SCNTransaction setAnimationDuration:1.5];
                node.geometry.shaderModifiers = @{SCNShaderModifierEntryPointFragment : _fragModifier,
                                                  SCNShaderModifierEntryPointLightingModel : _lightModifier};
                [node.geometry setValue:@1.0 forKey:@"fragIntensity"];
                [node.geometry setValue:@1.0 forKey:@"lightIntensity"];
                [SCNTransaction commit];
            }];
            [SCNTransaction commit];
        }

            break;
        case 4: // None
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:0.5];
            [node.geometry setValue:@0.0 forKey:@"fragIntensity"];
            [node.geometry setValue:@0.0 forKey:@"lightIntensity"];
            _shaderStage = 0;
            [SCNTransaction setCompletionBlock:^{
                node.geometry.shaderModifiers = nil;
            }];
            [SCNTransaction commit];
            break;
    }
}

- (void)showShadersSlide
{
    _shaderStage = 0;
    
    //move the camera back
    //place camera
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:1.0];
    _cameraHandle.position = SCNVector3Make(_cameraHandle.position.x+180, 60, 0);
    _cameraHandle.eulerAngles = SCNVector3Make(-M_PI_4*0.3, 0, 0);
    
    _spotLightNode.light.spotOuterAngle = 55;
    [SCNTransaction commit];
    
    _shaderGroupNode = [SCNNode node];
    _shaderGroupNode.position = SCNVector3Make(_cameraHandle.position.x, -5, 20);
    [_scene.rootNode addChildNode:_shaderGroupNode];
    
    //add globe stand
    SCNNode *globe = [[[SCNScene sceneNamed:@"assets.scnassets/models/globe.dae"] rootNode] childNodeWithName:@"globe" recursively:YES];
    
    [_shaderGroupNode addChildNode:globe];
    
    //show shader modifiers
    //add spheres
    SCNSphere *sphere = [SCNSphere sphereWithRadius:28];
    sphere.segmentCount = 48;
    sphere.firstMaterial.diffuse.contents = @"earth-diffuse.jpg";
    sphere.firstMaterial.specular.contents = @"earth-specular.jpg";
    sphere.firstMaterial.specular.intensity = 0.2;
    
    sphere.firstMaterial.shininess = 0.1;
    sphere.firstMaterial.reflective.contents = @"envmap.jpg";
    sphere.firstMaterial.reflective.intensity = 0.5;
    sphere.firstMaterial.fresnelExponent = 2;
    
    //GEOMETRY
    SCNNode *node = [globe childNodeWithName:@"globeAttach" recursively:YES];
    node.geometry = sphere;
    node.scale = SCNVector3Make(3, 3, 3);
    
    [node runAction:[SCNAction repeatActionForever:[SCNAction rotateByX:0 y:M_PI z:0 duration:6.0]]];
    
    _geomModifier = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sm_geom" ofType:@"shader"] encoding:NSUTF8StringEncoding error:nil];
    _surfModifier = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sm_surf" ofType:@"shader"] encoding:NSUTF8StringEncoding error:nil];
    _fragModifier = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sm_frag" ofType:@"shader"] encoding:NSUTF8StringEncoding error:nil];
    _lightModifier= [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sm_light" ofType:@"shader"] encoding:NSUTF8StringEncoding error:nil];
    
    [node.geometry setValue:@0.0 forKey:@"Amplitude"];
    [node.geometry setValue:@0.0 forKey:@"lightIntensity"];
    [node.geometry setValue:@0.0 forKey:@"surfIntensity"];
    [node.geometry setValue:@0.0 forKey:@"fragIntensity"];
    
    _shadedNode = node;
    
    //redraw forever
    ((SCNView*)self.view).playing = YES;
    ((SCNView*)self.view).loops = YES;
}

- (void)orderOutShaders
{
    [_shaderGroupNode runAction:[SCNAction sequence:@[[SCNAction scaleTo:0.01 duration:1.0], [SCNAction removeFromParentNode]]]];
    _shaderGroupNode = nil;
}

#pragma mark - Presentation logic

- (void)presentStep:(NSUInteger)step
{
    AAPLSpriteKitOverlayScene *overlay = (AAPLSpriteKitOverlayScene *)((SCNView*)self.view).overlaySKScene;
    
    if (_cameraHandleTransforms[step].m11 == 0) {
        _cameraHandleTransforms[step] = _cameraHandle.transform;
        _cameraOrientationTransforms[step] = _cameraOrientation.transform;
    }
    
    switch(step) {
        case 1:
        {
            [overlay showLabel:@"Physics"];
            [overlay runAction:[SKAction sequence:@[[SKAction waitForDuration:2], [SKAction runBlock:^{
                if (_step == 1)
                    [overlay showLabel:nil];
            }]]]];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self showPhysicsSlide];
            });
        }
            break;
        case 2:
        {
            [overlay showLabel:@"Particles"];
            [overlay runAction:[SKAction sequence:@[[SKAction waitForDuration:4], [SKAction runBlock:^{
                if (_step == 2)
                    [overlay showLabel:nil];
            }]]]];
            
            [self showParticlesSlide];
            break;
        }
        case 3:
        {
            [overlay showLabel:@"Physics Fields"];
            [overlay runAction:[SKAction sequence:@[[SKAction waitForDuration:2], [SKAction runBlock:^{
                if (_step == 3)
                    [overlay showLabel:nil];
            }]]]];
            
            [self showPhysicsFields];
            break;
        }
        case 4:
        {
            [overlay showLabel:@"SceneKit + SpriteKit"];
            [overlay runAction:[SKAction sequence:@[[SKAction waitForDuration:4], [SKAction runBlock:^{
                if (_step == 4)
                    [overlay showLabel:nil];
            }]]]];
            
            [self showSpriteKitSlide];
            break;
        }
        case 5:
        {
            [overlay showLabel:@"SceneKit + Shaders"];
            [self showShadersSlide];
            break;
        }
    }
}

- (void)orderOutStep:(NSInteger)step
{
    switch(step) {
        case 1:
            [self orderOutPhysics];
            break;
        case 2:
            [self orderOutParticles];
            break;
        case 3:
            [self orderOutPhysicsFields];
            break;
        case 4:
            [self orderOutSpriteKit];
            break;
        case 5:
            [self orderOutShaders];
            break;
    }
}

- (void)next
{
    if (_step >= 5)
        return;
    
    [self orderOutStep:_step];
    _step++;
    [self presentStep:_step];
}

- (void)previous
{
    if (_step <= 1)
        return;
    
    [self orderOutStep:_step];
    _step--;
    
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:0.75];
    [SCNTransaction setCompletionBlock:^{
        [self presentStep:_step];
    }];
    
    _cameraHandle.transform = _cameraHandleTransforms[_step];
    _cameraOrientation.transform = _cameraOrientationTransforms[_step];
    
    [SCNTransaction commit];
}

#pragma mark - Rendering Loop

- (void)renderer:(id <SCNSceneRenderer>)aRenderer updateAtTime:(NSTimeInterval)time
{
    if (_step == 2 && _hitFire) {
        float fire = _fire.birthRate;
        
        if (fire > 0) {
            fire -= 0.1;
            _smoke.birthRate = (1.0-(fire / MAX_FIRE)) * MAX_SMOKE;
            _fire.birthRate = MAX(0,fire);
        }
        else {
            float smoke = _smoke.birthRate ;
            if (smoke>0)
                smoke -= 0.03;
            
            _smoke.birthRate = MAX(0,smoke);
        }
    }
}

#pragma mark - Gestures

- (void)gestureDidEnd
{
     if (_step == 3) {
         //bubbles
         _fieldOwner.physicsField.strength = 0.0;
     }
}

- (void)gestureDidBegin
{
    _initialOffset = _lastOffset;
}

#if TARGET_OS_IPHONE
- (void)handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer
{
    [self restoreCameraAngle];
}

- (void)handlePan:(UITapGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self gestureDidEnd];
        return;
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self gestureDidBegin];
        return;
    }
    
    if (gestureRecognizer.numberOfTouches == 2) {
        [self tiltCameraWithOffset:[(UIPanGestureRecognizer *)gestureRecognizer translationInView:self.view]];
    }
    else {
        CGPoint p = [gestureRecognizer locationInView:self.view];
        [self handlePanAtPoint:p];
    }
}

- (void)handleTap:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint p = [gestureRecognizer locationInView:self.view];
    [self handleTapAtPoint:p];
}
#endif

- (void)handlePanAtPoint:(CGPoint) p
{
    SCNView *scnView = (SCNView *) self.view;
    
    if (_step == 2) {
        //particles
        SCNVector3 pTmp = [scnView projectPoint:SCNVector3Make(0, 0, 0)];
        SCNVector3 p3d = [scnView unprojectPoint:SCNVector3Make(p.x, p.y, pTmp.z)];
        SCNMatrix4 handlePos = _handle.worldTransform;
        
        
        float dy = MAX(0, p3d.y - handlePos.m42);
        float dx = handlePos.m41 - p3d.x;
        float angle = atan2f(dy, dx);
        
        
        angle -= 35.*M_PI/180.0; //handle is 35 degree by default
        
        //clamp
#define MIN_ANGLE -M_PI_2*0.1
#define MAX_ANGLE M_PI*0.8
        if (angle < MIN_ANGLE) angle = MIN_ANGLE;
        if (angle > MAX_ANGLE) angle = MAX_ANGLE;
        
        
#define HIT_DELAY 3.0
        
        if (angle <= 0.66 && angle >= 0.48) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(HIT_DELAY * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //hit the fire!
                _hitFire = YES;
            });
        }
        else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(HIT_DELAY * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //hit the fire!
                _hitFire = NO;
            });
        }
        
        _handle.rotation = SCNVector4Make(1, 0, 0, angle);
    }
    
    if (_step == 3) {
        //bubbles
        [self moveEmitterTo:p];
    }
}

- (void)handleDoubleTapAtPoint:(CGPoint)p
{
    [self restoreCameraAngle];
}

- (void) preventAccidentalNext:(CGFloat) delay
{
    _preventNext = YES;
    
    //disable the next button for "delay" seconds to prevent accidental tap
    AAPLSpriteKitOverlayScene *overlay = (AAPLSpriteKitOverlayScene *)((SCNView*)self.view).overlaySKScene;
    [overlay.nextButton runAction:[SKAction fadeAlphaBy:-0.5 duration:0.5]];
    [overlay.previousButton runAction:[SKAction fadeAlphaBy:-0.5 duration:0.5]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _preventNext = NO;
        [overlay.previousButton runAction:[SKAction fadeAlphaTo:_step > 1 ? 1 : 0 duration:0.75]];
        [overlay.nextButton runAction:[SKAction fadeAlphaTo:_introductionStep == 0 && _step < 5 ? 1 : 0 duration:0.75]];
    });
}

- (void)handleTapAtPoint:(CGPoint)p
{
    //test buttons
    SKScene *skScene = ((SCNView*)self.view).overlaySKScene;
    CGPoint p2D = [skScene convertPointFromView:p];
    SKNode *node = [skScene nodeAtPoint:p2D];
    
    // wait X seconds before enabling the next tap to avoid accidental tap
    BOOL ignoreNext = _preventNext;
    
    if (_introductionStep) {
        //next introduction step
        if (!ignoreNext){
            [self preventAccidentalNext:1];
            [self nextIntroductionStep];
        }
        return;
    }
    
    if (ignoreNext == NO) {
        if (_step == 0 || [node.name isEqualToString:@"next"] || [node.name isEqualToString:@"back"]) {
            BOOL shouldGoBack = [node.name isEqualToString:@"back"];

            if ([node.name isEqualToString:@"next"]) {
                ((SKSpriteNode*)node).color = [SKColor colorWithRed:1 green:0 blue:0 alpha:1];
                [node runAction:[SKAction customActionWithDuration:0.7 actionBlock:^(SKNode *node, CGFloat elapsedTime) {
                    ((SKSpriteNode*)node).colorBlendFactor = 0.7 - elapsedTime;
                }]];
            }
            
            [self restoreCameraAngle];
            
            [self preventAccidentalNext:_step==1 ? 3 : 1];
            
            if (shouldGoBack)
                [self previous];
            else
                [self next];
            
            return;
        }
    }
    
    if (_step == 1) {
        //bounce physics!
        SCNView *scnView = (SCNView *) self.view;
        SCNVector3 pTmp = [scnView projectPoint:SCNVector3Make(0, 0, -60)];
        SCNVector3 p3d = [scnView unprojectPoint:SCNVector3Make(p.x, p.y, pTmp.z)];
        
        p3d.y = 0;
        p3d.z = 0;
        
        [self explosionAt:p3d receivers:_boxes removeOnCompletion:NO];
    }
    if (_step == 3) {
        //bubbles
        [self moveEmitterTo:p];
    }
    
    if (_step == 5) {
        //shader
        [self showNextShaderStage];
    }
}

@end



@implementation AAPLSpriteKitOverlayScene {
@private
    SKNode *_nextButton;
    SKNode *_previousButton;
    CGSize _size;
    SKLabelNode *_label;
}

- (instancetype)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size]) {
        _size = size;
        
        /* Setup your scene here */
        self.anchorPoint = CGPointMake(0.5, 0.5);
        self.scaleMode = SKSceneScaleModeResizeFill;
        
        //buttons
        _nextButton = [SKSpriteNode spriteNodeWithImageNamed:@"next.png"];
        
        float marginY = 60;
        float maringX = -60;
#if TARGET_OS_IPHONE
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            marginY = 30;
            marginY = 30;
        }
#endif
        
        _nextButton.position = CGPointMake(size.width * 0.5 + maringX, -size.height * 0.5 + marginY);
        _nextButton.name = @"next";
        _nextButton.alpha = 0.01;
#if TARGET_OS_IPHONE
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            _nextButton.xScale = _nextButton.yScale = 0.5;
        }
#endif
        [self addChild:_nextButton];
        
        _previousButton = [SKSpriteNode spriteNodeWithColor:[SKColor clearColor] size:_nextButton.frame.size];
        _previousButton.position = CGPointMake(-(size.width * 0.5 + maringX), -size.height * 0.5 + marginY);
        _previousButton.name = @"back";
        _previousButton.alpha = 0.01;
        [self addChild:_previousButton];
    }
    return self;
}

- (void)showLabel:(NSString *)label
{
    if (!_label) {
        _label = [SKLabelNode labelNodeWithFontNamed:@"Myriad Set"];
        if(!_label)
            _label = [SKLabelNode labelNodeWithFontNamed:@"Avenir-Heavy"];
        _label.fontSize = 140;
        _label.position = CGPointMake(0,0);
        
        [self addChild:_label];
    }
    else {
        if (label)
            _label.position = CGPointMake(0, _size.height * 0.25);
    }
    
    if (!label) {
        [_label runAction:[SKAction fadeOutWithDuration:0.5]];
    }
    else {
#if TARGET_OS_IPHONE
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            _label.fontSize = [label length] > 10 ? 50 : 80;
        }
        else
#endif
        {
            _label.fontSize = [label length] > 10 ? 100 : 140;
        }
        
        _label.text = label;
        _label.alpha = 0.0;
        [_label runAction:[SKAction sequence:@[[SKAction waitForDuration:0.5], [SKAction fadeInWithDuration:0.5]]]];
    }
}

@end
