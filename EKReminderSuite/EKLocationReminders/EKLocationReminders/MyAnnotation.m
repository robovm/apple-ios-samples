/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Custom MKAnnotation object representing a generic location.
 */

#import "MyAnnotation.h"

@interface MyAnnotation()
@property (nonatomic,copy) NSString *title;
@property (nonatomic,assign) CLLocationCoordinate2D coordinate;

@end


@implementation MyAnnotation

-(instancetype)init
{
    self = [self initWithTitle:nil latitude:0.0 longitude:0.0 address: nil];
    if (self != nil)
    {
    }
    return self;
}


-(instancetype)initWithTitle:(NSString *)name latitude:(double)latitude longitude:(double)longitude address:(NSString *)address
{
    self = [super init];
    if(self != nil)
    {
        _title = name;
        _coordinate.latitude = latitude;
        _coordinate.longitude = longitude;
        _address = address;
    }
    return self;
}

@end
