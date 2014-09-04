/*
     File: APLConfigurationViewController.m
 Abstract: Illustrates how to configure an iOS device as a beacon.
 
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

#import "APLConfigurationViewController.h"
#import "APLDefaults.h"
#import "APLUUIDViewController.h"

@import CoreLocation;
@import CoreBluetooth;


CBPeripheralManager *peripheralManager = nil;
CLBeaconRegion *region = nil;
NSNumber *power = nil;


@interface APLConfigurationViewController () <CBPeripheralManagerDelegate, UIAlertViewDelegate, UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UISwitch *enabledSwitch;
@property (nonatomic, weak) IBOutlet UITextField *uuidTextField;

@property (nonatomic, weak) IBOutlet UITextField *majorTextField;
@property (nonatomic, weak) IBOutlet UITextField *minorTextField;
@property (nonatomic, weak) IBOutlet UITextField *powerTextField;

@property BOOL enabled;
@property NSUUID *uuid;
@property NSNumber *major;
@property NSNumber *minor;

@property UIBarButtonItem *doneButton;

@property NSNumberFormatter *numberFormatter;

- (void)updateAdvertisedRegion;

@end


@implementation APLConfigurationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing:)];

    if(region)
    {
        self.uuid = region.proximityUUID;
        self.major = region.major;
        self.minor = region.minor;
    }
    else
    {
        self.uuid = [APLDefaults sharedDefaults].defaultProximityUUID;
        self.major = [NSNumber numberWithShort:0];
        self.minor = [NSNumber numberWithShort:0];
    }
    
    if(!power)
    {
        power = [APLDefaults sharedDefaults].defaultPower;
    }
    
    self.numberFormatter = [[NSNumberFormatter alloc] init];
    self.numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (!peripheralManager)
    {
        peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    }
    else
    {
        peripheralManager.delegate = self;
    }

    // Refresh the enabled switch.
    self.enabled = self.enabledSwitch.on = peripheralManager.isAdvertising;
    
    self.uuidTextField.text = [self.uuid UUIDString];
    
    self.majorTextField.text = [self.major stringValue];
    self.minorTextField.text = [self.minor stringValue];
    self.powerTextField.text = [power stringValue];
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    peripheralManager.delegate = nil;
}


- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{

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
    else if(textField == self.powerTextField)
    {
        power = [self.numberFormatter numberFromString:textField.text];
        
        // ensure the power is negative
        if([power intValue] > 0)
        {
            power = [NSNumber numberWithInt:-[power intValue]];
            textField.text = [power stringValue];
        }
    }
    
    self.navigationItem.rightBarButtonItem = nil;
    
    [self updateAdvertisedRegion];
}


- (IBAction)toggleEnabled:(UISwitch *)sender
{
    self.enabled = sender.on;
    [self updateAdvertisedRegion];
}


- (IBAction)doneEditing:(id)sender
{
    [self.majorTextField resignFirstResponder];
    [self.minorTextField resignFirstResponder];
    [self.powerTextField resignFirstResponder];
    
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
    [self updateAdvertisedRegion];
}

- (void)updateAdvertisedRegion
{
    if(peripheralManager.state < CBPeripheralManagerStatePoweredOn)
    {
        NSString *title = NSLocalizedString(@"Bluetooth must be enabled", @"");
        NSString *message = NSLocalizedString(@"To configure your device as a beacon", @"");
        NSString *cancelButtonTitle = NSLocalizedString(@"OK", @"Cancel button title in configuration Save Changes");
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
        [errorAlert show];
        
        return;
    }
    
	[peripheralManager stopAdvertising];
    
    if(self.enabled)
    {
        // We must construct a CLBeaconRegion that represents the payload we want the device to beacon.
        NSDictionary *peripheralData = nil;
        
        region = [[CLBeaconRegion alloc] initWithProximityUUID:self.uuid major:[self.major shortValue] minor:[self.minor shortValue] identifier:BeaconIdentifier];
        peripheralData = [region peripheralDataWithMeasuredPower:power];
        
        // The region's peripheral data contains the CoreBluetooth-specific data we need to advertise.
        if(peripheralData)
        {
            [peripheralManager startAdvertising:peripheralData];
        }
    }
}

@end
