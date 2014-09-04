/*
     File: iOSProductsList.m
 Abstract:  Request product information about a list of product identifiers using StoreManager.
            Displays a list of products available for sale in the App Store if StoreManager returns one.
            Displays the localized title and price of each of these products using SKProduct. Also shows a list of product
            identifiers not recognized by the App Store if applicable. Calls StoreObserver to implement a purchase 
            when a user taps a product.
 
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

enum {
    PLAvailableProducts = 0,
    PLInvalidProductIds
};

@interface iOSProductsList ()
@property (nonatomic, strong) NSMutableArray *products;
@property (nonatomic, strong) NSMutableArray *sectionNames;

@end

@implementation iOSProductsList

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
    
    // Register for StoreManager's notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleProductRequestNotification:)
                                                 name:IAPProductRequestNotification
                                               object:[StoreManager sharedInstance]];
    
    
    self.products = [[NSMutableArray alloc] initWithCapacity:2];
    
    // The tableview is organized into 2 sections: AVAILABLE PRODUCTS and INVALID PRODUCT IDS
    [self.products insertObject:[[MyModel alloc] initWithName:@"AVAILABLE PRODUCTS" elements:@[]] atIndex:PLAvailableProducts];
    [self.products insertObject:[[MyModel alloc] initWithName:@"INVALID PRODUCT IDS" elements:@[]] atIndex:PLInvalidProductIds];
    
     self.sectionNames = [[NSMutableArray alloc] initWithCapacity:2];
    
    [self fetchProductInformation];
}


#pragma mark -
#pragma mark Fetch product information

// Retrieve product information from the App Store
-(void)fetchProductInformation
{
    // Query the App Store for product information if the user is is allowed to make purchases.
    // Display an alert, otherwise.
    if([SKPaymentQueue canMakePayments])
    {
        // Load the product identifiers fron ProductIds.plist
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"ProductIds" ofType:@"plist"];
		NSArray *productIds = [NSArray arrayWithContentsOfFile:plistPath];
        
        [[StoreManager sharedInstance] fetchProductInformationForIds:productIds];
    }
    else
	{
        // Warn the user that they are not allowed to make purchases.
        [self alertWithTitle:@"Warning" message:@"Purchases are disabled on this device."];
    }
}


#pragma mark -
#pragma mark Handle product request notification

// Update the UI according to the notification result
-(void)handleProductRequestNotification:(NSNotification *)notification
{
    MyModel *model = nil;
    StoreManager *productRequestNotification = (StoreManager*)[notification object];
    IAPProductRequestStatus result = (IAPProductRequestStatus)productRequestNotification.status;
   
    switch (result)
    {
        // The App Store has recognized some identifiers and returned their matching products.
        case IAPProductsFound:
         {
            model = (self.products)[PLAvailableProducts];
            model.elements = productRequestNotification.availableProducts;
            // Keep track of the position of the AVAILABLE PRODUCTS section
            [self.sectionNames addObject:@"AVAILABLE PRODUCTS"];
         }
         break;
        // Some product identifiers were not recognized by the App Store
        case IAPIdentifiersNotFound:
         {
            model = (self.products)[PLInvalidProductIds];
            model.elements = productRequestNotification.invalidProductIds;
            // Keep track of the position of the INVALID PRODUCT IDS section
            [self.sectionNames addObject:@"INVALID PRODUCT IDS"];
         }
         break;
        default:
            break;
    }
    // Reload the tableview to update it
    if (model != nil)
    {
        [self.tableView reloadData];
    }
}


#pragma mark -
#pragma mark Display message

// Display an alert with a given title and message
-(void)alertWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertView *alerView = [[UIAlertView alloc] initWithTitle:title
                                                       message:message
                                                      delegate:nil
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil];
    [alerView show];
    
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger numberOfSections = 0;
    
    if (![(self.products)[PLAvailableProducts] isEmpty])
    {
         numberOfSections++;
    }
    if (![(self.products)[PLInvalidProductIds] isEmpty])
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
    MyModel *model = ([sectionName isEqualToString:@"AVAILABLE PRODUCTS"]) ? (self.products)[PLAvailableProducts] : (self.products)[PLInvalidProductIds];
    
    // Return the header title for this section
    return (!model.isEmpty) ? model.name : nil;
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *sectionName = (self.sectionNames)[section];
    MyModel *model = ([sectionName isEqualToString:@"AVAILABLE PRODUCTS"]) ? (self.products)[PLAvailableProducts] : (self.products)[PLInvalidProductIds];
    
    // Return the number of rows in the section.
    return [model.elements count];
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *sectionName = (self.sectionNames)[indexPath.section];
    MyModel *model = ([sectionName isEqualToString:@"AVAILABLE PRODUCTS"]) ? (self.products)[PLAvailableProducts] : (self.products)[PLInvalidProductIds];
    
    
    NSArray *productRequestResponse = model.elements;
    
    if ([model.name isEqualToString:@"AVAILABLE PRODUCTS"])
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"availableProductID" forIndexPath:indexPath];
        SKProduct *aProduct = productRequestResponse[indexPath.row];
        // Show the localized title of the product
        cell.textLabel.text = aProduct.localizedTitle;
        // Show the product's price in the locale and currency returned by the App Store
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@",[aProduct.priceLocale objectForKey:NSLocaleCurrencySymbol],[aProduct price]];
        return cell;
        
    }
    else
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"invalidIdentifierID" forIndexPath:indexPath];
        cell.textLabel.text = productRequestResponse[indexPath.row];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.textColor = [UIColor grayColor];
        return cell;
    }

}


#pragma mark -
#pragma mark Table view delegate

// Start a purchase when the user taps a row
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Only items in the first section of the table can be bought
	if(indexPath.section == PLAvailableProducts)
	{
        MyModel *model = (MyModel *)(self.products)[indexPath.section];
        NSArray *productRequestResponse = model.elements;
        
        SKProduct *product = (SKProduct *)productRequestResponse[indexPath.row];
        // Attempt to purchase the tapped product
		[[StoreObserver sharedInstance] buy:product];
	}
}



#pragma mark -
#pragma mark Memory management
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)dealloc
{
    // Unregister for StoreManager's notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IAPProductRequestNotification
                                                  object:[StoreManager sharedInstance]];
    
}

@end
