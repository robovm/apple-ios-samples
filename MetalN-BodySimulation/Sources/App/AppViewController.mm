/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Application view controller implementing Metal Kit delgates.
 */

#import <cmath>

#import "NBodyVisualizer.h"

#import "AppViewController.h"

@implementation AppViewController
{
@private
    // Default Metal system devive
    id<MTLDevice>  device;
    
    // Metal-Kit view
    MTKView*  mpView;
    
    // N-body simulation visualizer object
    NBodyVisualizer*  mpVisualizer;
}

- (void) _update:(nonnull MTKView *)view
{
    const CGRect bounds = view.bounds;
    const float  aspect = float(std::abs(bounds.size.width / bounds.size.height));
    
    // Set the new aspect ratio for the mvp linear transformation matrix
    mpVisualizer.aspect = aspect;
} // _update

- (void) mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    // Update the mvp linear transformation matrix
    [self _update:view];
} // mtkView

- (void) drawInMTKView:(nonnull MTKView *)view
{
    if(view)
    {
        @autoreleasepool
        {
            [self _update:view];
            
            // Draw the particles from the N-body simulation
            mpVisualizer.drawable = view.currentDrawable;
        }
    } // if
} // drawInMTKView

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
} // didReceiveMemoryWarning

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
} // preferredStatusBarStyle

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Instantiate a new N-body visualizer object
    mpVisualizer = [NBodyVisualizer new];
    assert(mpVisualizer);

    // Acquire all the resources for the visualizer object
    mpVisualizer.device = device;
    
    // If successful in acquiring resources for the visualizer
    // object, then continue
    assert(mpVisualizer.haveVisualizer);
} // viewDidAppear

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    // Acquire a default Metal system device
    device = MTLCreateSystemDefaultDevice();
    
    // If this is a valid system device, then continue
    assert(device);

    // Our view should be a Metal-Kit view
    mpView = static_cast<MTKView *>(self.view);
    
    // If this a valid Metal-kit view, then continue
    assert(mpView);
    
    // Metal-kit view requires a Metal device and an app delegate
    mpView.device   = device;
    mpView.delegate = self;
} // viewDidLoad

@end
