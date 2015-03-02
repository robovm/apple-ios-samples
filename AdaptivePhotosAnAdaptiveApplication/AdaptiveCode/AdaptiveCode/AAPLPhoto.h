/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The model object that represents an individual photo.
 */

@import UIKit;

@interface AAPLPhoto : NSObject

+ (instancetype)photoWithDictionary:(NSDictionary *)dictionary;

@property (readonly, nonatomic) UIImage *image;
@property (copy, nonatomic) NSString *imageName;

@property (copy, nonatomic) NSString *comment;
@property (nonatomic) NSInteger rating;

@end
