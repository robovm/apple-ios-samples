/*
     File: CustomBackButtonViewController.m
 Abstract: Demonstrates using a custom back button image with no chevron and
 not text.
 
  Version: 1.12
 
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

#import "CustomBackButtonViewController.h"
#import "CustomBackButtonNavController.h"
#import "CustomBackButtonDetailViewController.h"

@interface CustomBackButtonViewController ()
//! An array of city names, populated from Cities.json.
@property (nonatomic, strong) NSArray *cities;
@end


@implementation CustomBackButtonViewController

//| ----------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Load some data to populate the table view with
    NSURL *citiesJSONURL = [[NSBundle mainBundle] URLForResource:@"Cities" withExtension:@"json"];
    NSData *citiesJSONData = [NSData dataWithContentsOfURL:citiesJSONURL];
    self.cities = [NSJSONSerialization JSONObjectWithData:citiesJSONData options:0 error:NULL];
    
    // Note that images configured as the back bar button's background do
    // not have the current tintColor applied to them, they are displayed
    // as it.
    UIImage *backButtonBackgroundImage = [UIImage imageNamed:@"Menu"];
    // The background should be pinned to the left and not stretch.
    backButtonBackgroundImage = [backButtonBackgroundImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, backButtonBackgroundImage.size.width - 1, 0, 0)];
    
    id appearance = [UIBarButtonItem appearanceWhenContainedIn:[CustomBackButtonNavController class], nil];
    [appearance setBackButtonBackgroundImage:backButtonBackgroundImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    // Provide an empty backBarButton to hide the 'Back' text present by
    // default in the back button.
    //
    // NOTE: You do not need to provide a target or action.  These are set
    //       by the navigation bar.
    // NOTE: Setting the title of this bar button item to ' ' (space) works
    //       around a bug in iOS 7.0.x where the background image would be
    //       horizontally compressed if the back button title is empty.
    UIBarButtonItem *backBarButton = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain target:nil action:NULL];
    self.navigationItem.backBarButtonItem = backBarButton;
    
    // NOTE: There is a bug in iOS 7.0.x where the background of the back bar
    //       button item will not appear until the back button has been tapped
    //       once.
}


//| ----------------------------------------------------------------------------
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"DetailSegue"])
        [(CustomBackButtonDetailViewController*)segue.destinationViewController setCity:self.cities[self.tableView.indexPathForSelectedRow.row]];
}

#pragma mark -
#pragma mark UITableViewDataSource

//| ----------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.cities.count;
}


//| ----------------------------------------------------------------------------
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    cell.textLabel.text = self.cities[indexPath.row];
    
    return cell;
}

@end
