/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Model class to represent a product/purchase.
 */


#import "MyModel.h"


@implementation MyModel

-(instancetype)initWithName:(NSString *)name elements:(NSArray *)elements
{
    self = [super init];
    if(self != nil)
    {
        _name = name;
        _elements = elements;
    }
    return self;
}

@end
