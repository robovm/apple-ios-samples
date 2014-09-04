/*
     File: LocationDetailViewController.m
 Abstract: Lists the values for all the properties of a single CLLocation object. 
 
  Version: 2.2
 
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
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */

#import "LocationDetailViewController.h"
#import "CLLocation (Strings).h"

@implementation LocationDetailViewController

@synthesize location;

- (void)dealloc {
    [dateFormatter release];
    [location release];
    [super dealloc];
}

- (void)viewDidUnload {
    [dateFormatter release];
    dateFormatter = nil;
    self.location = nil;
}

- (NSDateFormatter *)dateFormatter {
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterLongStyle];
    }
    return dateFormatter;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (section == 0) ? 3: 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0: {
            return NSLocalizedString(@"Attributes", @"Attributes");
        } break;
        case 1: {
            return NSLocalizedString(@"Accuracy", @"Accuracy");
        } break;
        default: {
            return NSLocalizedString(@"Course and Speed", @"Course and Speed");
        } break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *kLocationAttributeCellID = @"LocationAttributeCellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kLocationAttributeCellID];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:kLocationAttributeCellID] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0: {
                cell.textLabel.text = NSLocalizedString(@"timestamp", @"timestamp");
                cell.detailTextLabel.text = [self.dateFormatter stringFromDate:location.timestamp];
            } break;
            case 1: {
                cell.textLabel.text = NSLocalizedString(@"coordinate", @"coordinate");
                if (location.horizontalAccuracy < 0) {
                } else {
                    cell.detailTextLabel.text = location.localizedCoordinateString;
                }
            } break;
            default: {
                cell.textLabel.text = NSLocalizedString(@"altitude", @"altitude");
                cell.detailTextLabel.text = location.localizedAltitudeString;
            } break;
        }
    } else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0: {
                cell.textLabel.text = NSLocalizedString(@"horizontal", @"horizontal");
                cell.detailTextLabel.text = location.localizedHorizontalAccuracyString;
            } break;
            default: {
                cell.textLabel.text = NSLocalizedString(@"vertical", @"vertical");
                cell.detailTextLabel.text = location.localizedVerticalAccuracyString;
            } break;
        }
    } else {
        switch (indexPath.row) {
            case 0: {
                cell.textLabel.text = NSLocalizedString(@"course", @"course");
                cell.detailTextLabel.text = location.localizedCourseString;
            } break;
            default: {
                cell.textLabel.text = NSLocalizedString(@"speed", @"speed");
                cell.detailTextLabel.text = location.localizedSpeedString;
            } break;
        }
    }
    return cell;
}

@end

