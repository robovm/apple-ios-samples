/*
     File: iOSPurchasesList.m
 Abstract: Displays two lists: purchased products and restored ones. Call StoreObserver to determine
           whether the user has purchased or restored some products. When a user taps a product, it calls 
           PaymentTransactionDetails to display its purchase information using SKPaymentTransaction.
 
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
#import "iOSPurchasesList.h"
#import "PaymentTransactionDetails.h"

enum {
    PLPurchasedProducts = 0,
    PLRestoredProducts
};

@interface iOSPurchasesList ()
@property (nonatomic, strong) NSMutableArray *allPurchases;
@property (nonatomic, strong) NSMutableArray *sectionNames;

@end

@implementation iOSPurchasesList

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    MyModel *model;
    self.sectionNames = [[NSMutableArray alloc] initWithCapacity:2];
    
    self.allPurchases = [[NSMutableArray alloc] initWithCapacity:2];
    [self.allPurchases insertObject:[[MyModel alloc] initWithName:@"PURCHASED" elements:@[]] atIndex:PLPurchasedProducts];
    [self.allPurchases insertObject:[[MyModel alloc] initWithName:@"RESTORED" elements:@[]] atIndex:PLRestoredProducts];
    
    
    // Update allPurchases if there are purchased products
    if ([[StoreObserver sharedInstance] hasPurchasedProducts])
    {
        model = (self.allPurchases)[PLPurchasedProducts];
        model.elements = [StoreObserver sharedInstance].productsPurchased;
        [self.sectionNames addObject:@"PURCHASED"];
    }
    
     // Update allPurchases if there are restored products
    if ([[StoreObserver sharedInstance] hasRestoredProducts])
    {
        model = (self.allPurchases)[PLRestoredProducts];
        model.elements = [StoreObserver sharedInstance].productsRestored;
        [self.sectionNames addObject:@"RESTORED"];
    }
    // Refresh the UI with the above data
    [self.tableView reloadData];
}


#pragma mark -
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger numberOfSections = 0;
    
    if (![(self.allPurchases)[PLPurchasedProducts] isEmpty])
    {
        numberOfSections++;
    }
    if (![(self.allPurchases)[PLRestoredProducts] isEmpty])
    {
        numberOfSections++;
    }
    
    // Return the number of sections.
    return numberOfSections;
}


-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    // Fetch the section name at the given index
    NSString *sectionName = (self.sectionNames)[section];
    // Fetch the model whose name matches sectionName
    MyModel *model = ([sectionName isEqualToString:@"PURCHASED"]) ? (self.allPurchases)[PLPurchasedProducts] : (self.allPurchases)[PLRestoredProducts];
    
    // Return the header title for this section
    return (!model.isEmpty) ? model.name : nil;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *sectionName = (self.sectionNames)[section];
    MyModel *model = ([sectionName isEqualToString:@"PURCHASED"]) ? (self.allPurchases)[PLPurchasedProducts] : (self.allPurchases)[PLRestoredProducts];
    
    // Return the number of rows in the section.
    return [model.elements count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *sectionName = (self.sectionNames)[indexPath.section];
    MyModel *model = ([sectionName isEqualToString:@"PURCHASED"]) ? (self.allPurchases)[PLPurchasedProducts] : (self.allPurchases)[PLRestoredProducts];
    NSArray *purchases = model.elements;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"purchasedID" forIndexPath:indexPath];
    
    SKPaymentTransaction *paymentTransaction = purchases[indexPath.row];
    NSString *title = ([[StoreManager sharedInstance] titleMatchingProductIdentifier:paymentTransaction.payment.productIdentifier]);
    
    // Display the product's title associated with the payment's product identifier if it exists or the product identifier, otherwise
    cell.textLabel.text = (title.length > 0) ? title : paymentTransaction.payment.productIdentifier;
    
    return cell;
}


#pragma mark -
#pragma mark - Date Formatter

// Return a date formatter
-(NSDateFormatter *)dateFormatter
{
    NSDateFormatter *myDateFormatter = [[NSDateFormatter alloc] init];
    [myDateFormatter setDateStyle:NSDateFormatterShortStyle];
    [myDateFormatter setTimeStyle:NSDateFormatterShortStyle];
    return myDateFormatter;
}


#pragma mark -
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *sectionName = (self.sectionNames)[[self.tableView indexPathForSelectedRow].section];
    MyModel *model = ([sectionName isEqualToString:@"PURCHASED"]) ? (self.allPurchases)[PLPurchasedProducts] : (self.allPurchases)[PLRestoredProducts];
    
    if ([[segue identifier] isEqualToString:@"showDetails"])
    {
        NSArray *purchases = model.elements;
        
        SKPaymentTransaction *paymentTransaction = purchases[[self.tableView indexPathForSelectedRow].row];
        NSMutableArray *purchaseDetails = [[NSMutableArray alloc] init];
        
        // Add the product identifier, transaction id, and transaction date to purchaseDetails
        [purchaseDetails addObject:[[MyModel alloc] initWithName:@"PRODUCT IDENTIFIER" elements:@[paymentTransaction.payment.productIdentifier]]];
        [purchaseDetails addObject:[[MyModel alloc] initWithName:@"TRANSACTION ID" elements:@[paymentTransaction.transactionIdentifier]]];
        [purchaseDetails addObject:[[MyModel alloc] initWithName:@"TRANSACTION DATE" elements:@[[[self dateFormatter] stringFromDate:paymentTransaction.transactionDate]]]];
        
        
         NSArray *allDownloads = paymentTransaction.downloads;
         // If this product is hosted, add its first download to purchaseDetails
         if ([allDownloads count] > 0)
         {
            // We are only showing the first download
            SKDownload *firstDownload = allDownloads[0];
            
            NSDictionary *identifier = @{@"Identifier": firstDownload.contentIdentifier};
            NSDictionary *version = @{@"Version": firstDownload.contentVersion};
            NSDictionary *contentLength = @{@"Length": [NSByteCountFormatter stringFromByteCount:firstDownload.contentLength countStyle:NSByteCountFormatterCountStyleFile]};
            
            // Add the identifier, version, and length of a download to purchaseDetails
            [purchaseDetails addObject:[[MyModel alloc] initWithName:@"DOWNLOAD" elements:@[identifier,version,contentLength]]];
         }
         
        // If the product is a restored one, add its original transaction's transaction id and transaction date to purchaseDetails
        if (paymentTransaction.originalTransaction !=nil)
        {
            NSDictionary *transactionID = @{@"Transaction ID": paymentTransaction.originalTransaction.transactionIdentifier};
            NSDictionary *transactionDate = @{@"Transaction Date": [[self dateFormatter] stringFromDate:paymentTransaction.originalTransaction.transactionDate]};
            
            [purchaseDetails addObject:[[MyModel alloc] initWithName:@"ORIGINAL TRANSACTION" elements:[NSMutableArray arrayWithObjects:transactionID,transactionDate, nil]]];
        }
        
        PaymentTransactionDetails *transactionDetails = (PaymentTransactionDetails *)[segue destinationViewController];
        transactionDetails.details = [NSArray arrayWithArray:purchaseDetails];
        transactionDetails.title = [[StoreManager sharedInstance] titleMatchingProductIdentifier:paymentTransaction.payment.productIdentifier];
    }
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
