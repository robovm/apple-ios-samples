/*
     File: APAMultiplayerLayeredCharacterScene.m
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

#import "APAMultiplayerLayeredCharacterScene.h"
#import "APAPlayer.h"
#import "APAHeroCharacter.h"
#import "APAGraphicsUtilities.h"
#import <GameController/GameController.h>

@interface APAMultiplayerLayeredCharacterScene ()
@property (nonatomic) NSMutableArray *players;          // array of player objects or NSNull for no player
@property (nonatomic) APAPlayer *defaultPlayer;         // player '1' controlled by keyboard/touch
@property (nonatomic) SKNode *world;                    // root node to which all game renderables are attached
@property (nonatomic) NSMutableArray *layers;           // different layer nodes within the world
@property (nonatomic, readwrite) NSMutableArray *heroes;// our fearless adventurers

@property (nonatomic) NSArray *hudAvatars;              // keep track of the various nodes for the HUD
@property (nonatomic) NSArray *hudLabels;               // - there are always 'kNumPlayers' instances in each array
@property (nonatomic) NSArray *hudScores;
@property (nonatomic) NSArray *hudLifeHeartArrays;      // an array of NSArrays of life hearts

@property (nonatomic) NSTimeInterval lastUpdateTimeInterval; // the previous update: loop time interval
@end

@implementation APAMultiplayerLayeredCharacterScene

#pragma mark - Initialization
- (instancetype)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    if (self) {
        _players = [[NSMutableArray alloc] initWithCapacity:kNumPlayers];
        _defaultPlayer = [[APAPlayer alloc] init];
        [(NSMutableArray *)_players addObject:_defaultPlayer];
        for (int i = 1; i < kNumPlayers; i++) {
            [(NSMutableArray *)_players addObject:[NSNull null]];
        }
        
        _world = [[SKNode alloc] init];
        [_world setName:@"world"];
        _layers = [NSMutableArray arrayWithCapacity:kWorldLayerCount];
        for (int i = 0; i < kWorldLayerCount; i++) {
            SKNode *layer = [[SKNode alloc] init];
            layer.zPosition = i - kWorldLayerCount;
            [_world addChild:layer];
            [(NSMutableArray *)_layers addObject:layer];
        }
        
        [self addChild:_world];
        
        [self buildHUD];
        [self updateHUDForPlayer:_defaultPlayer forState:APAHUDStateLocal withMessage:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GCControllerDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GCControllerDidDisconnectNotification object:nil];
}

#pragma mark - Characters
- (APAHeroCharacter *)addHeroForPlayer:(APAPlayer *)player {
    NSAssert(![player isKindOfClass:[NSNull class]], @"Player should not be NSNull");
    
    if (player.hero && !player.hero.dying) {
        [player.hero removeFromParent];
    }
    
    CGPoint spawnPos = self.defaultSpawnPoint;
    
    APAHeroCharacter *hero = [[player.heroClass alloc] initAtPosition:spawnPos withPlayer:player];
    if (hero) {
        SKEmitterNode *emitter = [[self sharedSpawnEmitter] copy];
        emitter.position = spawnPos;
        [self addNode:emitter atWorldLayer:APAWorldLayerAboveCharacter];
        APARunOneShotEmitter(emitter, 0.15f);
        
        [hero fadeIn:2.0f];
        [hero addToScene:self];
        [(NSMutableArray *)self.heroes addObject:hero];
    }
    player.hero = hero;
    
    return hero;
}

- (void)heroWasKilled:(APAHeroCharacter *)hero {
    APAPlayer *player = hero.player;
    
    [(NSMutableArray *)self.heroes removeObject:hero];
    
#if TARGET_OS_IPHONE
    // Disable touch movement, otherwise new hero will try to move to previously-touched location.
    player.moveRequested = NO;
#endif
    
    if (--player.livesLeft < 1) {
        // In a real game, you'd want to end the game when there are no lives left.
        return;
    }
    
    [self updateHUDAfterHeroDeathForPlayer:hero.player];
    
    hero = [self addHeroForPlayer:hero.player];
    [self centerWorldOnCharacter:hero];
}

- (void)addNode:(SKNode *)node atWorldLayer:(APAWorldLayer)layer {
    SKNode *layerNode = self.layers[layer];
    [layerNode addChild:node];
}

#pragma mark - HUD and Scores
- (void)buildHUD {
    NSString *iconNames[] = { @"iconWarrior_blue", @"iconWarrior_green", @"iconWarrior_pink", @"iconWarrior_red" };
    NSArray *colors = @[ [SKColor greenColor], [SKColor blueColor], [SKColor yellowColor], [SKColor redColor] ];
    CGFloat hudX = 30;
    CGFloat hudY = self.frame.size.height - 30;
    CGFloat hudD = self.frame.size.width / kNumPlayers;
    
    _hudAvatars = [NSMutableArray arrayWithCapacity:kNumPlayers];
    _hudLabels = [NSMutableArray arrayWithCapacity:kNumPlayers];
    _hudScores = [NSMutableArray arrayWithCapacity:kNumPlayers];
    _hudLifeHeartArrays = [NSMutableArray arrayWithCapacity:kNumPlayers];
    SKNode *hud = [[SKNode alloc] init];
    
    for (int i = 0; i < kNumPlayers; i++) {
        SKSpriteNode *avatar = [SKSpriteNode spriteNodeWithImageNamed:iconNames[i]];
        avatar.scale = 0.5;
        avatar.alpha = 0.5;
        avatar.position = CGPointMake(hudX + i * hudD + (avatar.size.width * 0.5), self.frame.size.height - avatar.size.height * 0.5 - 8 );
        [(NSMutableArray *)_hudAvatars addObject:avatar];
        [hud addChild:avatar];
        
        SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"Copperplate"];
        label.text = @"NO PLAYER";
        label.fontColor = colors[i];
        label.fontSize = 16;
        label.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        label.position = CGPointMake(hudX + i * hudD + (avatar.size.width * 1.0), hudY + 10 );
        [(NSMutableArray *)_hudLabels addObject:label];
        [hud addChild:label];
        
        SKLabelNode *score = [SKLabelNode labelNodeWithFontNamed:@"Copperplate"];
        score.text = @"SCORE: 0";
        score.fontColor = colors[i];
        score.fontSize = 16;
        score.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        score.position = CGPointMake(hudX + i * hudD + (avatar.size.width * 1.0), hudY - 40 );
        [(NSMutableArray *)_hudScores addObject:score];
        [hud addChild:score];
        
        [(NSMutableArray *)_hudLifeHeartArrays addObject:[NSMutableArray arrayWithCapacity:kStartLives]];
        for (int j = 0; j < kStartLives; j++) {
            SKSpriteNode *heart = [SKSpriteNode spriteNodeWithImageNamed:@"lives.png"];
            heart.scale = 0.4;
            heart.position = CGPointMake(hudX + i * hudD + (avatar.size.width * 1.0) + 18 + ((heart.size.width + 5) * j), hudY - 10);
            heart.alpha = 0.1;
            [_hudLifeHeartArrays[i] addObject:heart];
            [hud addChild:heart];
        }
    }
    
    [self addChild:hud];
}

- (void)updateHUDForPlayer:(APAPlayer *)player forState:(APAHUDState)state withMessage:(NSString *)message {
    NSUInteger playerIndex = [self.players indexOfObject:player];
    
    SKSpriteNode *avatar = self.hudAvatars[playerIndex];
    [avatar runAction:[SKAction sequence: @[[SKAction fadeAlphaTo:1.0 duration:1.0], [SKAction fadeAlphaTo:0.2 duration:1.0], [SKAction fadeAlphaTo:1.0 duration:1.0]]]];
    
    SKLabelNode *label = self.hudLabels[playerIndex];
    CGFloat heartAlpha = 1.0;
    switch (state) {
        case APAHUDStateLocal:;
            label.text = @"ME";
            break;
        case APAHUDStateConnecting:
            heartAlpha = 0.25;
            if (message) {
                label.text = message;
            } else {
                label.text = @"AVAILABLE";
            }
            break;
        case APAHUDStateDisconnected:
            avatar.alpha = 0.5;
            heartAlpha = 0.1;
            label.text = @"NO PLAYER";
            break;
        case APAHUDStateConnected:
            if (message) {
                label.text = message;
            } else {
                label.text = @"CONNECTED";
            }
            break;
    }
    
    for (int i = 0; i < player.livesLeft; i++) {
        SKSpriteNode *heart = self.hudLifeHeartArrays[playerIndex][i];
        heart.alpha = heartAlpha;
    }
}

- (void)updateHUDForPlayer:(APAPlayer *)player {
    NSUInteger playerIndex = [self.players indexOfObject:player];
    SKLabelNode *label = self.hudScores[playerIndex];
    label.text = [NSString stringWithFormat:@"SCORE: %d", player.score];
}

- (void)updateHUDAfterHeroDeathForPlayer:(APAPlayer *)player {
    NSUInteger playerIndex = [self.players indexOfObject:player];
    
    // Fade out the relevant heart - one-based livesLeft has already been decremented.
    NSUInteger heartNumber = player.livesLeft;
    
    NSArray *heartArray = self.hudLifeHeartArrays[playerIndex];
    SKSpriteNode *heart = heartArray[heartNumber];
    [heart runAction:[SKAction fadeAlphaTo:0.0 duration:3.0f]];
}

- (void)addToScore:(uint32_t)amount afterEnemyKillWithProjectile:(SKNode *)projectile {
    APAPlayer *player = projectile.userData[kPlayer];
    
    player.score += amount;
    
    [self updateHUDForPlayer:player];
}

#pragma mark - Mapping
- (void)centerWorldOnPosition:(CGPoint)position {
    [self.world setPosition:CGPointMake(-(position.x) + CGRectGetMidX(self.frame),
                                        -(position.y) + CGRectGetMidY(self.frame))];
    
    self.worldMovedForUpdate = YES;
}

- (void)centerWorldOnCharacter:(APACharacter *)character {
    [self centerWorldOnPosition:character.position];
}


- (float)distanceToWall:(CGPoint)pos0 from:(CGPoint)pos1 {
    return 0.0f;
}

- (BOOL)canSee:(CGPoint)pos0 from:(CGPoint)pos1 {
    return NO;
}

#pragma mark - Loop Update
- (void)update:(NSTimeInterval)currentTime {
    // Handle time delta.
    // If we drop below 60fps, we still want everything to move the same distance.
    CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
    self.lastUpdateTimeInterval = currentTime;
    if (timeSinceLast > 1) { // more than a second since last update
        timeSinceLast = kMinTimeInterval;
        self.lastUpdateTimeInterval = currentTime;
        self.worldMovedForUpdate = YES;
    }
    
    [self updateWithTimeSinceLastUpdate:timeSinceLast];
    
#if TARGET_OS_IPHONE
    APAPlayer *defaultPlayer = self.defaultPlayer;
    APAHeroCharacter *hero = nil;
    if ([self.heroes count] > 0) {
        hero = defaultPlayer.hero;
    }
    
    if (![hero isDying]) {
        if (!CGPointEqualToPoint(defaultPlayer.targetLocation, CGPointZero)) {
            if (defaultPlayer.fireAction) {
                [hero faceTo:defaultPlayer.targetLocation];
            }
            
            if (defaultPlayer.moveRequested) {
                if (!CGPointEqualToPoint(defaultPlayer.targetLocation, hero.position)) {
                    [hero moveTowards:defaultPlayer.targetLocation withTimeInterval:timeSinceLast];
                } else {
                    defaultPlayer.moveRequested = NO;
                }
            }
        }
    }
#endif
    
    for (APAPlayer *player in self.players) {
        if ((id)player == [NSNull null]) {
            continue;
        }
        
        APAHeroCharacter *hero = player.hero;
        if (!hero || [hero isDying]) {
            continue;
        }
        
        // heroMoveDirection is used by game controllers.
        CGPoint heroMoveDirection = player.heroMoveDirection;
        if (hypotf(heroMoveDirection.x, heroMoveDirection.y) > 0.0f) {
            [hero moveInDirection:heroMoveDirection withTimeInterval:timeSinceLast];
        }
        else {
            if (player.moveForward) {
                [hero move:APAMoveDirectionForward withTimeInterval:timeSinceLast];
            } else if (player.moveBack) {
                [hero move:APAMoveDirectionBack withTimeInterval:timeSinceLast];
            }
            
            if (player.moveLeft) {
                [hero move:APAMoveDirectionLeft withTimeInterval:timeSinceLast];
            } else if (player.moveRight) {
                [hero move:APAMoveDirectionRight withTimeInterval:timeSinceLast];
            }
        }
        
        if (player.fireAction) {
            [hero performAttackAction];
        }
    }
}

- (void)updateWithTimeSinceLastUpdate:(NSTimeInterval)timeSinceLast {
    // Overridden by subclasses.
}

- (void)didSimulatePhysics {
    APAHeroCharacter *defaultHero = self.defaultPlayer.hero;
    
    // Move the world relative to the default player position.
    if (defaultHero) {
        CGPoint heroPosition = defaultHero.position;
        CGPoint worldPos = self.world.position;
        CGFloat yCoordinate = worldPos.y + heroPosition.y;
        if (yCoordinate < kMinHeroToEdgeDistance) {
            worldPos.y = worldPos.y - yCoordinate + kMinHeroToEdgeDistance;
            self.worldMovedForUpdate = YES;
        } else if (yCoordinate > (self.frame.size.height - kMinHeroToEdgeDistance)) {
            worldPos.y = worldPos.y + (self.frame.size.height - yCoordinate) - kMinHeroToEdgeDistance;
            self.worldMovedForUpdate = YES;
        }
        
        CGFloat xCoordinate = worldPos.x + heroPosition.x;
        if (xCoordinate < kMinHeroToEdgeDistance) {
            worldPos.x = worldPos.x - xCoordinate + kMinHeroToEdgeDistance;
            self.worldMovedForUpdate = YES;
        } else if (xCoordinate > (self.frame.size.width - kMinHeroToEdgeDistance)) {
            worldPos.x = worldPos.x + (self.frame.size.width - xCoordinate) - kMinHeroToEdgeDistance;
            self.worldMovedForUpdate = YES;
        }
        self.world.position = worldPos;
    }
    
    // Using performSelector:withObject:afterDelay: withg a delay of 0.0 means that the selector call occurs after
    // the current pass through the run loop.
    // This means the property will be cleared after the subclass implementation of didSimluatePhysics completes.
    [self performSelector:@selector(clearWorldMoved) withObject:nil afterDelay:0.0f];
}

- (void)clearWorldMoved {
    self.worldMovedForUpdate = NO;
}

#if TARGET_OS_IPHONE
#pragma mark - Event Handling - iOS
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSArray *heroes = self.heroes;
    if ([heroes count] < 1) {
        return;
    }
    UITouch *touch = [touches anyObject];
    
    APAPlayer *defaultPlayer = self.defaultPlayer;
    if (defaultPlayer.movementTouch) {
        return;
    }
    
    defaultPlayer.targetLocation = [touch locationInNode:defaultPlayer.hero.parent];
    
    BOOL wantsAttack = NO;
    NSArray *nodes = [self nodesAtPoint:[touch locationInNode:self]];
    for (SKNode *node in nodes) {
        if (node.physicsBody.categoryBitMask & (APAColliderTypeCave | APAColliderTypeGoblinOrBoss)) {
            wantsAttack = YES;
        }
    }
    
    defaultPlayer.fireAction = wantsAttack;
    defaultPlayer.moveRequested = !wantsAttack;
    defaultPlayer.movementTouch = touch;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    NSArray *heroes = self.heroes;
    if ([heroes count] < 1) {
        return;
    }
    APAPlayer *defaultPlayer = self.defaultPlayer;
    UITouch *touch = defaultPlayer.movementTouch;
    if ([touches containsObject:touch]) {
        defaultPlayer.targetLocation = [touch locationInNode:defaultPlayer.hero.parent];
        if (!defaultPlayer.fireAction) {
            defaultPlayer.moveRequested = YES;
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    NSArray *heroes = self.heroes;
    if ([heroes count] < 1) {
        return;
    }
    APAPlayer *defaultPlayer = self.defaultPlayer;
    UITouch *touch = defaultPlayer.movementTouch;
    
    if ([touches containsObject:touch]) {
        defaultPlayer.movementTouch = nil;
        defaultPlayer.fireAction = NO;
    }
}
#else

#pragma mark - Event Handling - OS X
- (void)handleKeyEvent:(NSEvent *)event keyDown:(BOOL)downOrUp {
    // First check the arrow keys since they are on the numeric keypad.
    if ([event modifierFlags] & NSNumericPadKeyMask) { // arrow keys have this mask
        NSString *theArrow = [event charactersIgnoringModifiers];
        unichar keyChar = 0;
        if ([theArrow length] == 1) {
            keyChar = [theArrow characterAtIndex:0];
            switch (keyChar) {
                case NSUpArrowFunctionKey:
                    self.defaultPlayer.moveForward = downOrUp;
                    break;
                case NSLeftArrowFunctionKey:
                    self.defaultPlayer.moveLeft = downOrUp;
                    break;
                case NSRightArrowFunctionKey:
                    self.defaultPlayer.moveRight = downOrUp;
                    break;
                case NSDownArrowFunctionKey:
                    self.defaultPlayer.moveBack = downOrUp;
                    break;
            }
        }
    }
    
    // Now check the rest of the keyboard
    NSString *characters = [event characters];
    for (int s = 0; s<[characters length]; s++) {
        unichar character = [characters characterAtIndex:s];
        switch (character) {
            case 'w':
                self.defaultPlayer.moveForward = downOrUp;
                break;
            case 'a':
                self.defaultPlayer.moveLeft = downOrUp;
                break;
            case 'd':
                self.defaultPlayer.moveRight = downOrUp;
                break;
            case 's':
                self.defaultPlayer.moveBack = downOrUp;
                break;
            case ' ':
                self.defaultPlayer.fireAction = downOrUp;
                break;
        }
    }
}

- (void)keyDown:(NSEvent *)event {
    [self handleKeyEvent:event keyDown:YES];
}

- (void)keyUp:(NSEvent *)event {
    [self handleKeyEvent:event keyDown:NO];
}
#endif

#pragma mark - Game Controllers
- (void)configureGameControllers {
    // Receive notifications when a controller connects or disconnects.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameControllerDidConnect:) name:GCControllerDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameControllerDidDisconnect:) name:GCControllerDidDisconnectNotification object:nil];
    
    // Configure all the currently connected game controllers.
    [self configureConnectedGameControllers];
    
    // And start looking for any wireless controllers.
    [GCController startWirelessControllerDiscoveryWithCompletionHandler:^{
        NSLog(@"Finished finding controllers");
    }];
}

- (void)configureConnectedGameControllers {
    // First deal with the controllers previously set to a player.
    for (GCController *controller in [GCController controllers]) {
        NSInteger playerIndex = controller.playerIndex;
        if (playerIndex == GCControllerPlayerIndexUnset) {
            continue;
        }
        
        [self assignPresetController:controller toIndex:playerIndex];
    }
    
    // Now deal with the unset controllers.
    for (GCController *controller in [GCController controllers]) {
        NSInteger playerIndex = controller.playerIndex;
        if (playerIndex != GCControllerPlayerIndexUnset) {
            continue;
        }
        
        [self assignUnknownController:controller];
    }
}

- (void)gameControllerDidConnect:(NSNotification *)notification {
    GCController *controller = notification.object;
    NSLog(@"Connected game controller: %@", controller);
    
    NSInteger playerIndex = controller.playerIndex;
    if (playerIndex == GCControllerPlayerIndexUnset) {
        [self assignUnknownController:controller];
    } else {
        [self assignPresetController:controller toIndex:playerIndex];
    }
}

- (void)gameControllerDidDisconnect:(NSNotification *)notification {
    GCController *controller = notification.object;
    for (APAPlayer *player in self.players) {
        if ((id)player == [NSNull null]) {
            continue;
        }
    
        if (player.controller == controller) {
            player.controller = nil;
        }
    }
    
    NSLog(@"Disconnected game controller: %@", controller);
}

- (void)assignUnknownController:(GCController *)controller {
    for (int playerIndex = 0; playerIndex < kNumPlayers; playerIndex++) {
        APAPlayer *player = self.players[playerIndex];
        
        if ((id)player == [NSNull null]) {
            player = [[APAPlayer alloc] init];
            [(NSMutableArray *)self.players replaceObjectAtIndex:playerIndex withObject:player];
            [self updateHUDForPlayer:player forState:APAHUDStateConnected withMessage:@"CONTROLLER"];
        }
        
        if (player.controller) {
            continue;
        }
        
        // Found an unlinked player.
        controller.playerIndex = playerIndex;
        [self configureController:controller forPlayer:player];
        return;
    }
}

- (void)assignPresetController:(GCController *)controller toIndex:(NSInteger)playerIndex {
    // Check whether this index is free.
    APAPlayer *player = self.players[playerIndex];
    if ((id)player == [NSNull null]) {
        player = [[APAPlayer alloc] init];
        [(NSMutableArray *)self.players replaceObjectAtIndex:playerIndex withObject:player];
        [self updateHUDForPlayer:player forState:APAHUDStateConnected withMessage:@"CONTROLLER"];
    }
    
    if (player.controller && player.controller != controller) {
        // Taken by another controller so reassign to another player.
        [self assignUnknownController:controller];
        return; 
    }
    
    [self configureController:controller forPlayer:player];
}

- (void)configureController:(GCController *)controller forPlayer:(APAPlayer *)player {
    NSLog(@"Assigning %@ to player %@ [%lu]", controller.vendorName, player, (unsigned long)[self.players indexOfObject:player]);
  
    // Assign the controller to the player.
    player.controller = controller;
    
    GCControllerDirectionPadValueChangedHandler dpadMoveHandler = ^(GCControllerDirectionPad *dpad, float xValue, float yValue) {
        float length = hypotf(xValue, yValue);
        if (length > 0.0f) {
            float invLength = 1.0f / length;
            player.heroMoveDirection = CGPointMake(xValue * invLength, yValue * invLength);
        } else {
            player.heroMoveDirection = CGPointZero;
        }
    };

    // Use either the dpad or the left thumbstick to move the character.
    controller.extendedGamepad.leftThumbstick.valueChangedHandler = dpadMoveHandler;
    controller.gamepad.dpad.valueChangedHandler = dpadMoveHandler;
    
    GCControllerButtonValueChangedHandler fireButtonHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        player.fireAction = pressed;
    };
    
    controller.gamepad.buttonA.valueChangedHandler = fireButtonHandler;
    controller.gamepad.buttonB.valueChangedHandler = fireButtonHandler;
  
    if (player != self.defaultPlayer && !player.hero) {
        [self addHeroForPlayer:player];
    }
}

#pragma mark - Shared Assets
+ (void)loadSceneAssetsWithCompletionHandler:(APAAssetLoadCompletionHandler)handler {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // Load the shared assets in the background.
        [self loadSceneAssets];
        
        if (!handler) {
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Call the completion handler back on the main queue.
            handler();
        });
    });
}

+ (void)loadSceneAssets {
    // Overridden by subclasses.
}

+ (void)releaseSceneAssets {
    // Overridden by subclasses.
}

- (SKEmitterNode *)sharedSpawnEmitter {
    // Overridden by subclasses.
    return nil;
}

@end
