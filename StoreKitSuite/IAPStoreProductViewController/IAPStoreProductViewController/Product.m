/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Model class to represent an iTunes item.
*/


#import "Product.h"

@implementation Product

-(instancetype)init
{
    self = [self initWithCategory:nil title:nil productIdentifier:nil campaignToken:nil providerToken:nil];
    if (self != nil)
    {
        
    }
    return self;
}

-(instancetype)initWithCategory: (NSString *)category title:(NSString *)title productIdentifier:(NSString *)productID campaignToken:(NSString *) campaignToken providerToken:(NSString *) providerToken
{
    self = [super init];
    if(self != nil)
    {
        _category = [category copy];
        _title = [title copy];
        _productID = [productID copy];
        _campaignToken = [campaignToken copy];
        _providerToken = [providerToken copy];
    }
    return self;
}

@end
