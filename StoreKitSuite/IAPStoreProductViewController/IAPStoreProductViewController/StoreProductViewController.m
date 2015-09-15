/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Demontrates how to use SKStoreProductViewControllerDelegate and SKStoreProductViewController.
         Displays a list of iTunes products available for sale in the App Store. Launches the App Store
         from within the app when tapping on a product.
*/


#import "Product.h"
#import "StoreProductViewController.h"

// Height for the Audio Books row
#define kUIAudioBooksRowHeight 81.0


@interface StoreProductViewController ()<SKStoreProductViewControllerDelegate>
@property (nonatomic, strong) NSMutableArray *myProducts;

@end

@implementation StoreProductViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Fetch all the products
    NSURL *plistURL = [[NSBundle mainBundle] URLForResource:@"Products" withExtension:@"plist"];
    NSArray *temp = [NSArray arrayWithContentsOfURL:plistURL];
    
    self.myProducts = [[NSMutableArray alloc] initWithCapacity:0];
    
    Product *item;
    for (NSDictionary *dictionary in temp)
    {
        // Create an Product object to store its category, title, and identifier properties
        item = [[Product alloc] initWithCategory:dictionary[@"category"]
                                           title:dictionary[@"title"]
                               productIdentifier:dictionary[@"identifier"]];
        
        // Keep track of all the products
        [self.myProducts addObject:item];
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections
    return self.myProducts.count;
}


-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    Product *item = (Product *)(self.myProducts)[section];
    //Return the title of the section header
    return item.category;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Product *item = (Product *)(self.myProducts)[indexPath.section];
    // Change the height if "AUDIO BOOKS" is the specified row
    return ([item.category isEqualToString:@"AUDIO BOOKS"]) ? kUIAudioBooksRowHeight : tableView.rowHeight;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"productID" forIndexPath:indexPath];
    
    Product *item = (Product *)(self.myProducts)[indexPath.section];
    cell.textLabel.text = item.title;
    
    return cell;
}


#pragma mark Table view delegate

// Loads and launches a store product view controller with a selected product
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Product *item = (Product *)(self.myProducts)[indexPath.section];
    
    // Create a product dictionary using the selected product's iTunes identifer
    NSDictionary* parametersDict = @{SKStoreProductParameterITunesItemIdentifier: @([item.productID intValue])};
    
    // Create a store product view controller
    SKStoreProductViewController* storeProductViewController = [[SKStoreProductViewController alloc] init];
    storeProductViewController.delegate = self;
    
    // Attempt to load the selected product from the App Store, display the store product view controller if success
    // and print an error message, otherwise.
    [storeProductViewController loadProductWithParameters:parametersDict completionBlock:^(BOOL result, NSError *error)
     {
         if(result)
         {
             [self presentViewController:storeProductViewController animated:YES completion:nil];
         }
         else
         {
             NSLog(@"Error message: %@",[error localizedDescription]);
         }
     }];
}


#pragma mark Store product view controller delegate

// Used to dismiss the store view controller
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    [viewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
