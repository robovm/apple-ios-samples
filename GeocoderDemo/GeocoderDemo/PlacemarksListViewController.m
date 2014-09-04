/*
     File: PlacemarksListViewController.m 
 Abstract: UITableViewController that Displays a list of CLPlacemarks. 
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

#import "PlacemarksListViewController.h"
#import "PlacemarkViewController.h"

#import <AddressBookUI/AddressBookUI.h>

@interface PlacemarksListViewController ()
{
    NSArray *_placemarks;
    BOOL _preferCoord;
}

@property (nonatomic, strong) NSArray *placemarks;
@end

@implementation PlacemarksListViewController

// show the coord in the main textField in the cell if YES
- (id)initWithPlacemarks:(NSArray*)placemarks preferCoord:(BOOL)shouldPreferCoord
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self)
    {
        _placemarks = placemarks;
        _preferCoord = shouldPreferCoord;
    }
    return self;

}

- (id)initWithPlacemarks:(NSArray*)placemarks
{
    return [self initWithPlacemarks:placemarks preferCoord:NO];
}

- (id)init
{
    return [self initWithPlacemarks:nil];
}



#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"CLPlacemarks";
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // return the number of rows in the section.   
    if (self.placemarks == nil || self.placemarks.count == 0)
        return 1;
    
    return self.placemarks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    if (self.placemarks == nil || self.placemarks.count == 0)
    {
        // show a zero results cell
        cell.textLabel.text = @"No Placemarks..";
    }
    else
    {
        CLPlacemark *placemark = self.placemarks[indexPath.row];
        
        // use the AddressBook framework to create an address dictionary
        NSString *addressString = CFBridgingRelease(CFBridgingRetain(ABCreateStringWithAddressDictionary(placemark.addressDictionary, NO)));
        
        CLLocationDegrees latitude = placemark.location.coordinate.latitude;
        CLLocationDegrees longitude = placemark.location.coordinate.longitude;
        NSString *coordString = [NSString stringWithFormat:@"φ:%.4F, λ:%.4F", latitude, longitude];
        // switch around our strings depending on our priority at init time
        cell.textLabel.text = _preferCoord ? coordString : addressString;
        cell.detailTextLabel.text = _preferCoord ? addressString : coordString;

        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CLPlacemark *placemark = self.placemarks[indexPath.row];
    PlacemarkViewController *pvc = [[PlacemarkViewController alloc] initWithPlacemark:placemark preferCoord:_preferCoord];
    [self.navigationController pushViewController:pvc animated:YES];
}

@end
