/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Handles keyboard (OS X), touch (iOS) and controller (iOS, tvOS) input for controlling the game.
*/

import simd
import SceneKit
import GameController

#if os(OSX)
    
protocol KeyboardAndMouseEventsDelegate {
    func mouseDown(view: NSView, theEvent: NSEvent) -> Bool
    func mouseDragged(view: NSView, theEvent: NSEvent) -> Bool
    func mouseUp(view: NSView, theEvent: NSEvent) -> Bool
    func keyDown(view: NSView, theEvent: NSEvent) -> Bool
    func keyUp(view: NSView, theEvent: NSEvent) -> Bool
}
    
private enum KeyboardDirection : UInt16 {
    case Left   = 123
    case Right  = 124
    case Down   = 125
    case Up     = 126
    
    var vector : float2 {
        switch self {
        case .Up:    return float2( 0, -1)
        case .Down:  return float2( 0,  1)
        case .Left:  return float2(-1,  0)
        case .Right: return float2( 1,  0)
        }
    }
}
    
extension GameViewController: KeyboardAndMouseEventsDelegate {
}
    
#endif

extension GameViewController {

    // MARK: Controller orientation
    
    private static let controllerAcceleration = Float(1.0 / 10.0)
    private static let controllerDirectionLimit = float2(1.0)
    
    internal func controllerDirection() -> float2 {
        // Poll when using a game controller
        if let dpad = controllerDPad {
            if dpad.xAxis.value == 0.0 && dpad.yAxis.value == 0.0 {
                controllerStoredDirection = float2(0.0)
            } else {
                controllerStoredDirection = clamp(controllerStoredDirection + float2(dpad.xAxis.value, -dpad.yAxis.value) * GameViewController.controllerAcceleration, min: -GameViewController.controllerDirectionLimit, max: GameViewController.controllerDirectionLimit)
            }
        }
        
        return controllerStoredDirection
    }
    
    // MARK: Game Controller Events
    
    internal func setupGameControllers() {
        #if os(OSX)
        gameView.eventsDelegate = self
        #endif
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleControllerDidConnectNotification:", name: GCControllerDidConnectNotification, object: nil)
    }
    
    @objc func handleControllerDidConnectNotification(notification: NSNotification) {
        let gameController = notification.object as! GCController
        registerCharacterMovementEvents(gameController)
    }
    
    private func registerCharacterMovementEvents(gameController: GCController) {
        
        // An analog movement handler for D-pads and thumbsticks.
        let movementHandler: GCControllerDirectionPadValueChangedHandler = { [unowned self] dpad, _, _ in
            self.controllerDPad = dpad
        }
        
        #if os(tvOS)
            
        // Apple TV remote
        if let microGamepad = gameController.microGamepad {
            // Allow the gamepad to handle transposing D-pad values when rotating the controller.
            microGamepad.allowsRotation = true
            microGamepad.dpad.valueChangedHandler = movementHandler
        }
            
        #endif
        
        // Gamepad D-pad
        if let gamepad = gameController.gamepad {
            gamepad.dpad.valueChangedHandler = movementHandler
        }
        
        // Extended gamepad left thumbstick
        if let extendedGamepad = gameController.extendedGamepad {
            extendedGamepad.leftThumbstick.valueChangedHandler = movementHandler
        }
    }
    
    // MARK: Touch Events
    
    #if os(iOS)
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            if CGRectContainsPoint(gameView.virtualDPadBounds(), touch.locationInView(gameView)) {
                // We're in the dpad
                if padTouch == nil {
                    padTouch = touch
                    controllerStoredDirection = float2(0.0)
                }
            } else if panningTouch == nil {
                // Start panning
                panningTouch = touches.first
            }
            
            if padTouch != nil && panningTouch != nil {
                break // We already have what we need
            }
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = panningTouch {
            let displacement = (float2(touch.locationInView(view)) - float2(touch.previousLocationInView(view)))
            panCamera(displacement)
        }
        
        if let touch = padTouch {
            let displacement = (float2(touch.locationInView(view)) - float2(touch.previousLocationInView(view)))
            controllerStoredDirection = clamp(mix(controllerStoredDirection, displacement, t: GameViewController.controllerAcceleration), min: -GameViewController.controllerDirectionLimit, max: GameViewController.controllerDirectionLimit)
        }
    }
    
    func commonTouchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = panningTouch {
            if touches.contains(touch) {
                panningTouch = nil
            }
        }
        
        if let touch = padTouch {
            if touches.contains(touch) || event?.touchesForView(view)?.contains(touch) == false {
                padTouch = nil
                controllerStoredDirection = float2(0.0)
            }
        }
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        commonTouchesEnded(touches!, withEvent: event)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        commonTouchesEnded(touches, withEvent: event)
    }
    
    #endif
    
    // MARK: Mouse and Keyboard Events
    
    #if os(OSX)
    
    func mouseDown(view: NSView, theEvent: NSEvent) -> Bool {
        // Remember last mouse position for dragging.
        lastMousePosition = float2(view.convertPoint(theEvent.locationInWindow, fromView: nil))
        
        return true
    }
    
    func mouseDragged(view: NSView, theEvent: NSEvent) -> Bool {
        let mousePosition = float2(view.convertPoint(theEvent.locationInWindow, fromView: nil))
        panCamera(mousePosition - lastMousePosition)
        lastMousePosition = mousePosition
        
        return true
    }
    
    func mouseUp(view: NSView, theEvent: NSEvent) -> Bool {
        return true
    }
    
    func keyDown(view: NSView, theEvent: NSEvent) -> Bool {
        if let direction = KeyboardDirection(rawValue: theEvent.keyCode) {
            if !theEvent.ARepeat {
                controllerStoredDirection += direction.vector
            }
            return true
        }
        
        return false
    }
    
    func keyUp(view: NSView, theEvent: NSEvent) -> Bool {
        if let direction = KeyboardDirection(rawValue: theEvent.keyCode) {
            if !theEvent.ARepeat {
                controllerStoredDirection -= direction.vector
            }
            return true
        }
        
        return false
    }
    
    #endif
}
