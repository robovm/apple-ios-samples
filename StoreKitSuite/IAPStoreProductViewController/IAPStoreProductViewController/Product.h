/*
 
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Model class to represent an iTunes item.
 
*/


#import <Foundation/Foundation.h>

@interface Product : NSObject
// Products are organized by category
@property (nonatomic, copy) NSString *category;
// Title of the product
@property (nonatomic, copy) NSString *title;
// iTunes identifier of the product
@property (nonatomic, copy) NSString *productID;

-(instancetype)initWithCategory: (NSString *)category title:(NSString *)title productIdentifier:(NSString *)productID NS_DESIGNATED_INITIALIZER;

@end
