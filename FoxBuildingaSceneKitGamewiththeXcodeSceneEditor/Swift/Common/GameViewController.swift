/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This class manages most of the game logic.
*/

import simd
import SceneKit
import SpriteKit
import QuartzCore
import AVFoundation
import GameController

// Collision bit masks
let BitmaskCollision        = 1 << 2
let BitmaskCollectable      = 1 << 3
let BitmaskEnemy            = 1 << 4
let BitmaskSuperCollectable = 1 << 5
let BitmaskWater            = 1 << 6

#if os(iOS) || os(tvOS)
    typealias ViewController = UIViewController
#elseif os(OSX)
    typealias ViewController = NSViewController
#endif

class GameViewController: ViewController, SCNSceneRendererDelegate, SCNPhysicsContactDelegate {
   
    // Game view
    var gameView: GameView {
        return view as! GameView
    }
    
    // Nodes to manipulate the camera
    private let cameraYHandle = SCNNode()
    private let cameraXHandle = SCNNode()
    
    // The character
    private let character = Character()
    
    // Game states
    private var gameIsComplete = false
    private var lockCamera = false
    
    private var grassArea: SCNMaterial!
    private var waterArea: SCNMaterial!
    private var flames = [SCNNode]()
    private var enemies = [SCNNode]()
    
    // Sounds
    private var collectPearlSound: SCNAudioSource!
    private var collectFlowerSound: SCNAudioSource!
    private var flameThrowerSound: SCNAudioPlayer!
    private var victoryMusic: SCNAudioSource!
    
    // Particles
    private var confettiParticleSystem: SCNParticleSystem!
    private var collectFlowerParticleSystem: SCNParticleSystem!
    
    // For automatic camera animation
    private var currentGround: SCNNode!
    private var mainGround: SCNNode!
    private var groundToCameraPosition = [SCNNode: SCNVector3]()
    
    // Game controls
    internal var controllerDPad: GCControllerDirectionPad?
    internal var controllerStoredDirection = float2(0.0) // left/right up/down
    
    #if os(OSX)
    internal var lastMousePosition = float2(0)
    #elseif os(iOS)
    internal var padTouch: UITouch?
    internal var panningTouch: UITouch?
    #endif
    
    // MARK: Initialization
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create a new scene.
        let scene = SCNScene(named: "game.scnassets/level.scn")!
        
        // Set the scene to the view and loop for the animation of the bamboos.
        self.gameView.scene = scene
        self.gameView.playing = true
        self.gameView.loops = true
        
        // Various setup
        setupCamera()
        setupSounds()
        
        // Configure particle systems
        collectFlowerParticleSystem = SCNParticleSystem(named: "collect.scnp", inDirectory: nil)
        collectFlowerParticleSystem.loops = false
        confettiParticleSystem = SCNParticleSystem(named: "confetti.scnp", inDirectory: nil)
        
        // Add the character to the scene.
        scene.rootNode.addChildNode(character.node)
        
        let startPosition = scene.rootNode.childNodeWithName("startingPoint", recursively: true)!
        character.node.transform = startPosition.transform
        
        // Retrieve various game elements in one traversal
        var collisionNodes = [SCNNode]()
        scene.rootNode.enumerateChildNodesUsingBlock { (node, _) in
            switch node.name {
            case .Some("flame"):
                node.physicsBody!.categoryBitMask = BitmaskEnemy
                self.flames.append(node)
            case .Some("enemy"):
                self.enemies.append(node)
            case let .Some(s) where s.rangeOfString("collision") != nil:
                collisionNodes.append(node)
            default:
                break
            }
        }
        
        for node in collisionNodes {
            node.hidden = false
            setupCollisionNode(node)
        }
        
        // Setup delegates
        scene.physicsWorld.contactDelegate = self
        gameView.delegate = self
        
        setupAutomaticCameraPositions()
        setupGameControllers()
    }
    
    // MARK: Managing the Camera
    
    func panCamera(var direction: float2) {
        if lockCamera {
            return
        }
        
        #if os(iOS) || os(tvOS)
            direction *= float2(1.0, -1.0)
        #endif
        
        let F = SCNFloat(0.005)
        
        // Make sure the camera handles are correctly reset (because automatic camera animations may have put the "rotation" in a weird state.
        SCNTransaction.animateWithDuration(0.0) {
            self.cameraYHandle.removeAllActions()
            self.cameraXHandle.removeAllActions()
            
            if self.cameraYHandle.rotation.y < 0 {
                self.cameraYHandle.rotation = SCNVector4(0, 1, 0, -self.cameraYHandle.rotation.w)
            }
            
            if self.cameraXHandle.rotation.x < 0 {
                self.cameraXHandle.rotation = SCNVector4(1, 0, 0, -self.cameraXHandle.rotation.w)
            }
        }
        
        // Update the camera position with some inertia.
        SCNTransaction.animateWithDuration(0.5, timingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)) {
            self.cameraYHandle.rotation = SCNVector4(0, 1, 0, self.cameraYHandle.rotation.y * (self.cameraYHandle.rotation.w - SCNFloat(direction.x) * F))
            self.cameraXHandle.rotation = SCNVector4(1, 0, 0, (max(SCNFloat(-M_PI_2), min(0.13, self.cameraXHandle.rotation.w + SCNFloat(direction.y) * F))))
        }
    }
    
    func updateCameraWithCurrentGround(node: SCNNode) {
        if gameIsComplete {
            return
        }
        
        if currentGround == nil {
            currentGround = node
            return
        }
        
        // Automatically update the position of the camera when we move to another block.
        if node != currentGround {
            currentGround = node
            
            if var position = groundToCameraPosition[node] {
                if node == mainGround && character.node.position.x < 2.5 {
                    position = SCNVector3(-0.098175, 3.926991, 0.0)
                }
                
                let actionY = SCNAction.rotateToX(0, y: CGFloat(position.y), z: 0, duration: 3.0, shortestUnitArc: true)
                actionY.timingMode = SCNActionTimingMode.EaseInEaseOut
                
                let actionX = SCNAction.rotateToX(CGFloat(position.x), y: 0, z: 0, duration: 3.0, shortestUnitArc: true)
                actionX.timingMode = SCNActionTimingMode.EaseInEaseOut
                
                cameraYHandle.runAction(actionY)
                cameraXHandle.runAction(actionX)
            }
        }
    }
    
    // MARK: Moving the Character
    
    private func characterDirection() -> float3 {
        let controllerDirection = self.controllerDirection()
        var direction = float3(controllerDirection.x, 0.0, controllerDirection.y)
        
        if let pov = gameView.pointOfView {
            let p1 = pov.presentationNode.convertPosition(SCNVector3(direction), toNode: nil)
            let p0 = pov.presentationNode.convertPosition(SCNVector3Zero, toNode: nil)
            direction = float3(Float(p1.x - p0.x), 0.0, Float(p1.z - p0.z))
            
            if direction.x != 0.0 || direction.z != 0.0 {
                direction = normalize(direction)
            }
        }
        
        return direction
    }
    
    // MARK: SCNSceneRendererDelegate Conformance (Game Loop)
    
    // SceneKit calls this method exactly once per frame, so long as the SCNView object (or other SCNSceneRenderer object) displaying the scene is not paused.
    // Implement this method to add game logic to the rendering loop. Any changes you make to the scene graph during this method are immediately reflected in the displayed scene.
    
    func groundTypeFromMaterial(material: SCNMaterial) -> GroundType {
        if material == grassArea {
            return .Grass
        }
        if material == waterArea {
            return .Water
        }
        else {
            return .Rock
        }
    }
    
    func renderer(renderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        // Reset some states every frame
        replacementPosition = nil
        maxPenetrationDistance = 0
        
        let scene = gameView.scene!
        let direction = characterDirection()
        
        let groundNode = character.walkInDirection(direction, time: time, scene: scene, groundTypeFromMaterial:groundTypeFromMaterial)
        if let groundNode = groundNode {
            updateCameraWithCurrentGround(groundNode)
        }
        
        // Flames are static physics bodies, but they are moved by an action - So we need to tell the physics engine that the transforms did change.
        for flame in flames {
            flame.physicsBody!.resetTransform()
        }
        
        // Adjust the volume of the enemy based on the distance to the character.
        var distanceToClosestEnemy = Float.infinity
        let characterPosition = float3(character.node.position)
        for enemy in enemies {
            //distance to enemy
            let enemyTransform = float4x4(enemy.worldTransform)
            let enemyPosition = float3(enemyTransform[3].x, enemyTransform[3].y, enemyTransform[3].z)
            let distance = simd.distance(characterPosition, enemyPosition)
            distanceToClosestEnemy = min(distanceToClosestEnemy, distance)
        }
        
        // Adjust sounds volumes based on distance with the enemy.
        if !gameIsComplete {
            if let mixer = flameThrowerSound!.audioNode as? AVAudioMixerNode {
                mixer.volume = 0.3 * max(0, min(1, 1 - ((distanceToClosestEnemy - 1.2) / 1.6)))
            }
        }
    }
    
    func renderer(renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: NSTimeInterval) {
        // If we hit a wall, position needs to be adjusted
        if let position = replacementPosition {
            character.node.position = position
        }
    }
    
    // MARK: SCNPhysicsContactDelegate Conformance
    
    // To receive contact messages, you set the contactDelegate property of an SCNPhysicsWorld object.
    // SceneKit calls your delegate methods when a contact begins, when information about the contact changes, and when the contact ends.
    
    func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact) {
        contact.match(category: BitmaskCollision) { (matching, other) in
            self.characterNode(other, hitWall: matching, withContact: contact)
        }
        contact.match(category: BitmaskCollectable) { (matching, _) in
            self.collectPearl(matching)
        }
        contact.match(category: BitmaskSuperCollectable) { (matching, _) in
            self.collectFlower(matching)
        }
        contact.match(category: BitmaskEnemy) { (_, _) in
            self.character.catchFire()
        }
    }
    
    func physicsWorld(world: SCNPhysicsWorld, didUpdateContact contact: SCNPhysicsContact) {
        contact.match(category: BitmaskCollision) { (matching, other) in
            self.characterNode(other, hitWall: matching, withContact: contact)
        }
    }
    
    private var maxPenetrationDistance = CGFloat(0.0)
    private var replacementPosition: SCNVector3?
    
    private func characterNode(characterNode: SCNNode, hitWall wall: SCNNode, withContact contact: SCNPhysicsContact) {
        if characterNode.parentNode != character.node {
            return
        }
        
        if maxPenetrationDistance > contact.penetrationDistance {
            return
        }
        
        maxPenetrationDistance = contact.penetrationDistance
        
        var characterPosition = float3(character.node.position)
        var positionOffset = float3(contact.contactNormal) * Float(contact.penetrationDistance)
        positionOffset.y = 0
        characterPosition += positionOffset
        
        replacementPosition = SCNVector3(characterPosition)
    }
    
    // MARK: Scene Setup
    
    private func setupCamera() {
        let ALTITUDE = 1.0
        let DISTANCE = 10.0
        
        // We create 2 nodes to manipulate the camera:
        // The first node "cameraXHandle" is at the center of the world (0, ALTITUDE, 0) and will only rotate on the X axis
        // The second node "cameraYHandle" is a child of the first one and will ony rotate on the Y axis
        // The camera node is a child of the "cameraYHandle" at a specific distance (DISTANCE).
        // So rotating cameraYHandle and cameraXHandle will update the camera position and the camera will always look at the center of the scene.
        
        let pov = self.gameView.pointOfView!
        pov.eulerAngles = SCNVector3Zero
        pov.position = SCNVector3(0.0, 0.0, DISTANCE)
        
        cameraXHandle.rotation = SCNVector4(1.0, 0.0, 0.0, -M_PI_4 * 0.125)
        cameraXHandle.addChildNode(pov)
        
        cameraYHandle.position = SCNVector3(0.0, ALTITUDE, 0.0)
        cameraYHandle.rotation = SCNVector4(0.0, 1.0, 0.0, M_PI_2 + M_PI_4 * 3.0)
        cameraYHandle.addChildNode(cameraXHandle)
        
        gameView.scene?.rootNode.addChildNode(cameraYHandle)
        
        // Animate camera on launch and prevent the user from manipulating the camera until the end of the animation.
        SCNTransaction.animateWithDuration(completionBlock: { self.lockCamera = false }) {
            self.lockCamera = true
            
            // Create 2 additive animations that converge to 0
            // That way at the end of the animation, the camera will be at its default position.
            let cameraYAnimation = CABasicAnimation(keyPath: "rotation.w")
            cameraYAnimation.fromValue = SCNFloat(M_PI) * 2.0 - self.cameraYHandle.rotation.w
            cameraYAnimation.toValue = 0.0
            cameraYAnimation.additive = true
            cameraYAnimation.beginTime = CACurrentMediaTime() + 3.0 // wait a little bit before stating
            cameraYAnimation.fillMode = kCAFillModeBoth
            cameraYAnimation.duration = 5.0
            cameraYAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            self.cameraYHandle.addAnimation(cameraYAnimation, forKey: nil)
            
            let cameraXAnimation = cameraYAnimation.copy() as! CABasicAnimation
            cameraXAnimation.fromValue = -SCNFloat(M_PI_2) + self.cameraXHandle.rotation.w
            self.cameraXHandle.addAnimation(cameraXAnimation, forKey: nil)
        }
    }
    
    private func setupAutomaticCameraPositions() {
        let rootNode = gameView.scene!.rootNode
        
        mainGround = rootNode.childNodeWithName("bloc05_collisionMesh_02", recursively: true)
        
        groundToCameraPosition[rootNode.childNodeWithName("bloc04_collisionMesh_02", recursively: true)!] = SCNVector3(-0.188683, 4.719608, 0.0)
        groundToCameraPosition[rootNode.childNodeWithName("bloc03_collisionMesh", recursively: true)!] = SCNVector3(-0.435909, 6.297167, 0.0)
        groundToCameraPosition[rootNode.childNodeWithName("bloc07_collisionMesh", recursively: true)!] = SCNVector3( -0.333663, 7.868592, 0.0)
        groundToCameraPosition[rootNode.childNodeWithName("bloc08_collisionMesh", recursively: true)!] = SCNVector3(-0.575011, 8.739003, 0.0)
        groundToCameraPosition[rootNode.childNodeWithName("bloc06_collisionMesh", recursively: true)!] = SCNVector3( -1.095519, 9.425292, 0.0)
        groundToCameraPosition[rootNode.childNodeWithName("bloc05_collisionMesh_02", recursively: true)!] = SCNVector3(-0.072051, 8.202264, 0.0)
        groundToCameraPosition[rootNode.childNodeWithName("bloc05_collisionMesh_01", recursively: true)!] = SCNVector3(-0.072051, 8.202264, 0.0)
    }
    
    private func setupCollisionNode(node: SCNNode) {
        if let geometry = node.geometry {
            // Collision meshes must use a concave shape for intersection correctness.
            node.physicsBody = SCNPhysicsBody.staticBody()
            node.physicsBody!.categoryBitMask = BitmaskCollision
            node.physicsBody!.physicsShape = SCNPhysicsShape(node: node, options: [SCNPhysicsShapeTypeKey: SCNPhysicsShapeTypeConcavePolyhedron])
            
            // Get grass area to play the right sound steps
            if geometry.firstMaterial!.name == "grass-area" {
                if grassArea != nil {
                    geometry.firstMaterial = grassArea
                } else {
                    grassArea = geometry.firstMaterial
                }
            }
            
            // Get the water area
            if geometry.firstMaterial!.name == "water" {
                waterArea = geometry.firstMaterial
            }
            
            // Temporary workaround because concave shape created from geometry instead of node fails
            let childNode = SCNNode()
            node.addChildNode(childNode)
            childNode.hidden = true
            childNode.geometry = node.geometry
            node.geometry = nil
            node.hidden = false
            
            if node.name == "water" {
                node.physicsBody!.categoryBitMask = BitmaskWater
            }
        }
        
        for childNode in node.childNodes {
            if childNode.hidden == false {
                setupCollisionNode(childNode)
            }
        }
    }
    
    private func setupSounds() {
        // Get an arbitrary node to attach the sounds to.
        let node = self.gameView.scene!.rootNode
        
        node.addAudioPlayer(SCNAudioPlayer(source: SCNAudioSource(name: "music.m4a", volume: 0.25, positional: false, loops: true, shouldStream: true)))
        node.addAudioPlayer(SCNAudioPlayer(source: SCNAudioSource(name: "wind.m4a", volume: 0.3, positional: false, loops: true, shouldStream: true)))
        flameThrowerSound = SCNAudioPlayer(source: SCNAudioSource(name: "flamethrower.mp3", volume: 0, positional: false, loops: true))
        node.addAudioPlayer(flameThrowerSound)
        
        collectPearlSound = SCNAudioSource(name: "collect1.mp3", volume: 0.5)
        collectFlowerSound = SCNAudioSource(name: "collect2.mp3")
        victoryMusic = SCNAudioSource(name: "Music_victory.mp3", volume: 0.5, shouldLoad: false)
    }
    
    // MARK: Collecting Items
    
    private func removeNode(node: SCNNode, soundToPlay sound: SCNAudioSource) {
        if let parentNode = node.parentNode {
            let soundEmitter = SCNNode()
            soundEmitter.position = node.position
            parentNode.addChildNode(soundEmitter)
            
            soundEmitter.runAction(SCNAction.sequence([
                SCNAction.playAudioSource(sound, waitForCompletion: true),
                SCNAction.removeFromParentNode()]))
            
            node.removeFromParentNode()
        }
    }
    
    private var collectedPearlsCount = 0 {
        didSet {
            gameView.collectedPearlsCount = collectedPearlsCount
        }
    }
    
    private func collectPearl(pearlNode: SCNNode) {
        if pearlNode.parentNode != nil {
            removeNode(pearlNode, soundToPlay:collectPearlSound)
            collectedPearlsCount++
        }
    }
    
    private var collectedFlowersCount = 0 {
        didSet {
            gameView.collectedFlowersCount = collectedFlowersCount
            if (collectedFlowersCount == 3) {
                showEndScreen()
            }
        }
    }
    
    private func collectFlower(flowerNode: SCNNode) {
        if flowerNode.parentNode != nil {
            // Emit particles.
            var particleSystemPosition = flowerNode.worldTransform
            particleSystemPosition.m42 += 0.1
            gameView.scene!.addParticleSystem(collectFlowerParticleSystem, withTransform: particleSystemPosition)
            
            // Remove the flower from the scene.
            removeNode(flowerNode, soundToPlay:collectFlowerSound)
            collectedFlowersCount++
        }
    }
    
    // MARK: Congratulating the Player
    
    private func showEndScreen() {
        gameIsComplete = true
        
        // Add confettis
        let particleSystemPosition = SCNMatrix4MakeTranslation(0.0, 8.0, 0.0)
        gameView.scene!.addParticleSystem(confettiParticleSystem, withTransform: particleSystemPosition)
        
        // Stop the music.
        gameView.scene!.rootNode.removeAllAudioPlayers()
        
        // Play the congrat sound.
        gameView.scene!.rootNode.addAudioPlayer(SCNAudioPlayer(source: victoryMusic))
        
        // Animate the camera forever
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            self.cameraYHandle.runAction(SCNAction.repeatActionForever(SCNAction.rotateByX(0, y:-1, z: 0, duration: 3)))
            self.cameraXHandle.runAction(SCNAction.rotateToX(CGFloat(-M_PI_4), y: 0, z: 0, duration: 5.0))
        }
        
        gameView.showEndScreen();
    }
    
}
