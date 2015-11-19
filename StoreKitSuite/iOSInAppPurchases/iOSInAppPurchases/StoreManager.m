/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Retrieves product information from the App Store using SKRequestDelegate,
         SKProductsRequestDelegate,SKProductsResponse, and SKProductsRequest.
         Notifies its observer with a list of products available for sale along with
         a list of invalid product identifiers. Logs an error message if the product 
         request failed.
 */


#import "MyModel.h"
#import "StoreManager.h"

NSString * const IAPProductRequestNotification = @"IAPProductRequestNotification";

@interface StoreManager()<SKRequestDelegate, SKProductsRequestDelegate>
@end


@implementation StoreManager

+ (StoreManager *)sharedInstance
{
    static dispatch_once_t onceToken;
    static StoreManager * storeManagerSharedInstance;
    
    dispatch_once(&onceToken, ^{
        storeManagerSharedInstance = [[StoreManager alloc] init];
    });
    return storeManagerSharedInstance;
}


- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _availableProducts = [[NSMutableArray alloc] initWithCapacity:0];
        _invalidProductIds = [[NSMutableArray alloc] initWithCapacity:0];
        _productRequestResponse = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}


#pragma mark Request information

// Fetch information about your products from the App Store
-(void)fetchProductInformationForIds:(NSArray *)productIds
{
    self.productRequestResponse = [[NSMutableArray alloc] initWithCapacity:0];
    // Create a product request object and initialize it with our product identifiers
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:productIds]];
    request.delegate = self;
    
    // Send the request to the App Store
    [request start];
}


#pragma mark - SKProductsRequestDelegate

// Used to get the App Store's response to your request and notifies your observer
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    MyModel *model = nil;
    
    // The products array contains products whose identifiers have been recognized by the App Store.
    // As such, they can be purchased. Create an "AVAILABLE PRODUCTS" model object.
    if ((response.products).count > 0)
    {
        model = [[MyModel alloc] initWithName:@"AVAILABLE PRODUCTS" elements:response.products];
        [self.productRequestResponse addObject:model];
        self.availableProducts = [NSMutableArray arrayWithArray:response.products];
    }
    
    // The invalidProductIdentifiers array contains all product identifiers not recognized by the App Store.
    // Create an "INVALID PRODUCT IDS" model object.
    if ((response.invalidProductIdentifiers).count > 0)
    {
        model = [[MyModel alloc] initWithName:@"INVALID PRODUCT IDS" elements:response.invalidProductIdentifiers];
        [self.productRequestResponse addObject:model];
    }
    
    self.status = IAPProductRequestResponse;
    [[NSNotificationCenter defaultCenter] postNotificationName:IAPProductRequestNotification object:self];
}


#pragma mark SKRequestDelegate method

// Called when the product request failed.
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    // Prints the cause of the product request failure
    NSLog(@"Product Request Status: %@",error.localizedDescription);
}


#pragma mark Helper method

// Return the product's title matching a given product identifier
-(NSString *)titleMatchingProductIdentifier:(NSString *)identifier
{
    NSString *productTitle = nil;
    // Iterate through availableProducts to find the product whose productIdentifier
    // property matches identifier, return its localized title when found
    for (SKProduct *product in self.availableProducts)
    {
        if ([product.productIdentifier isEqualToString:identifier])
        {
            productTitle = product.localizedTitle;
        }
    }
    return productTitle;
}

@end
