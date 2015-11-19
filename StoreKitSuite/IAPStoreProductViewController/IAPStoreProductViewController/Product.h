/*
 
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Model class to represent an iTunes item.
 
*/

@interface Product : NSObject
// Products are organized by category
@property (nonatomic, copy) NSString *category;
// Title of the product
@property (nonatomic, copy) NSString *title;
// iTunes identifier of the product
@property (nonatomic, copy) NSString *productID;
// App Analytics campagin token
@property (nonatomic, copy) NSString *campaignToken;
// App Analytics provider token
@property (nonatomic, copy) NSString *providerToken;

-(instancetype)initWithCategory: (NSString *)category title:(NSString *)title productIdentifier:(NSString *)productID campaignToken:(NSString *)campaignToken providerToken:(NSString *)providerToken NS_DESIGNATED_INITIALIZER;

@end
