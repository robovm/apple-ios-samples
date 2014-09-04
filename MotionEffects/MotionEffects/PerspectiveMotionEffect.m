/*
     File: PerspectiveMotionEffect.m
 Abstract: Subclass of UIMotionEffect that simulates a camera which orbits
 around a specific point of interest as the reported viewer offset changes.
 
  Version: 1.0
 
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

#import "PerspectiveMotionEffect.h"

@implementation PerspectiveMotionEffect

//| ----------------------------------------------------------------------------
//  This is the only method declared by UIMotionEffect and the only method that
//  subclasses of UIMotionEffect must override.  Your implementation must return
//  an NSDictionary containing key paths (relative to an instance of UIView) and
//  the amount by which to change the current value of the property.  Values
//  returned are added to (or in the case of a matrix, multiplied with) the
//  existing value at the corresponding key path of any view to which the
//  motion effect has been applied.
//
//  Remember, instances of UIMotionEffect should be stateless.  An instance of
//  UIMotionEffect knows nothing about the views it has been applied to.  Your
//  subclass should not attempt to break from this design.
//
- (NSDictionary*)keyPathsAndRelativeValuesForViewerOffset:(UIOffset)viewerOffset
{    
    CATransform3D transform = CATransform3DIdentity;
    
    transform.m34 = -1.0/1500;
    transform = CATransform3DTranslate(transform, 0, 0, -1504);
    
    // Transform the viewer offset using the function y=x^(2/3).  This makes
    // the effect more noticable at slight deviations from the center. (Try
    // plotting the function in the Grapher app on your Mac to see the
    // exact curve.)
    viewerOffset.horizontal = ((viewerOffset.horizontal < 0) ? -1 : 1) * powf(fabsf(viewerOffset.horizontal), 2.0/3.0);
    viewerOffset.vertical = ((viewerOffset.vertical < 0) ? -1 : 1) * powf(fabsf(viewerOffset.vertical), 2.0/3.0);
    
    // Gimble Lock is not an issue here because we are only rotating around
    // two axis at most.
    transform = CATransform3DRotate(transform, self.maximumViewingAngleX * viewerOffset.vertical, 1, 0, 0);
    transform = CATransform3DRotate(transform, self.maximumViewingAngleY * viewerOffset.horizontal, 0, 1, 0);
    
    return @{@"layer.sublayerTransform": [NSValue valueWithCATransform3D:transform]};
}

@end
