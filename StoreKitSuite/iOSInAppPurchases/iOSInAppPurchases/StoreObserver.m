/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Implements the SKPaymentTransactionObserver protocol. Handles purchasing and restoring products
         as well as downloading hosted content using paymentQueue:updatedTransactions: and paymentQueue:updatedDownloads:,
         respectively. Provides download progress information using SKDownload's progres. Logs the location of the downloaded
         file using SKDownload's contentURL property.
 */


#import "StoreObserver.h"

NSString * const IAPPurchaseNotification = @"IAPPurchaseNotification";


@implementation StoreObserver

+ (StoreObserver *)sharedInstance
{
    static dispatch_once_t onceToken;
    static StoreObserver * storeObserverSharedInstance;
    
    dispatch_once(&onceToken, ^{
        storeObserverSharedInstance = [[StoreObserver alloc] init];
    });
    return storeObserverSharedInstance;
}


- (instancetype)init
{
	self = [super init];
	if (self != nil)
    {
        _productsPurchased = [[NSMutableArray alloc] initWithCapacity:0];
        _productsRestored = [[NSMutableArray alloc] initWithCapacity:0];
    }
	return self;
}


#pragma mark -
#pragma mark Make a purchase

// Create and add a payment request to the payment queue
-(void)buy:(SKProduct *)product
{
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
	[[SKPaymentQueue defaultQueue] addPayment:payment];
}


#pragma mark -
#pragma mark Has purchased products

// Returns whether there are purchased products
-(BOOL)hasPurchasedProducts
{
    // productsPurchased keeps track of all our purchases.
    // Returns YES if it contains some items and NO, otherwise
     return (self.productsPurchased.count > 0);
}


#pragma mark -
#pragma mark Has restored products

// Returns whether there are restored purchases
-(BOOL)hasRestoredProducts
{
    // productsRestored keeps track of all our restored purchases.
    // Returns YES if it contains some items and NO, otherwise
    return (self.productsRestored.count > 0);
}


#pragma mark -
#pragma mark Restore purchases

-(void)restore
{
    self.productsRestored = [[NSMutableArray alloc] initWithCapacity:0];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}


#pragma mark -
#pragma mark SKPaymentTransactionObserver methods

// Called when there are trasactions in the payment queue
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
	for(SKPaymentTransaction * transaction in transactions)
	{
		switch (transaction.transactionState )
		{
			case SKPaymentTransactionStatePurchasing:
				break;
                
            case SKPaymentTransactionStateDeferred:
                // Do not block your UI. Allow the user to continue using your app.
                NSLog(@"Allow the user to continue using your app.");
                break;
            // The purchase was successful
			case SKPaymentTransactionStatePurchased:
            {
                self.purchasedID = transaction.payment.productIdentifier;
                [self.productsPurchased addObject:transaction];
                
                NSLog(@"Deliver content for %@",transaction.payment.productIdentifier);
                // Check whether the purchased product has content hosted with Apple.
                if(transaction.downloads && transaction.downloads.count > 0)
                {
                    [self completeTransaction:transaction forStatus:IAPDownloadStarted];
                }
                else
                {
                    [self completeTransaction:transaction forStatus:IAPPurchaseSucceeded];
                }
            }
                break;
            // There are restored products
            case SKPaymentTransactionStateRestored:
            {
                self.purchasedID = transaction.payment.productIdentifier;
                [self.productsRestored addObject:transaction];
                
                NSLog(@"Restore content for %@",transaction.payment.productIdentifier);
                // Send a IAPDownloadStarted notification if it has
                if(transaction.downloads && transaction.downloads.count > 0)
                {
                    [self completeTransaction:transaction forStatus:IAPDownloadStarted];
                }
                else
                {
                   [self completeTransaction:transaction forStatus:IAPRestoredSucceeded];
                }
            }
				break;
            // The transaction failed
			case SKPaymentTransactionStateFailed:
            {
                self.message = [NSString stringWithFormat:@"Purchase of %@ failed.",transaction.payment.productIdentifier];
                [self completeTransaction:transaction forStatus:IAPPurchaseFailed];
            }
            break;
			default:
                break;
		}
	}
}


// Called when the payment queue has downloaded content
- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray *)downloads
{
    for (SKDownload* download in downloads)
    {
        switch (download.downloadState)
        {
            // The content is being downloaded. Let's provide a download progress to the user
            case SKDownloadStateActive:
            {
                self.status = IAPDownloadInProgress;
                self.purchasedID = download.transaction.payment.productIdentifier;
                self.downloadProgress = download.progress*100;
                [[NSNotificationCenter defaultCenter] postNotificationName:IAPPurchaseNotification object:self];
            }
                break;
                
            case SKDownloadStateCancelled:
                // StoreKit saves your downloaded content in the Caches directory. Let's remove it
                // before finishing the transaction.
                [[NSFileManager defaultManager] removeItemAtURL:download.contentURL error:nil];
                [self finishDownloadTransaction:download.transaction];
                break;
                
            case SKDownloadStateFailed:
                // If a download fails, remove it from the Caches, then finish the transaction.
                // It is recommended to retry downloading the content in this case.
                [[NSFileManager defaultManager] removeItemAtURL:download.contentURL error:nil];
                [self finishDownloadTransaction:download.transaction];
                break;
                
            case SKDownloadStatePaused:
                NSLog(@"Download was paused");
                break;
                
            case SKDownloadStateFinished:
                // Download is complete. StoreKit saves the downloaded content in the Caches directory.
                NSLog(@"Location of downloaded file %@",download.contentURL);
                [self finishDownloadTransaction:download.transaction];
                break;
                
            case SKDownloadStateWaiting:
                NSLog(@"Download Waiting");
                [[SKPaymentQueue defaultQueue] startDownloads:@[download]];
                break;
                
            default:
                break;
        }
    }
}


// Logs all transactions that have been removed from the payment queue
- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
	for(SKPaymentTransaction * transaction in transactions)
	{
		NSLog(@"%@ was removed from the payment queue.", transaction.payment.productIdentifier);
	}
}


// Called when an error occur while restoring purchases. Notify the user about the error.
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    if (error.code != SKErrorPaymentCancelled)
    {
        self.status = IAPRestoredFailed;
        self.message = error.localizedDescription;
        [[NSNotificationCenter defaultCenter] postNotificationName:IAPPurchaseNotification object:self];
    }
}


// Called when all restorable transactions have been processed by the payment queue
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSLog(@"All restorable transactions have been processed by the payment queue.");
}


#pragma mark -
#pragma mark Complete transaction

// Notify the user about the purchase process. Start the download process if status is
// IAPDownloadStarted. Finish all transactions, otherwise.
-(void)completeTransaction:(SKPaymentTransaction *)transaction forStatus:(NSInteger)status
{
    self.status = status;
    //Do not send any notifications when the user cancels the purchase
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        // Notify the user
        [[NSNotificationCenter defaultCenter] postNotificationName:IAPPurchaseNotification object:self];
    }
    
    if (status == IAPDownloadStarted)
    {
        // The purchased product is a hosted one, let's download its content
        [[SKPaymentQueue defaultQueue] startDownloads:transaction.downloads];
    }
    else
    {
        // Remove the transaction from the queue for purchased and restored statuses
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }
}


#pragma mark -
#pragma mark - Handle download transaction

- (void)finishDownloadTransaction:(SKPaymentTransaction*)transaction
{
    //allAssetsDownloaded indicates whether all content associated with the transaction were downloaded.
    BOOL allAssetsDownloaded = YES;
    
    // A download is complete if its state is SKDownloadStateCancelled, SKDownloadStateFailed, or SKDownloadStateFinished
    // and pending, otherwise. We finish a transaction if and only if all its associated downloads are complete.
    // For the SKDownloadStateFailed case, it is recommended to try downloading the content again before finishing the transaction.
    for (SKDownload* download in transaction.downloads)
    {
        if (download.downloadState != SKDownloadStateCancelled &&
            download.downloadState != SKDownloadStateFailed &&
            download.downloadState != SKDownloadStateFinished )
        {
            //Let's break. We found an ongoing download. Therefore, there are still pending downloads.
            allAssetsDownloaded = NO;
            break;
        }
    }
    
    // Finish the transaction and post a IAPDownloadSucceeded notification if all downloads are complete
    if (allAssetsDownloaded)
    {
        self.status = IAPDownloadSucceeded;
        
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        [[NSNotificationCenter defaultCenter] postNotificationName:IAPPurchaseNotification object:self];
        
        if ([self.productsRestored containsObject:transaction])
        {
            self.status = IAPRestoredSucceeded;
            [[NSNotificationCenter defaultCenter] postNotificationName:IAPPurchaseNotification object:self];
        }

    }
}

@end
