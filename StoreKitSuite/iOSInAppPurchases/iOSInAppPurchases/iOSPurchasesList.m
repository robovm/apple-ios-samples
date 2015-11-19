/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Displays two lists: purchased products and restored ones. Call StoreObserver to determine
         whether the user has purchased or restored some products. When a user taps a product, it calls
         PaymentTransactionDetails to display its purchase information using SKPaymentTransaction.
 */


#import "MyModel.h"
#import "StoreManager.h"
#import "StoreObserver.h"
#import "iOSPurchasesList.h"
#import "PaymentTransactionDetails.h"

@interface iOSPurchasesList()
@property (nonatomic, strong) NSMutableArray *allPurchases;

@end


@implementation iOSPurchasesList

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.allPurchases = [[NSMutableArray alloc] initWithCapacity:0];
}


#pragma mark - IAPTableViewDataSource

-(void)reloadUIWithData:(NSMutableArray *)data
{
    self.allPurchases = data;
    [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return self.allPurchases.count;
}


-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    MyModel *model = (self.allPurchases)[section];
    return model.name;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    MyModel *model = (self.allPurchases)[section];
    
    // Return the number of rows in the section.
    return model.elements.count;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    MyModel *model = (self.allPurchases)[indexPath.section];
    
    NSArray *purchases = model.elements;
    SKPaymentTransaction *paymentTransaction = purchases[indexPath.row];
    NSString *title = ([[StoreManager sharedInstance] titleMatchingProductIdentifier:paymentTransaction.payment.productIdentifier]);
    
    // Display the product's title associated with the payment's product identifier if it exists or the product identifier, otherwise
    cell.textLabel.text = (title.length > 0) ? title : paymentTransaction.payment.productIdentifier;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier:@"purchasedID" forIndexPath:indexPath];
}


#pragma mark - Date Formatter

// Return a date formatter
-(NSDateFormatter *)dateFormatter
{
    NSDateFormatter *myDateFormatter = [[NSDateFormatter alloc] init];
    myDateFormatter.dateStyle = NSDateFormatterShortStyle;
    myDateFormatter.timeStyle = NSDateFormatterShortStyle;
    return myDateFormatter;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSInteger selectedRowIndex = (self.tableView).indexPathForSelectedRow.section;
    MyModel *model = self.allPurchases[selectedRowIndex];
    
    if ([segue.identifier isEqualToString:@"showPaymentTransaction"])
    {
        NSArray *purchases = model.elements;
        
        SKPaymentTransaction *paymentTransaction = purchases[(self.tableView).indexPathForSelectedRow.row];
        NSMutableArray *purchaseDetails = [[NSMutableArray alloc] init];
        
        // Add the product identifier, transaction id, and transaction date to purchaseDetails
        [purchaseDetails addObject:[[MyModel alloc] initWithName:@"PRODUCT IDENTIFIER" elements:@[paymentTransaction.payment.productIdentifier]]];
        [purchaseDetails addObject:[[MyModel alloc] initWithName:@"TRANSACTION ID" elements:@[paymentTransaction.transactionIdentifier]]];
        [purchaseDetails addObject:[[MyModel alloc] initWithName:@"TRANSACTION DATE" elements:@[[[self dateFormatter] stringFromDate:paymentTransaction.transactionDate]]]];
        
        
        NSArray *allDownloads = paymentTransaction.downloads;
        // If this product is hosted, add its first download to purchaseDetails
        if (allDownloads.count > 0)
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
        
        PaymentTransactionDetails *transactionDetails = (PaymentTransactionDetails *)segue.destinationViewController;
        transactionDetails.details = [NSArray arrayWithArray:purchaseDetails];
        transactionDetails.title = [[StoreManager sharedInstance] titleMatchingProductIdentifier:paymentTransaction.payment.productIdentifier];
    }
}


#pragma mark Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
