/*
     File: StoreProductViewController.m
 Abstract: Demontrates how to use SKStoreProductViewControllerDelegate and SKStoreProductViewController. 
           Displays a list of iTunes products available for sale in the App Store. Launches the App Store 
           from within the app when tapping on a product.
 
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

#import "Product.h"
#import "StoreProductViewController.h"

// Height for the Audio Books row
#define kUIAudioBooksRowHeight 81.0


@interface StoreProductViewController ()<SKStoreProductViewControllerDelegate>
@property (nonatomic, strong) NSMutableArray *myProducts;

@end

@implementation StoreProductViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self)
    {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Fetch all the products 
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Products" ofType:@"plist"];
    NSArray *temp = [NSArray arrayWithContentsOfFile:plistPath];
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
    return [self.myProducts count];
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
             [self presentViewController:storeProductViewController animated:YES completion:NULL];
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
    [viewController.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
