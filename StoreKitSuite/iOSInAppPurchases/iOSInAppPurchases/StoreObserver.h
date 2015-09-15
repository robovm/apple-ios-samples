/*
 
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Implements the SKPaymentTransactionObserver protocol. Handles purchasing and restoring products
         as well as downloading hosted content using paymentQueue:updatedTransactions: and paymentQueue:updatedDownloads:,
         respectively. Provides download progress information using SKDownload's progres. Logs the location of the downloaded
         file using SKDownload's contentURL property.
 
*/


extern NSString * const IAPPurchaseNotification;

@interface StoreObserver : NSObject <SKPaymentTransactionObserver>

typedef NS_ENUM(NSInteger, IAPPurchaseNotificationStatus)
{
    IAPPurchaseFailed, // Indicates that the purchase was unsuccessful
    IAPPurchaseSucceeded, // Indicates that the purchase was successful
    IAPRestoredFailed, // Indicates that restoring products was unsuccessful
    IAPRestoredSucceeded, // Indicates that restoring products was successful
    IAPDownloadStarted, // Indicates that downloading a hosted content has started
    IAPDownloadInProgress, // Indicates that a hosted content is currently being downloaded
    IAPDownloadFailed,  // Indicates that downloading a hosted content failed
    IAPDownloadSucceeded // Indicates that a hosted content was successfully downloaded
};

@property (nonatomic) IAPPurchaseNotificationStatus status;

// Keep track of all purchases
@property (nonatomic, strong) NSMutableArray *productsPurchased;
// Keep track of all restored purchases
@property (nonatomic, strong) NSMutableArray *productsRestored;

@property (nonatomic, copy) NSString *message;

@property(nonatomic) float downloadProgress;
// Keep track of the purchased/restored product's identifier
@property (nonatomic, copy) NSString *purchasedID;


-(BOOL)hasPurchasedProducts;
-(BOOL)hasRestoredProducts;

+ (StoreObserver *)sharedInstance;
// Implement the purchase of a product
-(void)buy:(SKProduct *)product;
// Implement the restoration of previously completed purchases
-(void)restore;

@end
