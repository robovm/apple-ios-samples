/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 MetalKit view controller that's setup as the MTKViewDelegate.
 */

#ifdef TARGET_IOS
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#import <MetalKit/MetalKit.h>

#ifdef TARGET_IOS
@interface AAPLMetalKitEssentialsViewController : UIViewController <MTKViewDelegate>
#else
@interface AAPLMetalKitEssentialsViewController : NSViewController <MTKViewDelegate>
#endif

@end