/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The view displaying the game scene. Handles keyboard (OS X) and touch (iOS) input for controlling the game.
*/

@import SpriteKit;

#import "AAPLGameView.h"
#import "AAPLGameViewController.h"

#define SHOW_DPAD 1

typedef NS_ENUM(NSInteger, AAPLDirection) {
    AAPLDirectionUp,
    AAPLDirectionLeft,
    AAPLDirectionRight,
    AAPLDirectionDown,
    AAPLDirectionCount
};

@implementation AAPLGameView
{
#if !TARGET_OS_IPHONE
    bool keyPressed[AAPLDirectionCount];
    CGPoint _lastMousePosition;
#else
    CGPoint _direction;
    UITouch *_panningTouch;
    UITouch *_padTouch;
#endif
    
    CGRect _padRect;
    SKSpriteNode *_flowers[3];
    SKLabelNode *_pearlLabel;
    SKNode *_overlayGroup;
    NSInteger _pearlCount;
    NSInteger _flowerCount;
    
    BOOL _directionCacheValid;
    SCNVector3 _directionCache;
    
    CGFloat _defaultFov;
}

#pragma mark Initial Setup

- (void)setup
{
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    
#if TARGET_OS_IPHONE
    // Support Landscape scape
    if (w < h) {
        CGFloat wTmp = w;
        w = h;
        h = wTmp;
    }
#endif
    
    // Setup the game overlays using SpriteKit.
    SKScene *skScene = [SKScene sceneWithSize:CGSizeMake(w, h)];
    skScene.scaleMode = SKSceneScaleModeResizeFill;

    _overlayGroup = [SKNode node];
    [skScene addChild:_overlayGroup];
    _overlayGroup.position = CGPointMake(0, h);
    
    // The Max icon.
    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"MaxIcon.png"];
    sprite.position = CGPointMake(50, - 50);
    [_overlayGroup addChild:sprite];
    sprite.xScale = sprite.yScale = 0.5;
    
    // The flowers.
    for (int i=0; i<3; i++) {
        _flowers[i] = [SKSpriteNode spriteNodeWithImageNamed:@"FlowerEmpty.png"];
        _flowers[i].position = CGPointMake(110 + i*40, - 50);
        _flowers[i].xScale = _flowers[i].yScale = 0.25;
        [_overlayGroup addChild:_flowers[i]];
    }

    // The peal icon and count.
    sprite = [SKSpriteNode spriteNodeWithImageNamed:@"ItemsPearl.png"];
    sprite.position = CGPointMake(110, -100);
    sprite.xScale = sprite.yScale = 0.5;
    [_overlayGroup addChild:sprite];
    
    _pearlLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    _pearlLabel.text = @"x0";
    _pearlLabel.position = CGPointMake(152, -113);
    [_overlayGroup addChild:_pearlLabel];
    
    // The D-Pad
#if SHOW_DPAD && TARGET_OS_IPHONE
#define DPAD_RADIUS 80
    sprite = [SKSpriteNode spriteNodeWithImageNamed:@"dpad.png"];
    sprite.position = CGPointMake(100, 100);
    sprite.xScale = sprite.yScale = 0.5;
    [skScene addChild:sprite];

    _padRect = CGRectMake((sprite.position.y-DPAD_RADIUS)/w, 1.0 - ((sprite.position.y + DPAD_RADIUS) / h), 2 * DPAD_RADIUS/w, 2 * DPAD_RADIUS/h);
#else
    _padRect = CGRectMake(0, 0.7, 0.3, 0.3);
#endif
    
    // Assign the SpriteKit overlay to the SceneKit view.
    self.overlaySKScene = skScene;
    
    // Setup the pinch gesture
    _defaultFov = self.pointOfView.camera.xFov;
    
#if TARGET_OS_IPHONE
    UIGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] init];
    pinch.delegate = (id <UIGestureRecognizerDelegate>) self;
    [pinch addTarget:self action:@selector(pinchWithGestureRecognizer:)];
    pinch.cancelsTouchesInView = NO;
    [self addGestureRecognizer:pinch];
#endif
}

#pragma mark Overlays

- (BOOL)didCollectAFlower
{
    if (_flowerCount < 3)
        _flowers[_flowerCount].texture = [SKTexture textureWithImageNamed:@"FlowerFull.png"];
    
    _flowerCount++;
    
    return _flowerCount == 3; // Return YES when every flowers are collected.
}


- (void)didCollectAPearl
{
    _pearlCount++;
    if (_pearlCount == 10) {
        _pearlLabel.position = CGPointMake(158, _pearlLabel.position.y);
    }
    
    _pearlLabel.text = [NSString stringWithFormat:@"x%d", (int)_pearlCount];
}

#pragma mark Events

#if !TARGET_OS_IPHONE

// Override setFrame to update SpriteKit overlays
- (void)setFrame:(NSRect)frame
{
    [super setFrame:frame];
    
    //update SpriteKit overlays
    _overlayGroup.position = CGPointMake(0, frame.size.height);
}

-(void)mouseDown:(NSEvent *)theEvent
{
    // Remember last mouse position for dragging.
    _lastMousePosition = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    [super mouseDown:theEvent];
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    _directionCacheValid = NO;
    
    CGPoint mousePosition = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    // Pan the camera on drag.
    [self.controller panCamera:CGSizeMake(mousePosition.x-_lastMousePosition.x, mousePosition.y-_lastMousePosition.y)];
    _lastMousePosition = mousePosition;
    
    [super mouseDragged:theEvent];
}

// Keep a cache of pressed keys.
- (void)keyDown:(NSEvent *)theEvent
{
    _directionCacheValid = NO;
    
    unichar firstChar = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];

    switch (firstChar) {
        case NSUpArrowFunctionKey:
            if (![theEvent isARepeat]) {
                keyPressed[AAPLDirectionUp] = YES;
            }
            return;
        case NSDownArrowFunctionKey:
            if (![theEvent isARepeat]) {
                keyPressed[AAPLDirectionDown] = YES;
            }
            return;
        case NSRightArrowFunctionKey: //
            if (![theEvent isARepeat]) {
                keyPressed[AAPLDirectionRight] = YES;
            }
            return;
        case NSLeftArrowFunctionKey:
            if (![theEvent isARepeat]) {
                keyPressed[AAPLDirectionLeft] = YES;
            }
            return;
    }
    
    [super keyDown:theEvent];
}

- (void)keyUp:(NSEvent *)theEvent
{
    _directionCacheValid = NO;
    
    unichar firstChar = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    
    switch (firstChar) {
        case NSUpArrowFunctionKey: // accelerate forward
            if (![theEvent isARepeat]) {
                keyPressed[AAPLDirectionUp] = NO;
            }
            return;
        case NSDownArrowFunctionKey: // accelerate forward
            if (![theEvent isARepeat]) {
                keyPressed[AAPLDirectionDown] = NO;
            }
            return;
        case NSRightArrowFunctionKey: //
            if (![theEvent isARepeat]) {
                keyPressed[AAPLDirectionRight] = NO;
            }
            return;
        case NSLeftArrowFunctionKey:
            if (![theEvent isARepeat]) {
                keyPressed[AAPLDirectionLeft] = NO;
            }
            return;
    }
    
    [super keyUp:theEvent];
}
#else  // TARGET_OS_IPHONE

- (BOOL)touch:(UITouch *)touch isInRect:(CGRect)rect
{
    CGRect bounds = self.bounds;
    rect = CGRectApplyAffineTransform(rect, CGAffineTransformMakeScale(bounds.size.width, bounds.size.height));
    return CGRectContainsPoint(rect, [touch locationInView:self]);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches) {
        if ([self touch:touch isInRect:_padRect]) {
            // We're in the dpad
            if (!_padTouch) {
                _padTouch = touch;
            }
        }
        else if (!_panningTouch) {
            // Start panning
            _panningTouch = [touches anyObject];
        }
        
        if (_padTouch && _panningTouch)
            break;  // We already have what we need
    }
    [super touchesBegan:touches withEvent:event];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    _directionCacheValid = NO;
    
    if (_panningTouch) {
        CGPoint _p0 = [_panningTouch previousLocationInView:self];
        CGPoint _p1 = [_panningTouch locationInView:self];
        
        [self.controller panCamera:CGSizeMake(_p1.x-_p0.x, _p0.y-_p1.y)];
    }

    if (_padTouch) {
        CGPoint _p0 = [_padTouch previousLocationInView:self];
        CGPoint _p1 = [_padTouch locationInView:self];
        
        const float SPEED = 1.0 / 10.0;
        const float LIMIT = 1;
        _direction.x += (_p1.x-_p0.x) * SPEED;
        _direction.y += (_p1.y-_p0.y) * SPEED;

        if (_direction.x > LIMIT)
            _direction.x = LIMIT;
        
        if (_direction.x < -LIMIT)
            _direction.x = -LIMIT;
        
        if (_direction.y > LIMIT)
            _direction.y = LIMIT;
        
        if (_direction.y < -LIMIT)
            _direction.y = -LIMIT;
        
        [self directionDidChange];
    }
    [super touchesMoved:touches withEvent:event];
}

-(void)commonTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_panningTouch) {
        if ([touches containsObject:_panningTouch]) {
            _panningTouch = nil;
        }
    }
    
    if (_padTouch) {
        if ([touches containsObject:_padTouch] || [[event touchesForView:self] containsObject:_padTouch] == NO) {
            _padTouch = nil;
            _direction = CGPointMake(0, 0);
            [self directionDidChange];
        }
    }
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self commonTouchesEnded:touches withEvent:event];
    [super touchesCancelled:touches withEvent:event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self commonTouchesEnded:touches withEvent:event];
    [super touchesEnded:touches withEvent:event];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] && _padTouch != nil)
        return NO;
        
    return YES;
}

- (void) pinchWithGestureRecognizer:(UIPinchGestureRecognizer *) recognizer
{
    [SCNTransaction begin];
    [SCNTransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];

    float fov = _defaultFov;
    float constraintFactor = 0;
    
    if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        //back to initial zoom
        [SCNTransaction setAnimationDuration:0.5];
    }
    else {
        [SCNTransaction setAnimationDuration:0.1];
        if (recognizer.scale > 1) {
            float scale = 1.0 + ((recognizer.scale - 1) * 0.75); //make pinch smoother
            fov *= 1 / scale; //zoom on pinch
            constraintFactor = MIN(1,(scale - 1) * 0.75); //focus on character when pinching
        }
    }
    
    self.pointOfView.camera.xFov = fov;
    self.pointOfView.constraints[0].influenceFactor = constraintFactor;
    
    [SCNTransaction commit];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIDeviceOrientationLandscapeRight) || (interfaceOrientation == UIDeviceOrientationLandscapeLeft);
}

-(BOOL)shouldAutorotate
{
    return NO;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIDeviceOrientationLandscapeRight | UIDeviceOrientationLandscapeLeft;
}

#endif // TARGET_OS_IPHONE

- (void)directionDidChange
{
    _directionCacheValid = NO;
}

- (CGPoint) directionFromPressedKeys
{
#if !TARGET_OS_IPHONE
    CGPoint d = {0,0};
    
    if (keyPressed[AAPLDirectionUp]) {
        d.y -= 1;
    }
    if (keyPressed[AAPLDirectionDown]) {
        d.y += 1;
    }
    if (keyPressed[AAPLDirectionLeft]) {
        d.x -= 1;
    }
    if (keyPressed[AAPLDirectionRight]) {
        d.x += 1;
    }
    
    return d;
#else
    return _direction;
#endif
}

// returns the direction based on the pressed keys and the current camera orientation
- (SCNVector3)computeDirection
{
    CGPoint p = [self directionFromPressedKeys];
    SCNVector3 dir = SCNVector3Make(p.x, 0, p.y);
    SCNVector3 p0 = SCNVector3Make(0, 0, 0);
    
    dir = [self.pointOfView.presentationNode convertPosition:dir toNode:nil];
    p0 = [self.pointOfView.presentationNode convertPosition:p0 toNode:nil];
    
    dir = SCNVector3Make(dir.x - p0.x, 0, dir.z - p0.z);
    
    if (dir.x !=0 || dir.z != 0) {
        //normalize
        dir = SCNVector3FromFloat3(vector_normalize(SCNVector3ToFloat3(dir)));
    }
    
    return dir;
}

- (SCNVector3)direction
{
    if (!_directionCacheValid) {
        _directionCache = [self computeDirection];
        _directionCacheValid = YES;
    }
    
    return _directionCache;
}
@end
