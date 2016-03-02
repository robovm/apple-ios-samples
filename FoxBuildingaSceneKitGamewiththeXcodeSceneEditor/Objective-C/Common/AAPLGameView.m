/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The view displaying the game scene, including the 2D overlay.
*/

@import SpriteKit;

#import "AAPLGameView.h"

@implementation AAPLGameView {
    SKNode *_overlayNode;
    SKNode *_congratulationsGroupNode;
    SKLabelNode *_collectedPearlCountLabel;
    NSMutableArray<SKSpriteNode *> *_collectedFlowerSprites;
}

#pragma mark -  2D Overlay

#if TARGET_OS_IOS || TARGET_OS_TV

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup2DOverlay];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layout2DOverlay];
}

#else

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    [self setup2DOverlay];
}

- (void)setFrameSize:(NSSize)newSize {
    [super setFrameSize:newSize];
    [self layout2DOverlay];
}

#endif

- (void)layout2DOverlay {
    _overlayNode.position = CGPointMake(0.0, self.bounds.size.height);
    
    _congratulationsGroupNode.position = CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5);
    
    _congratulationsGroupNode.xScale = 1.0;
    _congratulationsGroupNode.yScale = 1.0;
    CGRect currentBbox = [_congratulationsGroupNode calculateAccumulatedFrame];
   
    CGFloat margin = 25.0;
    CGRect maximumAllowedBbox = CGRectInset(self.bounds, margin, margin);
    
    CGFloat top = CGRectGetMaxY(currentBbox) - _congratulationsGroupNode.position.y;
    CGFloat bottom = _congratulationsGroupNode.position.y - CGRectGetMinY(currentBbox);
    CGFloat maxTopAllowed = CGRectGetMaxY(maximumAllowedBbox) - _congratulationsGroupNode.position.y;
    CGFloat maxBottomAllowed = _congratulationsGroupNode.position.y - CGRectGetMinY(maximumAllowedBbox);

    CGFloat left = _congratulationsGroupNode.position.x - CGRectGetMinX(currentBbox);
    CGFloat right = CGRectGetMaxX(currentBbox) - _congratulationsGroupNode.position.x;
    CGFloat maxLeftAllowed = _congratulationsGroupNode.position.x - CGRectGetMinX(maximumAllowedBbox);
    CGFloat maxRightAllowed = CGRectGetMaxX(maximumAllowedBbox) - _congratulationsGroupNode.position.x;
    
    CGFloat topScale = top > maxTopAllowed ? maxTopAllowed / top : 1;
    CGFloat bottomScale = bottom > maxBottomAllowed ? maxBottomAllowed / bottom : 1;
    CGFloat leftScale = left > maxLeftAllowed ? maxLeftAllowed / left : 1;
    CGFloat rightScale = right > maxRightAllowed ? maxRightAllowed / right : 1;
    
    CGFloat scale = MIN(topScale, MIN(bottomScale, MIN(leftScale, rightScale)));
    
    _congratulationsGroupNode.xScale = scale;
    _congratulationsGroupNode.yScale = scale;
}

- (void)setup2DOverlay {
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    
    _overlayNode = [[SKNode alloc] init];
    
    _collectedFlowerSprites = [[NSMutableArray alloc] init];
    
    // Setup the game overlays using SpriteKit.
    SKScene *skScene = [SKScene sceneWithSize:CGSizeMake(w, h)];
    skScene.scaleMode = SKSceneScaleModeResizeFill;
    
    [skScene addChild:_overlayNode];
    _overlayNode.position = CGPointMake(0.0, h);
    
    // The Max icon.
    SKSpriteNode *characterNode = [SKSpriteNode spriteNodeWithImageNamed:@"MaxIcon.png"];
    characterNode.position = CGPointMake(50, -50);
    characterNode.xScale = 0.5;
    characterNode.yScale = 0.5;
    [_overlayNode addChild:characterNode];
    
    // The flowers.
    for (NSUInteger i = 0; i < 3; i++) {
        SKSpriteNode *flowerNode = [SKSpriteNode spriteNodeWithImageNamed:@"FlowerEmpty.png"];
        flowerNode.position = CGPointMake(110 + i * 40, -50);
        flowerNode.xScale = 0.25;
        flowerNode.yScale = 0.25;
        [_overlayNode addChild:flowerNode];
        [_collectedFlowerSprites addObject:flowerNode];
    }
    
    // The pearl icon and count.
    SKSpriteNode *pearlNode = [SKSpriteNode spriteNodeWithImageNamed:@"ItemsPearl.png"];
    pearlNode.position = CGPointMake(110, -100);
    pearlNode.xScale = 0.5;
    pearlNode.yScale = 0.5;
    [_overlayNode addChild:pearlNode];

    _collectedPearlCountLabel = [[SKLabelNode alloc] initWithFontNamed:@"Chalkduster"];
    _collectedPearlCountLabel.text = @"x0";
    _collectedPearlCountLabel.position = CGPointMake(152, -113);
    [_overlayNode addChild:_collectedPearlCountLabel];
    
    // The virtual D-pad
#if TARGET_OS_IOS
    
    CGRect virtualDPadBounds = self.virtualDPadBoundsInScene;
    SKSpriteNode *dpadSprite = [SKSpriteNode spriteNodeWithImageNamed:@"dpad.png"];
    dpadSprite.anchorPoint = CGPointMake(0.0, 0.0);
    dpadSprite.position = virtualDPadBounds.origin;
    dpadSprite.size = virtualDPadBounds.size;
    [skScene addChild:dpadSprite];
    
#endif
    
    // Assign the SpriteKit overlay to the SceneKit view.
    self.overlaySKScene = skScene;
    skScene.userInteractionEnabled = NO;
}

- (void)setCollectedPearlsCount:(NSUInteger)collectedPearlsCount {
    _collectedPearlsCount = collectedPearlsCount;
    if (_collectedPearlsCount == 10) {
        _collectedPearlCountLabel.position = CGPointMake(158, _collectedPearlCountLabel.position.y);
    }
    _collectedPearlCountLabel.text = [NSString stringWithFormat:@"x%d", (uint32_t)collectedPearlsCount];
}

- (void)setCollectedFlowersCount:(NSUInteger)collectedFlowersCount {
    _collectedFlowerSprites[collectedFlowersCount - 1].texture = [SKTexture textureWithImageNamed:@"FlowerFull.png"];
}

#pragma mark - Congratulating the Player

- (void)showEndScreen {
    // Congratulation title
    SKSpriteNode *congratulationsNode = [SKSpriteNode spriteNodeWithImageNamed:@"congratulations.png"];
    
    // Max image
    SKSpriteNode *characterNode = [SKSpriteNode spriteNodeWithImageNamed:@"congratulations_pandaMax.png"];
    characterNode.position = CGPointMake(0.0, -220.0);
    characterNode.anchorPoint = CGPointMake(0.5, 0.0);
    
    _congratulationsGroupNode = [[SKNode alloc] init];
    
    [_congratulationsGroupNode addChild:characterNode];
    [_congratulationsGroupNode addChild:congratulationsNode];
    
    SKScene *overlayScene = self.overlaySKScene;
    [overlayScene addChild:_congratulationsGroupNode];
    
    // Layout the overlay
    [self layout2DOverlay];
    
    // Animate
    congratulationsNode.alpha = 0.0;
    congratulationsNode.xScale = 0.0;
    congratulationsNode.yScale = 0.0;
    [congratulationsNode runAction:[SKAction group:@[[SKAction fadeInWithDuration:0.25],
                                                     [SKAction sequence:@[[SKAction scaleTo:1.22 duration:0.25], [SKAction scaleTo:1.0 duration:0.1]]]]]];
    
    
    characterNode.alpha = 0.0;
    characterNode.xScale = 0.0;
    characterNode.yScale = 0.0;
    [characterNode runAction:[SKAction sequence:@[[SKAction waitForDuration:0.5], [SKAction group:@[[SKAction fadeInWithDuration:0.5],
                                                                                                    [SKAction sequence:@[[SKAction scaleTo:1.22 duration:0.25], [SKAction scaleTo:1.0 duration:0.1]]]]]]]];
}

#pragma mark - Mouse and Keyboard Events

#if !(TARGET_OS_IOS || TARGET_OS_TV)

- (void)mouseDown:(NSEvent *)theEvent {
    if (!_eventsDelegate || [_eventsDelegate mouseDown:self event:theEvent] == NO) {
        [super mouseDown:theEvent];
    }
}

- (void)mouseDragged:(NSEvent *)theEvent {
    if (!_eventsDelegate || [_eventsDelegate mouseDragged:self event:theEvent] == NO) {
        [super mouseDragged:theEvent];
    }
}

- (void)mouseUp:(NSEvent *)theEvent {
    if (!_eventsDelegate || [_eventsDelegate mouseUp:self event:theEvent] == NO) {
        [super mouseUp:theEvent];
    }
}

- (void)keyDown:(NSEvent *)theEvent {
    if (!_eventsDelegate || [_eventsDelegate keyDown:self event:theEvent] == NO) {
        [super keyDown:theEvent];
    }
}

- (void)keyUp:(NSEvent *)theEvent {
    if (!_eventsDelegate || [_eventsDelegate keyUp:self event:theEvent] == NO) {
        [super keyUp:theEvent];
    }
}

#endif

#pragma mark - Virtual D-pad

#if TARGET_OS_IOS

- (CGRect)virtualDPadBoundsInScene {
    return CGRectMake(10.0, 10.0, 150.0, 150.0);
}

- (CGRect)virtualDPadBounds {
    CGRect virtualDPadBounds = [self virtualDPadBoundsInScene];
    virtualDPadBounds.origin.y = self.bounds.size.height - virtualDPadBounds.size.height + virtualDPadBounds.origin.y;
    return virtualDPadBounds;
}

#endif

@end
