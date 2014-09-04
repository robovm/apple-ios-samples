/*
     File: APLMonitoringViewController.m
 Abstract: View controller that illustrates how to start and stop monitoring for a beacon region.
 
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

#import "APLMonitoringViewController.h"
#import "APLDefaults.h"
#import "APLUUIDViewController.h"
@import CoreLocation;


@interface APLMonitoringViewController () <CLLocationManagerDelegate, UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UISwitch *enabledSwitch;

@property (nonatomic, weak) IBOutlet UITextField *uuidTextField;

@property (nonatomic, weak) IBOutlet UITextField *majorTextField;
@property (nonatomic, weak) IBOutlet UITextField *minorTextField;

@property (nonatomic, weak) IBOutlet UISwitch *notifyOnEntrySwitch;
@property (nonatomic, weak) IBOutlet UISwitch *notifyOnExitSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *notifyOnDisplaySwitch;

@property BOOL enabled;
@property NSUUID *uuid;
@property NSNumber *major;
@property NSNumber *minor;
@property BOOL notifyOnEntry;
@property BOOL notifyOnExit;
@property BOOL notifyOnDisplay;

@property UIBarButtonItem *doneButton;

@property (nonatomic) NSNumberFormatter *numberFormatter;
@property (nonatomic) CLLocationManager *locationManager;

- (void)updateMonitoredRegion;

@end


@implementation APLMonitoringViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    self.numberFormatter = [[NSNumberFormatter alloc] init];
    self.numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;

    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:[NSUUID UUID] identifier:BeaconIdentifier];
    region = [self.locationManager.monitoredRegions member:region];
    if(region)
    {
        self.enabled = YES;
        self.uuid = region.proximityUUID;
        self.major = region.major;
        self.majorTextField.text = [self.major stringValue];
        self.minor = region.minor;
        self.minorTextField.text = [self.minor stringValue];
        self.notifyOnEntry = region.notifyOnEntry;
        self.notifyOnExit = region.notifyOnExit;
        self.notifyOnDisplay = region.notifyEntryStateOnDisplay;
    }
    else
    {
        // Default settings.
        self.enabled = NO;
        
        self.uuid = [APLDefaults sharedDefaults].defaultProximityUUID;
        self.major = self.minor = nil;
        self.notifyOnEntry = self.notifyOnExit = YES;
        self.notifyOnDisplay = NO;
    }

    self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing:)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.uuidTextField.text = [self.uuid UUIDString];
    
    self.enabledSwitch.on = self.enabled;
    self.notifyOnEntrySwitch.on = self.notifyOnEntry;
    self.notifyOnExitSwitch.on = self.notifyOnExit;
    self.notifyOnDisplaySwitch.on = self.notifyOnDisplay;
}

#pragma mark - Toggling state

- (IBAction)toggleEnabled:(UISwitch *)sender
{
    self.enabled = sender.on;
    
    [self updateMonitoredRegion];
}

- (IBAction)toggleNotifyOnEntry:(UISwitch *)sender
{
    self.notifyOnEntry = sender.on;
    [self updateMonitoredRegion];
}

- (IBAction)toggleNotifyOnExit:(UISwitch *)sender
{
    self.notifyOnExit = sender.on;
    [self updateMonitoredRegion];
}

- (IBAction)toggleNotifyOnDisplay:(UISwitch *)sender
{
    self.notifyOnDisplay = sender.on;
    [self updateMonitoredRegion];
}

#pragma mark - Text editing

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if(textField == self.uuidTextField)
    {
        [self performSegueWithIdentifier:@"selectUUID" sender:self];
        return NO;
    }
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.navigationItem.rightBarButtonItem = self.doneButton;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{    
    if(textField == self.majorTextField)
    {
        self.major = [self.numberFormatter numberFromString:textField.text];
    }
    else if(textField == self.minorTextField)
    {
        self.minor = [self.numberFormatter numberFromString:textField.text];
    }
    
    self.navigationItem.rightBarButtonItem = nil;
    
    [self updateMonitoredRegion];
}

#pragma mark - Managing editing

- (IBAction)doneEditing:(id)sender
{
    [self.majorTextField resignFirstResponder];
    [self.minorTextField resignFirstResponder];
    
    [self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"selectUUID"])
    {
        APLUUIDViewController *uuidSelector = [segue destinationViewController];
        
        uuidSelector.uuid = self.uuid;
    }
}

- (IBAction)unwindUUIDSelector:(UIStoryboardSegue*)sender
{
    APLUUIDViewController *uuidSelector = [sender sourceViewController];
    
    self.uuid = uuidSelector.uuid;
    [self updateMonitoredRegion];
}

- (void)updateMonitoredRegion
{
    // if region monitoring is enabled, update the region being monitored
    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:[NSUUID UUID] identifier:BeaconIdentifier];
    
    if(region != nil)
    {
        [self.locationManager stopMonitoringForRegion:region];
    }
    
    if(self.enabled)
    {
        region = nil;
        if(self.uuid && self.major && self.minor)
        {
            region = [[CLBeaconRegion alloc] initWithProximityUUID:self.uuid major:[self.major shortValue] minor:[self.minor shortValue] identifier:BeaconIdentifier];
        }
        else if(self.uuid && self.major)
        {
            region = [[CLBeaconRegion alloc] initWithProximityUUID:self.uuid major:[self.major shortValue]  identifier:BeaconIdentifier];
        }
        else if(self.uuid)
        {
            region = [[CLBeaconRegion alloc] initWithProximityUUID:self.uuid identifier:BeaconIdentifier];
        }
        
        if(region)
        {
            region.notifyOnEntry = self.notifyOnEntry;
            region.notifyOnExit = self.notifyOnExit;
            region.notifyEntryStateOnDisplay = self.notifyOnDisplay;
            
            [self.locationManager startMonitoringForRegion:region];
        }
    }
    else
    {
        CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:[NSUUID UUID] identifier:BeaconIdentifier];
        [self.locationManager stopMonitoringForRegion:region];
    }
}

@end
