/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The model object that represents an individual photo.
 */

#import "AAPLPhoto.h"

@implementation AAPLPhoto

+ (instancetype)photoWithDictionary:(NSDictionary *)dictionary
{
    AAPLPhoto *photo = [[self alloc] init];
    photo.imageName = dictionary[@"imageName"];
    photo.comment = dictionary[@"comment"];
    photo.rating = [dictionary[@"rating"] integerValue];
    return photo;
}

//  Custom implementation of the getter for the image property. The image property is a derived property. The image corresponding to self.imageName is loaded upon request.
//  Note that if you had to load the image over a network, you should instead define a method that takes a completion block, which is called when the image has been downloaded. See the LazyTableImages sample for an example.
//  https://developer.apple.com/library/ios/samplecode/LazyTableImages/Introduction/Intro.html
- (UIImage *)image
{
    return [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:self.imageName ofType:@"jpg"]];
}

@end
