/*
 
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Custom MKAnnotation object representing a generic location.
 
 */

@interface MyAnnotation : NSObject <MKAnnotation>
@property(nonatomic, copy) NSString *address;
-(instancetype)initWithTitle:(NSString *)name latitude:(double)latitude longitude:(double)longitude address:(NSString *)address NS_DESIGNATED_INITIALIZER;

@end