/*
     File: DistanceViewController.m 
 Abstract: View controller in charge of measuring distance between 2 locations.
  
  Version: 1.3 
  
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
  
 Copyright (C) 2013 Apple Inc. All Rights Reserved. 
  
 */

#import "DistanceViewController.h"

#import "CoordinateSelectorTableViewController.h"
#import "PlacemarksListViewController.h"


#pragma mark -

@interface DistanceViewController ()

@property (readonly) CoordinateSelectorTableViewController *toCoordinateSelector;  
@property (readonly) CoordinateSelectorTableViewController *fromCoordinateSelector;  

@end


@implementation DistanceViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _toCoordinateSelector = [[CoordinateSelectorTableViewController alloc] init];
    _fromCoordinateSelector = [[CoordinateSelectorTableViewController alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

// rotation support for iOS 5.x and earlier, note for iOS 6.0 and later all you need is
// "UISupportedInterfaceOrientations" defined in your Info.plist
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    }
    else
    {
        return YES;
    }
}
#endif

#pragma mark - Distance Calculation

- (double)distanceBetweenCoordinates
{
    CLLocationDegrees latitude, longitude;
    
    latitude = self.toCoordinateSelector.selectedCoordinate.latitude;
    longitude = self.toCoordinateSelector.selectedCoordinate.longitude;
    CLLocation *to = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    
    latitude = self.fromCoordinateSelector.selectedCoordinate.latitude;
    longitude = self.fromCoordinateSelector.selectedCoordinate.longitude;
    CLLocation *from = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    
    CLLocationDistance distance = [to distanceFromLocation:from];
    
    return distance;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // return the number of sections
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // return the number of rows in the section
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    // to and from cells
    if (indexPath.section == 0 || indexPath.section == 1)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"selectorCell"];
        if (!cell)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"selectorCell"];
        
        CoordinateSelectorTableViewController *selector;
        switch (indexPath.section)
        {
            default:
            case 0:
                selector = self.toCoordinateSelector;
                break;
            case 1:
                selector = self.fromCoordinateSelector;
                break;
        }
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        if (selector.selectedType != CoordinateSelectorLastSelectedTypeUndefined)
        {
            cell.textLabel.text = selector.selectedName;
            if (CLLocationCoordinate2DIsValid(selector.selectedCoordinate))
            {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"φ:%.4F, λ:%.4F", selector.selectedCoordinate.latitude, selector.selectedCoordinate.longitude];
            }
        }
        else
        {
            cell.textLabel.text = @"Select a Place";
            cell.detailTextLabel.text = @"";
        }
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 1)
    {
        if (self.toCoordinateSelector.selectedType != CoordinateSelectorLastSelectedTypeUndefined &&
            self.fromCoordinateSelector.selectedType != CoordinateSelectorLastSelectedTypeUndefined)
        {
            return [NSString stringWithFormat:@"%.1f km\n(as the crow flies)", [self distanceBetweenCoordinates] / 1000];
        }
        else
        {
            return @"- km";
        }
    }
    return nil;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[tableView cellForRowAtIndexPath:indexPath] setSelected:NO];
    
    if (indexPath.section == 0)
    {
        [[self navigationController] pushViewController:self.toCoordinateSelector animated:YES];
    }
    else if (indexPath.section == 1)
    {
        [[self navigationController] pushViewController:self.fromCoordinateSelector animated:YES];
    }
}

@end
