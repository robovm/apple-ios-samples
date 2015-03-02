/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Image Filter Objects
  
 */

#import <Foundation/Foundation.h>

@interface AAPLImageFilter : NSObject <UIStateRestoring>

- (instancetype)initFilter:(BOOL)useDefaultState NS_DESIGNATED_INITIALIZER;

@property (nonatomic) BOOL active;
@property (nonatomic) BOOL dirty;
@property (nonatomic, readwrite, strong) id<UIStateRestoring> restorationParent;
@property (nonatomic, readwrite, strong) Class<UIObjectRestoration> objectRestorationClass;
@end

#pragma mark -

#define kBlurFilterKey @"BlurFilter"

@interface BlurFilter : AAPLImageFilter
@property (nonatomic) CGFloat blurRadius;
@end

#pragma mark -

#define kModifyFilterKey @"ModifyFilter"

@interface ModifyFilter : AAPLImageFilter
@property (nonatomic) CGFloat intensity;

@end
