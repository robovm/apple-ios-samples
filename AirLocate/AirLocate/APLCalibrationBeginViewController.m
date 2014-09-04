/*
     File: APLCalibrationBeginViewController.m
 Abstract: View controller for bootstrapping the calibration process.
 
  Version: 1.1
 
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

#import "APLCalibrationBeginViewController.h"
#import "APLCalibrationEndViewController.h"
#import "APLCalibrationCalculator.h"
#import "APLProgressTableViewCell.h"
#import "APLDefaults.h"


@interface APLCalibrationBeginViewController()

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) NSMutableDictionary *beacons;
@property (nonatomic) NSMutableArray *rangedRegions;
@property (nonatomic) APLCalibrationCalculator *calculator;

@property BOOL inProgress;

@end


@implementation APLCalibrationBeginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // This location manager will be used to display beacons available for calibration.
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.inProgress = NO;

    self.beacons = [[NSMutableDictionary alloc] init];

    // Populate the regions for the beacons we're interested in calibrating.
    self.rangedRegions = [NSMutableArray array];
    for (NSUUID *uuid in [APLDefaults sharedDefaults].supportedProximityUUIDs)
    {
        CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:[uuid UUIDString]];
        [self.rangedRegions addObject:region];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Start ranging to show the beacons available for calibration.
    [self startRangingAllRegions];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    // Cancel calibration (if it was started) and stop ranging when the view goes away.
    [self.calculator cancelCalibration];
    [self stopRangingAllRegions];
}

#pragma mark - Ranging beacons

- (void)startRangingAllRegions
{
    for (CLBeaconRegion *region in self.rangedRegions)
    {
        [self.locationManager startRangingBeaconsInRegion:region];
    }
}

- (void)stopRangingAllRegions
{
    for (CLBeaconRegion *region in self.rangedRegions)
    {
        [self.locationManager stopRangingBeaconsInRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{    
    // CoreLocation will call this delegate method at 1 Hz with updated range information.
    // Beacons will be categorized and displayed by proximity.
    [self.beacons removeAllObjects];
    NSArray *unknownBeacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityUnknown]];
    if([unknownBeacons count])
        self.beacons[@(CLProximityUnknown)] = unknownBeacons;
    
    NSArray *immediateBeacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityImmediate]];
    if([immediateBeacons count])
        self.beacons[@(CLProximityImmediate)] = immediateBeacons;
    
    NSArray *nearBeacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityNear]];
    if([nearBeacons count])
        self.beacons[@(CLProximityNear)] = nearBeacons;
    
    NSArray *farBeacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityFar]];
    if([farBeacons count])
        self.beacons[@(CLProximityFar)] = farBeacons;
    
    [self.tableView reloadData];
}

- (void)updateProgressViewWithProgress:(float)percentComplete
{
    if (!self.inProgress)
    {
        return;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    APLProgressTableViewCell *progressCell = (APLProgressTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [progressCell.progressView setProgress:percentComplete animated:YES];
}

#pragma mark - Table view data source/delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // A special indicator appears if calibration is in progress.
    // This is handled throughout the table view controller delegate methods.
    NSInteger i = self.inProgress ? self.beacons.count + 1 : self.beacons.count;
    
    return i;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger adjustedSection = section;
    if(self.inProgress)
    {
        if(adjustedSection == 0)
        {
            return 1;
        }
        else
        {
            adjustedSection--;
        }
    }
    
    NSArray *sectionValues = [self.beacons allValues];
    return [sectionValues[adjustedSection] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSInteger adjustedSection = section;
    if(self.inProgress)
    {
        if(adjustedSection == 0)
        {
            return nil;
        }
        else
        {
            adjustedSection--;
        }
    }
    
    NSString *title;
    NSArray *sectionKeys = [self.beacons allKeys];
    
    NSNumber *sectionKey = sectionKeys[adjustedSection];
    switch([sectionKey integerValue])
    {
        case CLProximityImmediate:
            title = NSLocalizedString(@"Immediate", @"Section title in begin calibration view controller");
            break;
            
        case CLProximityNear:
            title = NSLocalizedString(@"Near", @"Section title in begin calibration view controller");
            break;
            
        case CLProximityFar:
            title = NSLocalizedString(@"Far", @"Section title in begin calibration view controller");
            break;
            
        default:
            title = NSLocalizedString(@"Unknown", @"Section title in begin calibration view controller");
            break;
    }
    
    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *beaconCellIdentifier = @"BeaconCell";
    static NSString *progressCellIdentifier = @"ProgressCell";
    
    NSInteger section = indexPath.section;
    NSString *identifier = self.inProgress && section == 0 ? progressCellIdentifier : beaconCellIdentifier;
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if(identifier == progressCellIdentifier)
    {
        return cell;
    }
    else if(self.inProgress)
    {
        section--;
    }
    
    NSNumber *sectionKey = [self.beacons allKeys][section];
    CLBeacon *beacon = self.beacons[sectionKey][indexPath.row];
    cell.textLabel.text = [beacon.proximityUUID UUIDString];
    NSString *formatString = NSLocalizedString(@"Major: %@, Minor: %@, Acc: %.2fm", @"format string for detail");
    cell.detailTextLabel.text = [NSString stringWithFormat:formatString, beacon.major, beacon.minor, beacon.accuracy];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    NSNumber *sectionKey = [self.beacons allKeys][indexPath.section];
    CLBeacon *beacon = self.beacons[sectionKey][indexPath.row];
    
    if(!self.inProgress)
    {
        CLBeaconRegion *region = nil;
        if(beacon.proximityUUID && beacon.major && beacon.minor)
        {
            region = [[CLBeaconRegion alloc] initWithProximityUUID:beacon.proximityUUID major:[beacon.major shortValue] minor:[beacon.minor shortValue] identifier:BeaconIdentifier];
        }
        else if(beacon.proximityUUID && beacon.major)
        {
            region = [[CLBeaconRegion alloc] initWithProximityUUID:beacon.proximityUUID major:[beacon.major shortValue] identifier:BeaconIdentifier];
        }
        else if(beacon.proximityUUID)
        {
            region = [[CLBeaconRegion alloc] initWithProximityUUID:beacon.proximityUUID identifier:BeaconIdentifier];
        }
        
        if(region)
        {
            // We can stop ranging to display beacons available for calibration.
            [self stopRangingAllRegions];
            
            // And we'll start the calibration process.
            self.calculator = [[APLCalibrationCalculator alloc] initWithRegion:region completionHandler:^(NSInteger measuredPower, NSError *error) {
                if(error)
                {
                    // Only display if the view is showing.
                    if(self.view.window)
                    {
                        NSString *title = NSLocalizedString(@"Unable to calibrate device", @"Alert title for calibration begin view controller");
                        NSString *cancelTitle = NSLocalizedString(@"OK", @"Alert OK title for calibration begin view controller");
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:(error.userInfo)[NSLocalizedDescriptionKey] delegate:nil cancelButtonTitle:cancelTitle otherButtonTitles:nil];
                        [alert show];
                        
                        // Resume displaying beacons available for calibration if the calibration process failed.
                        [self startRangingAllRegions];
                    }
                }
                else
                {
                    APLCalibrationEndViewController *endViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EndViewController"];
                    endViewController.measuredPower = measuredPower;
                    [self.navigationController pushViewController:endViewController animated:YES];
                }
                
                self.inProgress = NO;
                self.calculator = nil;
                
                [self.tableView reloadData];
            }];

            __weak APLCalibrationBeginViewController *weakSelf = self;
            [self.calculator performCalibrationWithProgressHandler:^(float percentComplete) {
                [weakSelf updateProgressViewWithProgress:percentComplete];
            }];
            
            self.inProgress = YES;
            [self.tableView beginUpdates];
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
            [self updateProgressViewWithProgress:0.0];
        }
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.inProgress && indexPath.section == 0)
    {
        return 66.0;
    }
    return 44.0;
}

@end
