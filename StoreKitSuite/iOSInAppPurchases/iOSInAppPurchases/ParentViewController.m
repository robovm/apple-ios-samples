/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Manages the child view controllers: iOSProductsList and iOSPurchasesList.
         Displays a Restore button that allows you to restore all previously purchased
         non-consumable and auto-renewable subscription products. Request product information
         about a list of product identifiers using StoreManager. Calls StoreObserver to implement
         the restoration of purchases.
 */


#import "MyModel.h"
#import "StoreManager.h"
#import "StoreObserver.h"
#import "iOSProductsList.h"
#import "iOSPurchasesList.h"
#import "ParentViewController.h"


@interface ParentViewController ()
// Indicate that there are restored products
@property BOOL restoreWasCalled;

// Indicate whether a download is in progress
@property (nonatomic)BOOL hasDownloadContent;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (nonatomic, strong) iOSProductsList *productsList;
@property (nonatomic, strong) iOSPurchasesList *purchasesList;

@property (weak, nonatomic) IBOutlet UILabel *statusMessage;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

// Keep track of the current selected view controller
@property (nonatomic, strong) UIViewController *currentViewController;

@end


@implementation ParentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.hasDownloadContent = NO;
    self.restoreWasCalled = NO;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleProductRequestNotification:)
                                                 name:IAPProductRequestNotification
                                               object:[StoreManager sharedInstance]];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlePurchasesNotification:)
                                                 name:IAPPurchaseNotification
                                               object:[StoreObserver sharedInstance]];
    
    
    // Get the storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iOSInAppPurchases" bundle:nil];
    
    // Fetch the iOSProductsList and iOSPurchasesList view controllers from our storyboard
    self.productsList = [storyboard instantiateViewControllerWithIdentifier:@"iOSProductsListID"];
    self.purchasesList = [storyboard instantiateViewControllerWithIdentifier:@"iOSPurchasesListID"];
    
    // Fetch information about our products from the App Store
    [self fetchProductInformation];
    
    // iOSProductsList is the default child view controller
    [self cycleFromViewController:nil toViewController:self.productsList];
}


- (void)viewDidLayoutSubviews
{
    CGRect contentFrame = self.containerView.frame;
    CGRect messageFrame = self.statusMessage.frame;
    
    // Add the status message to the UI if a download is in progress.
    // Remove it when the download is done
    if (self.hasDownloadContent)
    {
        messageFrame = CGRectMake(contentFrame.origin.x, contentFrame.origin.y, contentFrame.size.width, 44);
        contentFrame.size.height -= messageFrame.size.height;
        contentFrame.origin.y += messageFrame.size.height;
    }
    else
    {
        contentFrame = self.view.frame;
        // We need to account for the navigation bar
        contentFrame.origin.y = 64;
        contentFrame.size.height -=contentFrame.origin.y;
        messageFrame.origin.y = self.view.frame.size.height;
    }
    
    self.containerView.frame = contentFrame;
    self.statusMessage.frame = messageFrame;
}


// Called when the status message was removed. Force the view to update its layout.
-(void)hideStatusMessage
{
    [self.view setNeedsLayout];
}


#pragma mark Display message

-(void)alertWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark Fetch product information

// Retrieve product information from the App Store
-(void)fetchProductInformation
{
    // Query the App Store for product information if the user is is allowed to make purchases.
    // Display an alert, otherwise.
    if([SKPaymentQueue canMakePayments])
    {
        // Load the product identifiers fron ProductIds.plist
        NSURL *plistURL = [[NSBundle mainBundle] URLForResource:@"ProductIds" withExtension:@"plist"];
        NSArray *productIds = [NSArray arrayWithContentsOfURL:plistURL];
        
        [[StoreManager sharedInstance] fetchProductInformationForIds:productIds];
    }
    else
    {
        // Warn the user that they are not allowed to make purchases.
        [self alertWithTitle:@"Warning" message:@"Purchases are disabled on this device."];
    }
}


#pragma mark Handle product request notification

// Update the UI according to the product request notification result
-(void)handleProductRequestNotification:(NSNotification *)notification
{
    StoreManager *productRequestNotification = (StoreManager*)[notification object];
    IAPProductRequestStatus result = (IAPProductRequestStatus)productRequestNotification.status;
    
    if (result == IAPProductRequestResponse)
    {
        // Switch to the iOSProductsList view controller and display its view
        [self cycleFromViewController:self.currentViewController toViewController:self.productsList];
        
        // Set the data source for the Products view
        [self.productsList reloadUIWithData:productRequestNotification.productRequestResponse];
    }
}


#pragma mark Handle purchase request notification

// Update the UI according to the purchase request notification result
-(void)handlePurchasesNotification:(NSNotification *)notification
{
    StoreObserver *purchasesNotification = (StoreObserver *)[notification object];
    IAPPurchaseNotificationStatus status = (IAPPurchaseNotificationStatus)purchasesNotification.status;
    
    switch (status)
    {
        case IAPPurchaseFailed:
            [self alertWithTitle:@"Purchase Status" message:purchasesNotification.message];
            break;
            // Switch to the iOSPurchasesList view controller when receiving a successful restore notification
        case IAPRestoredSucceeded:
        {
            self.segmentedControl.selectedSegmentIndex = 1;
            self.restoreWasCalled = YES;
            
            [self cycleFromViewController:self.currentViewController toViewController:self.purchasesList];
            [self.purchasesList reloadUIWithData:[self dataSourceForPurchasesUI]];
        }
            break;
        case IAPRestoredFailed:
            [self alertWithTitle:@"Purchase Status" message:purchasesNotification.message];
            break;
            // Notify the user that downloading is about to start when receiving a download started notification
        case IAPDownloadStarted:
        {
            self.hasDownloadContent = YES;
            [self.view addSubview:self.statusMessage];
        }
            break;
            // Display a status message showing the download progress
        case IAPDownloadInProgress:
        {
            self.hasDownloadContent = YES;
            NSString *title = [[StoreManager sharedInstance] titleMatchingProductIdentifier:purchasesNotification.purchasedID];
            NSString *displayedTitle = (title.length > 0) ? title : purchasesNotification.purchasedID;
            self.statusMessage.text = [NSString stringWithFormat:@" Downloading %@   %.2f%%",displayedTitle, purchasesNotification.downloadProgress];
        }
            break;
            // Downloading is done, remove the status message
        case IAPDownloadSucceeded:
        {
            self.hasDownloadContent = NO;
            self.statusMessage.text = @"Download complete: 100%";
            
            // Remove the message after 2 seconds
            [self performSelector:@selector(hideStatusMessage) withObject:nil afterDelay:2];
        }
            break;
        default:
            break;
    }
}


#pragma mark Toggle between view controllers

// Transition from the old view controller to the new one
-(void)cycleFromViewController:(UIViewController *)oldViewController toViewController:(UIViewController *)newViewController
{
    assert(newViewController != nil);
    
    if (oldViewController != nil)
    {
        [oldViewController willMoveToParentViewController:nil];
        [oldViewController.view removeFromSuperview];
        [oldViewController removeFromParentViewController];
    }
    
    [self addChildViewController:newViewController];
    
    CGRect frame = newViewController.view.frame;
    frame.size.height = CGRectGetHeight(self.containerView.frame);
    frame.size.width = CGRectGetWidth(self.containerView.frame);
    newViewController.view.frame = frame;
    
    [self.containerView addSubview:newViewController.view];
    [newViewController didMoveToParentViewController:self];
    
    self.currentViewController = newViewController;
}


// Return an array that will be used to populate the Purchases view
-(NSMutableArray *)dataSourceForPurchasesUI
{
    NSMutableArray *dataSource = [[NSMutableArray alloc] initWithCapacity:0];
    
    if (self.restoreWasCalled && [[StoreObserver sharedInstance] hasRestoredProducts] && [[StoreObserver sharedInstance] hasPurchasedProducts])
    {
        dataSource = [[NSMutableArray alloc] initWithObjects:[[MyModel alloc] initWithName:@"PURCHASED" elements:[StoreObserver sharedInstance].productsPurchased],
                                                             [[MyModel alloc] initWithName:@"RESTORED" elements:[StoreObserver sharedInstance].productsRestored],nil];
    }
    else if (self.restoreWasCalled && [[StoreObserver sharedInstance] hasRestoredProducts])
    {
        dataSource = [[NSMutableArray alloc] initWithObjects:[[MyModel alloc] initWithName:@"RESTORED" elements:[StoreObserver sharedInstance].productsRestored], nil];
    }
    else if ([[StoreObserver sharedInstance] hasPurchasedProducts])
    {
        dataSource = [[NSMutableArray alloc] initWithObjects:[[MyModel alloc] initWithName:@"PURCHASED" elements:[StoreObserver sharedInstance].productsPurchased], nil];
    }
    
    // Only want to display restored products when the Restore button was tapped and there are restored products
    self.restoreWasCalled = NO;
    return dataSource;
}


#pragma mark Handle segmented control tap

// Called when a user taps on the segmented control
- (IBAction)segmentValueChanged:(id)sender
{
    UISegmentedControl *segmentControl = (UISegmentedControl *)sender;
    
    // Return productsList if the user tapped Products in the segmented control and purchasesList, otherwise
    switch (segmentControl.selectedSegmentIndex)
    {
        case 0:
            // Toggle from the current view controller to the Products view
            [self cycleFromViewController:self.currentViewController toViewController:self.productsList];
            break;
        case 1:
            // Toggle from the current view controller to the Purchases view
            [self cycleFromViewController:self.currentViewController toViewController:self.purchasesList];
            
            // Reload the purchase list
            [self.purchasesList reloadUIWithData:[self dataSourceForPurchasesUI]];
            break;
        default:
            break;
    }

}


#pragma mark Restore all appropriate transactions

- (IBAction)restore:(id)sender
{
    // Call StoreObserver to restore all restorable purchases
    [[StoreObserver sharedInstance] restore];
}


#pragma mark Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)dealloc
{
    // Unregister for StoreManager's notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IAPProductRequestNotification
                                                  object:[StoreManager sharedInstance]];
    
    // Unregister for StoreObserver's notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IAPPurchaseNotification
                                                  object:[StoreObserver sharedInstance]];
}

@end
