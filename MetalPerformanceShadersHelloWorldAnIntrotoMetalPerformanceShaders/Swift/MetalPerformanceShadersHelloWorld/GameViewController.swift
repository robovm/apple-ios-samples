/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Contains the applications main view controller, GameViewController.
*/

import UIKit
import MetalKit
import MetalPerformanceShaders

class GameViewController: UIViewController, MTKViewDelegate {
    // MARK: Properties
    
    // Used to access View
    var metalView: MTKView!
    
    // Used to access Metal.
    var commandQueue: MTLCommandQueue!
    
    // Used to access MetalPerformanceShaders.
    var sourceTexture: MTLTexture!
    
    // Label telling the user their device isn't supported by MetalPerformanceShaders.
    @IBOutlet var metalPerformanceShadersDisabledLabel: UILabel!
    
    // MARK: View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load any resources required for rendering.
        metalView = view as? MTKView
        
        // Load default device.
        metalView.device = MTLCreateSystemDefaultDevice()
        
        // Make sure the current device supports MetalPerformanceShaders.
        guard let metalView = view as? MTKView where MPSSupportsMTLDevice(metalView.device) else { return }
        
        // Hide the label telling the user their device isn't supported by MetalPerformanceShaders.
        metalPerformanceShadersDisabledLabel.hidden = true
        
        // Setup view properties.
        metalView.delegate = self
        metalView.depthStencilPixelFormat = .Depth32Float_Stencil8
        
        // Set up pixel format as your input/output texture.
        metalView.colorPixelFormat = .BGRA8Unorm
        
        // Allow to access to `currentDrawable.texture` write mode.
        metalView.framebufferOnly = false
        
        loadAssets()
    }
    
    func loadAssets() {
        // Create new command queue.
        commandQueue = metalView.device!.newCommandQueue()
        
        // Load image into source texture for MetalPerformanceShaders.
        let textureLoader = MTKTextureLoader(device: metalView.device!)
        let url = NSBundle.mainBundle().URLForResource("AnimalImage", withExtension: "png")!

        do {
            sourceTexture = try textureLoader.newTextureWithContentsOfURL(url, options: [:])
        }
        catch let error as NSError {
            fatalError("Unexpected error ocurred: \(error.localizedDescription).")
        }
    }
    
    // MARK: MTKViewDelegate
    
    func drawInMTKView(view: MTKView) {
        // Get command buffer to use in MetalPerformanceShaders.
        let commandBuffer = commandQueue.commandBuffer()
        
        // Initialize MetalPerformanceShaders gaussianBlur with Sigma = 10.0f.
        let gaussianblur = MPSImageGaussianBlur(device: view.device!, sigma: 10.0)
        
        // Run MetalPerformanceShader `gaussianBlur`.
        gaussianblur.encodeToCommandBuffer(commandBuffer, sourceTexture: sourceTexture, destinationTexture: view.currentDrawable!.texture)
        
        // Finish `commandBuffer`.
        commandBuffer.presentDrawable(view.currentDrawable!)
        commandBuffer.commit()
    }
    
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize)
    {
        // No op.
    }    
}
