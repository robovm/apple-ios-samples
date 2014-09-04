/*
     File: PerspectiveMotionEffect.h
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

#import <UIKit/UIKit.h>

@interface PerspectiveMotionEffect : UIMotionEffect

//! Position of the camera along the Z-axis.  Positive values extend twoards
//! the screen.  The point of interest for the virtual camera is fixed
//! at (center.x, center.y, 0) where center is the center point of the
//! view plane.
@property (nonatomic, readwrite) CGFloat cameraPositionZ;

//! Limits how much the camera can orbit around the X-axis.  (Recall that
//! the X-axis is parallel to the screen and extends horizontally).
//! You can therefore think of this value as how far the camera can move
//! up or down while still keeping its point of interest centered in its
//! view.
@property (nonatomic, readwrite) CGFloat maximumViewingAngleX;
//! Limits how much the camera can orbit around the Y-axis.  (Recall that
//! the Y-axis is parallel to the screen and extends vertically).
//! You can therefore think of this value as how far the camera can move
//! to the left or right while still keeping its point of interest centered
//! in its view.
@property (nonatomic, readwrite) CGFloat maximumViewingAngleY;

@end
