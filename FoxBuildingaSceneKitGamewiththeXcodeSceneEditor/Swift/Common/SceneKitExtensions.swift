/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

*/

import SceneKit
import SpriteKit

// MARK: SceneKit

extension SCNTransaction {
    class func animateWithDuration(duration: CFTimeInterval = 0.25, timingFunction: CAMediaTimingFunction? = nil, completionBlock: (() -> Void)? = nil, animations: () -> Void) {
        begin()
        setAnimationDuration(duration)
        setCompletionBlock(completionBlock)
        setAnimationTimingFunction(timingFunction)
        animations()
        commit()
    }
}

extension SCNNode {
    var boundingBox: (min: SCNVector3, max: SCNVector3) {
        get {
            var min = SCNVector3(0, 0, 0)
            var max = SCNVector3(0, 0, 0)
            getBoundingBoxMin(&min, max: &max)
            return (min, max)
        }
    }
}

extension SCNPhysicsContact {
    func match(category category: Int, block: (matching: SCNNode, other: SCNNode) -> Void) {
        if self.nodeA.physicsBody!.categoryBitMask == category {
            block(matching: self.nodeA, other: self.nodeB)
        }
  
        if self.nodeB.physicsBody!.categoryBitMask == category {
            block(matching: self.nodeB, other: self.nodeA)
        }
    }
}

extension SCNAudioSource {
    convenience init(name: String, volume: Float = 1.0, positional: Bool = true, loops: Bool = false, shouldStream: Bool = false, shouldLoad: Bool = true) {
        self.init(named: "game.scnassets/sounds/\(name)")!
        self.volume = volume
        self.positional = positional
        self.loops = loops
        self.shouldStream = shouldStream
        if shouldLoad {
            load()
        }
    }
}

// MARK: SpriteKit

extension SKSpriteNode {
    convenience init(imageNamed name: String, position: CGPoint, scale: CGFloat = 1.0) {
        self.init(imageNamed: name)
        self.position = position
        xScale = scale
        yScale = scale
    }
}

// MARK: Simd

extension float2 {
    init(_ v: CGPoint) {
        self.init(Float(v.x), Float(v.y))
    }
}

// MARK: CoreAnimation

extension CAAnimation {
    class func animationWithSceneNamed(name: String) -> CAAnimation? {
        var animation: CAAnimation?
        if let scene = SCNScene(named: name) {
            scene.rootNode.enumerateChildNodesUsingBlock({ (child, stop) in
                if child.animationKeys.count > 0 {
                    animation = child.animationForKey(child.animationKeys.first!)
                    stop.initialize(true)
                }
            })
        }
        return animation
    }
}
