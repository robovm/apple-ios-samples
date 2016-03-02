/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Handles keyboard (OS X), touch (iOS) and controller (iOS, tvOS) input for controlling the game.
*/

#import "AAPLGameViewControllerPrivate.h"

static CGFloat const AAPLControllerAcceleration = 1.0 / 10.0;
static CGFloat const AAPLControllerDirectionLimit = 1.0;

@implementation AAPLGameViewController (GameControls)
    
#pragma mark - Controller orientation

- (vector_float2)controllerDirection {
    // Poll when using a game controller
    if (_controllerDPad) {
        if (_controllerDPad.xAxis.value == 0.0 && _controllerDPad.yAxis.value == 0.0) {
            _controllerDirection = (vector_float2){0.0, 0.0};
        } else {
            _controllerDirection = vector_clamp(_controllerDirection + (vector_float2){_controllerDPad.xAxis.value, -_controllerDPad.yAxis.value} * AAPLControllerAcceleration, -AAPLControllerDirectionLimit, AAPLControllerDirectionLimit);
        }
    }
    
    return _controllerDirection;
}

#pragma mark -  Game Controller Events

- (void)setupGameControllers {
#if !(TARGET_OS_IOS || TARGET_OS_TV)
    self.gameView.eventsDelegate = self;
#endif
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleControllerDidConnectNotification:) name:GCControllerDidConnectNotification object:nil];
}

- (void)handleControllerDidConnectNotification:(NSNotification *)notification {
    GCController *gameController = notification.object;
    [self registerCharacterMovementEvents:gameController];
}

- (void)registerCharacterMovementEvents:(GCController *)gameController {
    
    // An analog movement handler for D-pads and thumbsticks.
    __weak typeof(self) weakSelf = self;
    GCControllerDirectionPadValueChangedHandler movementHandler = ^(GCControllerDirectionPad *dpad, float xValue, float yValue) {
        typeof(self) strongSelf = weakSelf;
        strongSelf->_controllerDPad = dpad;
    };
    
#if TARGET_OS_TV
    
    // Apple TV remote
    GCMicroGamepad *microGamepad = gameController.microGamepad;
    // Allow the gamepad to handle transposing D-pad values when rotating the controller.
    microGamepad.allowsRotation = YES;
    microGamepad.dpad.valueChangedHandler = movementHandler;
    
#endif
    
    // Gamepad D-pad
    GCGamepad *gamepad = gameController.gamepad;
    gamepad.dpad.valueChangedHandler = movementHandler;
    
    // Extended gamepad left thumbstick
    GCExtendedGamepad *extendedGamepad = gameController.extendedGamepad;
    extendedGamepad.leftThumbstick.valueChangedHandler = movementHandler;
}

#pragma mark - Touch Events

#if TARGET_OS_IOS

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        if (CGRectContainsPoint(self.gameView.virtualDPadBounds, [touch locationInView:self.gameView])) {
            // We're in the dpad
            if (_padTouch == nil) {
                _padTouch = touch;
                _controllerDirection = (vector_float2){0.0, 0.0};
            }
        }
        else if (_panningTouch == nil) {
            // Start panning
            _panningTouch = [touches anyObject];
        }
        
        if (_padTouch && _panningTouch)
            break; // We already have what we need
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_panningTouch) {
        CGPoint p0 = [_panningTouch previousLocationInView:self.view];
        CGPoint p1 = [_panningTouch locationInView:self.view];
        CGPoint displacement = CGPointMake(p1.x - p0.x, p1.y - p0.y);
        [self panCamera:displacement];
    }
    
    if (_padTouch) {
        CGPoint p0 = [_padTouch previousLocationInView:self.view];
        CGPoint p1 = [_padTouch locationInView:self.view];
        vector_float2 displacement = {p1.x - p0.x, p1.y - p0.y};
        _controllerDirection = vector_clamp(vector_mix(_controllerDirection, displacement, AAPLControllerAcceleration), -AAPLControllerDirectionLimit, AAPLControllerDirectionLimit);
    }
}

- (void)commonTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_panningTouch) {
        if ([touches containsObject:_panningTouch]) {
            _panningTouch = nil;
        }
    }
    
    if (_padTouch) {
        if ([touches containsObject:_padTouch] || [[event touchesForView:self.view] containsObject:_padTouch] == NO) {
            _padTouch = nil;
            _controllerDirection = (vector_float2){0.0, 0.0};
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self commonTouchesEnded:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self commonTouchesEnded:touches withEvent:event];
}

#endif

#pragma mark - Mouse and Keyboard Events

#if !(TARGET_OS_IOS || TARGET_OS_TV)

- (BOOL)mouseDown:(NSView *)view event:(NSEvent *)theEvent {
    // Remember last mouse position for dragging.
    _lastMousePosition = [self.view convertPoint:theEvent.locationInWindow fromView:nil];
    return YES;
}

- (BOOL)mouseDragged:(NSView *)view event:(NSEvent *)theEvent {
    CGPoint mousePosition = [self.view convertPoint:theEvent.locationInWindow fromView:nil];
    [self panCamera:CGPointMake(mousePosition.x - _lastMousePosition.x, mousePosition.y - _lastMousePosition.y)];
    _lastMousePosition = mousePosition;
    
    return YES;
}

- (BOOL)mouseUp:(NSView *)view event:(NSEvent *)theEvent {
    return YES;
}

- (BOOL)keyDown:(NSView *)view event:(NSEvent *)theEvent {
    switch (theEvent.keyCode) {
        case 126: // Up
            if (!theEvent.isARepeat) {
                _controllerDirection += (vector_float2){ 0, -1};
            }
            return YES;
        case 125: // Down
            if (!theEvent.isARepeat) {
                _controllerDirection += (vector_float2){ 0,  1};
            }
            return YES;
        case 123: // Left
            if (!theEvent.isARepeat) {
                _controllerDirection += (vector_float2){-1,  0};
            }
            return YES;
        case 124: // Right
            if (!theEvent.isARepeat) {
                _controllerDirection += (vector_float2){ 1,  0};
            }
            return YES;
    }
    
    return NO;
}

- (BOOL)keyUp:(NSView *)view event:(NSEvent *)theEvent {
    switch (theEvent.keyCode) {
        case 126: // Up
            if (!theEvent.isARepeat) {
                _controllerDirection -= (vector_float2){ 0, -1};
            }
            return YES;
        case 125: // Down
            if (!theEvent.isARepeat) {
                _controllerDirection -= (vector_float2){ 0,  1};
            }
            return YES;
        case 123: // Left
            if (!theEvent.isARepeat) {
                _controllerDirection -= (vector_float2){-1,  0};
            }
            return YES;
        case 124: // Right
            if (!theEvent.isARepeat) {
                _controllerDirection -= (vector_float2){ 1,  0};
            }
            return YES;
    }
    
    return NO;
}

#endif

@end
