/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Displays a list of products available for sale in the App Store if StoreManager returns one.
         Displays the localized title and price of each of these products using SKProduct. Also shows a list
         of product identifiers not recognized by the App Store if applicable. Calls StoreObserver to implement
         a purchase when a user taps a product.
 */


#import "MyModel.h"
#import "StoreObserver.h"
#import "iOSProductsList.h"


@interface iOSProductsList()
@property (nonatomic, strong) NSMutableArray *products;

@end

@implementation iOSProductsList


-(void)viewDidLoad
{
    [super viewDidLoad];
    self.products = [[NSMutableArray alloc] initWithCapacity:0];
}


#pragma mark - IAPTableViewDataSource

-(void)reloadUIWithData:(NSMutableArray *)data
{
    self.products = data;
    [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections
    return self.products.count;
}


-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    // Fetch the model at the given index
    MyModel *model = (self.products)[section];
    
    // Return the header title for this section
    return model.name;
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    MyModel *model = (self.products)[section];
    
    // Return the number of rows in the section
    return model.elements.count;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MyModel *model = (self.products)[indexPath.section];
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



#pragma mark Table view delegate

// Start a purchase when the user taps a row
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MyModel *model = (self.products)[indexPath.section];
    // Only available products can be bought
    if([model.name isEqualToString:@"AVAILABLE PRODUCTS"])
    {
        NSArray *productRequestResponse = model.elements;
        SKProduct *product = (SKProduct *)productRequestResponse[indexPath.row];
        // Attempt to purchase the tapped product
        [[StoreObserver sharedInstance] buy:product];
    }
}



#pragma mark Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
