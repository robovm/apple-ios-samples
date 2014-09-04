/*
     File: ViewController.m
 Abstract: A view controller with different views for portrait and landscape
 orientations.
 
  Version: 1.3
 
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
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import "ViewController.h"
#import "PortraitView.h"
#import "LandscapeView.h"

@interface ViewController ()
//! The view to use while in portrait orientation.  This property is configured
//! to be strong because the view it references may not always be in the view
//! hierarchy.
@property (nonatomic, strong) IBOutlet PortraitView *portraitView;
//! The view to use while in landscape orientation.  This property is configured
//! to be strong because the view it references may not always be in the view
//! hierarchy.
@property (nonatomic, strong) IBOutlet LandscapeView *landscapeView;
@end


@implementation ViewController
{
    //! Holds a snapshot of the outgoing view used duration rotation,
    //! to smooth out the transition animation.
    __weak UIView *_rotationSnapshotView;
}


//| ----------------------------------------------------------------------------
//  Our view only serves as a container for the orientation-specific views.
//  If you remove this method, subviews added to the view for this view
//  controller's scene in the storyboard will be visible in both orientations.
//
- (void)loadView
{
    self.view = [[UIView alloc] init];
}


//| ----------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Display the correct view for the current interface orientation.
    // This is done here instead of in -viewDidLoad because the value of
    // interfaceOrientation is not final when -viewDidLoad called.
    {
        UIView *viewForCurrentInterfaceOrientation = [self viewForInterfaceOrientation:self.interfaceOrientation];
        
        if (viewForCurrentInterfaceOrientation.superview == nil)
        {
            [self.portraitView removeFromSuperview];
            [self.landscapeView removeFromSuperview];
            
            [self.view addSubview:viewForCurrentInterfaceOrientation];
            [self.view sendSubviewToBack:viewForCurrentInterfaceOrientation];
        }
    }
    
    // If you've created separate UIView subclasses for your portrait and
    // landscape interfaces, then you should perform and orientation specific
    // setup in the -willMoveToSuperview: method of each respective subclass
    // instead of here.
}


//| ----------------------------------------------------------------------------
- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    // Match the orientation-specific view's frame to our view's frame.
    // It's easier to update both here instead of checking which one is
    // actually in use at the current time.
    self.portraitView.frame = self.view.bounds;
    self.landscapeView.frame = self.view.bounds;
    
    // Forward the current values of  self.topLayoutGuide and
    // self.bottomLayoutGuide to the orientation-specific views.
    // (See the comments in LayoutSupport.h for more information)
    // It's easier to update both here instead of checking which one is
    // actually in use at the current time.
    if ([self respondsToSelector:@selector(topLayoutGuide)])
    {
        self.portraitView.topLayoutGuideLength = self.topLayoutGuide.length;
        self.landscapeView.topLayoutGuideLength = self.topLayoutGuide.length;
        self.portraitView.bottomLayoutGuideLength = self.bottomLayoutGuide.length;
        self.landscapeView.bottomLayoutGuideLength = self.bottomLayoutGuide.length;
    }
    // iOS 6 does not have topLayoutGuide and bottomLayoutGuide.
    else
    {
        self.portraitView.topLayoutGuideLength = 0;
        self.landscapeView.topLayoutGuideLength = 0;
        self.portraitView.bottomLayoutGuideLength = 0;
        self.landscapeView.bottomLayoutGuideLength = 0;
    }
    
}

#pragma mark -
#pragma mark Rotation

//| ----------------------------------------------------------------------------
//  This method is called before
//      a) The system configures transaction to animate the rotation (changes
//         made here won't be animated)
//      b) The system resizes the window's root view for the new orientation.
//
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    UIView *viewForCurrentInterfaceOrientation = [self viewForInterfaceOrientation:self.interfaceOrientation];
    UIView *viewForFinalInterfaceOrientation = [self viewForInterfaceOrientation:toInterfaceOrientation];
    
    // Ignore rotating from Landscape-Left to Landscape-Right or vis-versa.
    if (viewForCurrentInterfaceOrientation != viewForFinalInterfaceOrientation)
    {
        // Don't let an orientation-specific view ever be resized for the
        // orientation it does not support.  Instead, a snapshot of the
        // outgoing view is swapped in before the rotation animation
        // begins.  The snapshot will be stretched (or squished) to match our
        // view's changing frame .
        UIView *rotationSnapshotView;
        if ([viewForCurrentInterfaceOrientation respondsToSelector:@selector(snapshotViewAfterScreenUpdates:)])
        // iOS 7
        {
            rotationSnapshotView = [viewForCurrentInterfaceOrientation snapshotViewAfterScreenUpdates:NO];
        }
        else
        // iOS 6
        {
            UIGraphicsBeginImageContextWithOptions(viewForCurrentInterfaceOrientation.bounds.size, YES, viewForCurrentInterfaceOrientation.layer.contentsScale);
            [[viewForCurrentInterfaceOrientation layer] renderInContext:UIGraphicsGetCurrentContext()];
            UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            rotationSnapshotView = [[UIImageView alloc] initWithImage:snapshot];
        }
        
        rotationSnapshotView.frame = viewForCurrentInterfaceOrientation.frame;
        rotationSnapshotView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self.view insertSubview:rotationSnapshotView aboveSubview:viewForCurrentInterfaceOrientation];
        
        // Save the snapshot view so it can be removed when the animation
        // completes.
        _rotationSnapshotView = rotationSnapshotView;
        
        // Now that the sanpshot is in place, remove the outgoing view.
        [viewForCurrentInterfaceOrientation removeFromSuperview];
    }
    
    if (viewForFinalInterfaceOrientation.superview == nil)
    {
        [self.view addSubview:viewForFinalInterfaceOrientation];
        [self.view sendSubviewToBack:viewForFinalInterfaceOrientation];
        
        // We're going to fade the incoming view in.
        viewForFinalInterfaceOrientation.alpha = 0.0f;
    }
}


//| ----------------------------------------------------------------------------
//  By the time this method is called
//      a) The system has opened (but not committed) a transaction to
//         animate the rotation.
//      b) The system has resized the root view from the new orientation.
//      c) -viewWillLayoutSubviews has been called.
//
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    // Snapshot fades out, incoming view fades in.
    // You don't need to setup your own animation transaction here, one
    // has already been setup by the system.
    _rotationSnapshotView.alpha = 0.0f;
    [self viewForInterfaceOrientation:toInterfaceOrientation].alpha = 1.0f;
}


//| ----------------------------------------------------------------------------
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    [_rotationSnapshotView removeFromSuperview];
}

#pragma mark -
#pragma mark Utility

//| ----------------------------------------------------------------------------
//! Lazily loads and returns the view of the give \a interfaceOrientation.
//
- (UIView*)viewForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation))
    {
        // Lazily load landscapeView if necessary.
        if (self.landscapeView == nil)
        {
            // Will automatically load LandscapeView~ipad if run on an iPad.
            UINib *landscapeViewXib = [UINib nibWithNibName:@"LandscapeView" bundle:nil];
            
            // In the LandscapeView xib the "File's Owner" has been set to
            // ViewController and the landscapeView IBOutlet of the file's owner
            // has been connected to the view defined within the xib.  Thus upon
            // instantiation, the unarchived view will be automatically connected
            // to the landscapeView of self.
            [landscapeViewXib instantiateWithOwner:self options:nil];
        }
        
        return self.landscapeView;
    }
    else
    {
        // Lazily load portraitView if necessary.
        if (self.portraitView == nil)
        {
            // Will automatically load PortraitView~ipad if run on an iPad.
            UINib *portraitViewXib = [UINib nibWithNibName:@"PortraitView" bundle:nil];
            
            // In the PortraitView xib the "File's Owner" has been set to
            // ViewController and the portraitView IBOutlet of the file's owner
            // has been connected to the view defined within the xib.  Thus upon
            // instantiation, the unarchived view will be automatically connected
            // to the portraitView of self.
            [portraitViewXib instantiateWithOwner:self options:nil];
        }
        
        return self.portraitView;
    }
        
}

@end
