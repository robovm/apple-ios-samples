/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Model class to represent an iTunes item.
*/


#import "Product.h"

@implementation Product

-(instancetype)initWithCategory: (NSString *)category title:(NSString *)title productIdentifier:(NSString *)productID
{
    self = [super init];
    if(self != nil)
    {
        _category = category;
        _title = title;
        _productID = productID;
    }
    return self;
}

@end
