/*
     File: ParentViewController.m
 Abstract: Manages the child view controllers: iOSProductsList and iOSPurchasesList.
           Displays a Restore button that allows you to restore all previously purchased
           non-consumable and auto-renewable subscription products.
           Calls StoreObserver to implement the restoration of purchases.
 
  Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
*/

#import "MyModel.h"
#import "StoreManager.h"
#import "StoreObserver.h"
#import "iOSProductsList.h"
#import "iOSPurchasesList.h"
#import "ParentViewController.h"

@interface ParentViewController ()
// Indicate whether a download is in progress
@property (nonatomic)BOOL hasDownloadContent;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (nonatomic, strong) iOSProductsList *productsList;
@property (nonatomic, strong) iOSPurchasesList *purchasesList;

@property (weak, nonatomic) IBOutlet UILabel *statusMessage;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@end

@implementation ParentViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.hasDownloadContent = NO;
  
    // Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlePurchasesNotification:)
                                                 name:IAPPurchaseNotification
                                               object:[StoreObserver sharedInstance]];
    
    
    // Get the storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iOSInAppPurchases" bundle:nil];
   
    // Fetch the iOSProductsList and iOSPurchasesList view controllers from our storyboard
    self.productsList = [storyboard instantiateViewControllerWithIdentifier:@"iOSProductsListID"];
    self.purchasesList = [storyboard instantiateViewControllerWithIdentifier:@"iOSPurchasesListID"];
    
    // Add iOSProductsList and iOSPurchasesList as child view controllers
    [self addChildViewController:self.productsList];
    [self.productsList didMoveToParentViewController:self];
    [self addChildViewController:self.purchasesList];
    [self.purchasesList didMoveToParentViewController:self];
    
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


#pragma mark -
#pragma mark Display message

-(void)alertWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertView *alerView = [[UIAlertView alloc] initWithTitle:title
                                                       message:message
                                                      delegate:nil
                                             cancelButtonTitle:@"Ok"
                                             otherButtonTitles:nil];
    [alerView show];
    
}


#pragma mark -
#pragma mark Handle purchase request notification

// Update the UI according to the notification result
-(void)handlePurchasesNotification:(NSNotification *)notification
{
    StoreObserver *purchasesNotification = (StoreObserver *)[notification object];
    IAPPurchaseNotificationStatus status = (IAPPurchaseNotificationStatus)purchasesNotification.status;
    
    switch (status)
    {
        case IAPPurchaseSucceeded:
        {
            NSString *title = [[StoreManager sharedInstance] titleMatchingProductIdentifier:purchasesNotification.purchasedID];
            
            // Display the product's title associated with the payment's product identifier if it exists or the product identifier, otherwise
            NSString *displayedTitle = (title.length > 0) ? title : purchasesNotification.purchasedID;
            [self alertWithTitle:@"Purchase Status" message:[NSString stringWithFormat:@"%@ was successfully purchased.",displayedTitle]];
        }
            break;
        case IAPPurchaseFailed:
            [self alertWithTitle:@"Purchase Status" message:purchasesNotification.message];
            break;
        // Switch to the iOSPurchasesList view controller when receiving a successful restore notification
        case IAPRestoredSucceeded:
        {
            // Get the view controller currently displayed
            UIViewController *selectedController = [self viewControllerForSelectedIndex:self.segmentedControl.selectedSegmentIndex];
            self.segmentedControl.selectedSegmentIndex = 1;
            [self cycleFromViewController:selectedController toViewController:self.purchasesList];
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
            self.statusMessage.text = [NSString stringWithFormat:@"Downloading %@ %.2f%%",displayedTitle, purchasesNotification.downloadProgress];
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
        default:
            break;
    }
}


#pragma mark -
#pragma mark Toggle between view controllers

// Transition from the old view controller to the new one
-(void)cycleFromViewController:(UIViewController *)oldViewController toViewController:(UIViewController *)newViewController
{
    assert(newViewController != nil);
    
    if (oldViewController != nil)
    {
        [oldViewController.view removeFromSuperview];
    }
    
    CGRect frame = newViewController.view.frame;
    frame.size.height = CGRectGetHeight(self.containerView.frame);
    frame.size.width = CGRectGetWidth(self.containerView.frame);
    newViewController.view.frame = frame;
    [self.containerView addSubview:newViewController.view];
}


// Return the view controller associated with the segmented control's selected index
-(UIViewController *)viewControllerForSelectedIndex:(NSInteger)index
{
    UIViewController *viewController;
    switch (index)
    {
        case 0:
            viewController = self.productsList;
            break;
        case 1:
            viewController = self.purchasesList;
        default:
            break;
    }
    return viewController;
}


#pragma mark -
#pragma mark Handle segmented control tap

// Called when a user taps on the segmented control
- (IBAction)segmentValueChanged:(id)sender
{
    UISegmentedControl *segControl = (UISegmentedControl *)sender;
    
    // Return productsList if the user tapped Products in the segmented control and purchasesList, otherwise
    UIViewController *newViewController = (segControl.selectedSegmentIndex == 0) ? self.productsList : self.purchasesList;
    
     // Return purchasesList if the user tapped Purchases in the segmented control and productsList, otherwise
    UIViewController *oldViewController = (segControl.selectedSegmentIndex == 1) ? self.purchasesList : self.productsList;
    
    // Toggle from oldViewController to newViewController
    [self cycleFromViewController:oldViewController toViewController:newViewController];
}


#pragma mark -
#pragma mark Restore all appropriate transactions

- (IBAction)restore:(id)sender
{
    // Call StoreObserver to restore all restorable purchases
    [[StoreObserver sharedInstance] restore];
}


#pragma mark -
#pragma mark Memory management
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IAPPurchaseNotification
                                                  object:[StoreObserver sharedInstance]];
}

@end
