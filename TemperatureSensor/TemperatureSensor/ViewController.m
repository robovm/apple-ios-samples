/*
 
 File: ViewController.m
 
 Abstract: User interface to display a list of discovered peripherals
 and allow the user to connect to them.
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
 Apple Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. 
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
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
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import <Foundation/Foundation.h>

#import "ViewController.h"
#import "LeDiscovery.h"
#import "LeTemperatureAlarmService.h"



@interface ViewController ()  <LeDiscoveryDelegate, LeTemperatureAlarmProtocol, UITableViewDataSource, UITableViewDelegate>
@property (retain, nonatomic) LeTemperatureAlarmService *currentlyDisplayingService;
@property (retain, nonatomic) NSMutableArray            *connectedServices;
@property (retain, nonatomic) IBOutlet UILabel          *currentlyConnectedSensor;
@property (retain, nonatomic) IBOutlet UILabel          *currentTemperatureLabel;
@property (retain, nonatomic) IBOutlet UILabel          *maxAlarmLabel,*minAlarmLabel;
@property (retain, nonatomic) IBOutlet UITableView      *sensorsTable;
@property (retain, nonatomic) IBOutlet UIStepper        *maxAlarmStepper,*minAlarmStepper;
- (IBAction)maxStepperChanged;
- (IBAction)minStepperChanged;
@end



@implementation ViewController


@synthesize currentlyDisplayingService;
@synthesize connectedServices;
@synthesize currentlyConnectedSensor;
@synthesize sensorsTable;
@synthesize currentTemperatureLabel;
@synthesize maxAlarmLabel,minAlarmLabel;
@synthesize maxAlarmStepper,minAlarmStepper;



#pragma mark -
#pragma mark View lifecycle
/****************************************************************************/
/*								View Lifecycle                              */
/****************************************************************************/
- (void) viewDidLoad
{
    [super viewDidLoad];
    
    connectedServices = [NSMutableArray new];
    
	[[LeDiscovery sharedInstance] setDiscoveryDelegate:self];
    [[LeDiscovery sharedInstance] setPeripheralDelegate:self];
    [[LeDiscovery sharedInstance] startScanningForUUIDString:kTemperatureServiceUUIDString];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackgroundNotification:) name:kAlarmServiceEnteredBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterForegroundNotification:) name:kAlarmServiceEnteredForegroundNotification object:nil];
}


- (void) viewDidUnload
{
    [self setCurrentlyConnectedSensor:nil];
    [self setCurrentTemperatureLabel:nil];
    [self setMaxAlarmLabel:nil];
    [self setMinAlarmLabel:nil];
    [self setSensorsTable:nil];
    [self setMaxAlarmStepper:nil];
    [self setMinAlarmStepper:nil];
    [self setConnectedServices:nil];
    [self setCurrentlyDisplayingService:nil];
    
    [[LeDiscovery sharedInstance] stopScanning];
    
    [super viewDidUnload];
}


- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void) dealloc 
{
    [[LeDiscovery sharedInstance] stopScanning];
    
    [currentTemperatureLabel release];
    [maxAlarmLabel release];
    [minAlarmLabel release];
    [sensorsTable release];
    [maxAlarmStepper release];
    [minAlarmStepper release];
    
    [currentlyConnectedSensor release];
    [connectedServices release];
    [currentlyDisplayingService release];
    
    [super dealloc];
}



#pragma mark -
#pragma mark LeTemperatureAlarm Interactions
/****************************************************************************/
/*                  LeTemperatureAlarm Interactions                         */
/****************************************************************************/
- (LeTemperatureAlarmService*) serviceForPeripheral:(CBPeripheral *)peripheral
{
    for (LeTemperatureAlarmService *service in connectedServices) {
        if ( [[service peripheral] isEqual:peripheral] ) {
            return service;
        }
    }
    
    return nil;
}

- (void)didEnterBackgroundNotification:(NSNotification*)notification
{   
    NSLog(@"Entered background notification called.");
    for (LeTemperatureAlarmService *service in self.connectedServices) {
        [service enteredBackground];
    }
}

- (void)didEnterForegroundNotification:(NSNotification*)notification
{
    NSLog(@"Entered foreground notification called.");
    for (LeTemperatureAlarmService *service in self.connectedServices) {
        [service enteredForeground];
    }    
}


#pragma mark -
#pragma mark LeTemperatureAlarmProtocol Delegate Methods
/****************************************************************************/
/*				LeTemperatureAlarmProtocol Delegate Methods					*/
/****************************************************************************/
/** Broke the high or low temperature bound */
- (void) alarmService:(LeTemperatureAlarmService*)service didSoundAlarmOfType:(AlarmType)alarm
{
    if (![service isEqual:currentlyDisplayingService])
        return;
    
    NSString *title;
    NSString *message;
    
	switch (alarm) {
		case kAlarmLow: 
			NSLog(@"Alarm low");
            title     = @"Alarm Notification";
            message   = @"Low Alarm Fired";
			break;
            
		case kAlarmHigh: 
			NSLog(@"Alarm high");
            title     = @"Alarm Notification";
            message   = @"High Alarm Fired";
			break;
	}
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}


/** Back into normal values */
- (void) alarmServiceDidStopAlarm:(LeTemperatureAlarmService*)service
{
    NSLog(@"Alarm stopped");
}


/** Current temp changed */
- (void) alarmServiceDidChangeTemperature:(LeTemperatureAlarmService*)service
{  
    if (service != currentlyDisplayingService)
        return;
    
    NSInteger currentTemperature = (int)[service temperature];
    [currentTemperatureLabel setText:[NSString stringWithFormat:@"%dº", currentTemperature]];
}


/** Max or Min change request complete */
- (void) alarmServiceDidChangeTemperatureBounds:(LeTemperatureAlarmService*)service
{
    if (service != currentlyDisplayingService) 
        return;
    
    [maxAlarmLabel setText:[NSString stringWithFormat:@"MAX %dº", (int)[currentlyDisplayingService maximumTemperature]]];
    [minAlarmLabel setText:[NSString stringWithFormat:@"MIN %dº", (int)[currentlyDisplayingService minimumTemperature]]];
    
    [maxAlarmStepper setEnabled:YES];
    [minAlarmStepper setEnabled:YES];
}


/** Peripheral connected or disconnected */
- (void) alarmServiceDidChangeStatus:(LeTemperatureAlarmService*)service
{
    if ( [[service peripheral] isConnected] ) {
        NSLog(@"Service (%@) connected", service.peripheral.name);
        if (![connectedServices containsObject:service]) {
            [connectedServices addObject:service];
        }
    }
    
    else {
        NSLog(@"Service (%@) disconnected", service.peripheral.name);
        if ([connectedServices containsObject:service]) {
            [connectedServices removeObject:service];
        }
    }
}


/** Central Manager reset */
- (void) alarmServiceDidReset
{
    [connectedServices removeAllObjects];
}



#pragma mark -
#pragma mark TableView Delegates
/****************************************************************************/
/*							TableView Delegates								*/
/****************************************************************************/
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell	*cell;
	CBPeripheral	*peripheral;
	NSArray			*devices;
	NSInteger		row	= [indexPath row];
    static NSString *cellID = @"DeviceList";
    
	cell = [tableView dequeueReusableCellWithIdentifier:cellID];
	if (!cell)
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID] autorelease];
    
	if ([indexPath section] == 0) {
		devices = [[LeDiscovery sharedInstance] connectedServices];
        peripheral = [(LeTemperatureAlarmService*)[devices objectAtIndex:row] peripheral];
        
	} else {
		devices = [[LeDiscovery sharedInstance] foundPeripherals];
        peripheral = (CBPeripheral*)[devices objectAtIndex:row];
	}
    
    if ([[peripheral name] length])
        [[cell textLabel] setText:[peripheral name]];
    else
        [[cell textLabel] setText:@"Peripheral"];
		
    [[cell detailTextLabel] setText: [peripheral isConnected] ? @"Connected" : @"Not connected"];
    
	return cell;
}


- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}


- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger	res = 0;
    
	if (section == 0)
		res = [[[LeDiscovery sharedInstance] connectedServices] count];
	else
		res = [[[LeDiscovery sharedInstance] foundPeripherals] count];
    
	return res;
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{  
	CBPeripheral	*peripheral;
	NSArray			*devices;
	NSInteger		row	= [indexPath row];
	
	if ([indexPath section] == 0) {
		devices = [[LeDiscovery sharedInstance] connectedServices];
        peripheral = [(LeTemperatureAlarmService*)[devices objectAtIndex:row] peripheral];
	} else {
		devices = [[LeDiscovery sharedInstance] foundPeripherals];
    	peripheral = (CBPeripheral*)[devices objectAtIndex:row];
	}
    
	if (![peripheral isConnected]) {
		[[LeDiscovery sharedInstance] connectPeripheral:peripheral];
        [currentlyConnectedSensor setText:[peripheral name]];
        
        [currentlyConnectedSensor setEnabled:NO];
        [currentTemperatureLabel setEnabled:NO];
        [maxAlarmLabel setEnabled:NO];
        [minAlarmLabel setEnabled:NO];
    }
    
	else {
        
        if ( currentlyDisplayingService != nil ) {
            [currentlyDisplayingService release];
            currentlyDisplayingService = nil;
        }
        
        currentlyDisplayingService = [self serviceForPeripheral:peripheral];
        [currentlyDisplayingService retain];
        
        [currentlyConnectedSensor setText:[peripheral name]];
        
        [currentTemperatureLabel setText:[NSString stringWithFormat:@"%dº", (int)[currentlyDisplayingService temperature]]];
        [maxAlarmLabel setText:[NSString stringWithFormat:@"MAX %dº", (int)[currentlyDisplayingService maximumTemperature]]];
        [minAlarmLabel setText:[NSString stringWithFormat:@"MIN %dº", (int)[currentlyDisplayingService minimumTemperature]]];
        
        [currentlyConnectedSensor setEnabled:YES];
        [currentTemperatureLabel setEnabled:YES];
        [maxAlarmLabel setEnabled:YES];
        [minAlarmLabel setEnabled:YES];
    }
}


#pragma mark -
#pragma mark LeDiscoveryDelegate 
/****************************************************************************/
/*                       LeDiscoveryDelegate Methods                        */
/****************************************************************************/
- (void) discoveryDidRefresh 
{
    [sensorsTable reloadData];
}

- (void) discoveryStatePoweredOff 
{
    NSString *title     = @"Bluetooth Power";
    NSString *message   = @"You must turn on Bluetooth in Settings in order to use LE";
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}



#pragma mark -
#pragma mark App IO
/****************************************************************************/
/*                              App IO Methods                              */
/****************************************************************************/
/** Increase or decrease the maximum alarm setting */
- (IBAction) maxStepperChanged
{
    int newTemp = [currentlyDisplayingService maximumTemperature] * 10;
    
    if (maxAlarmStepper.value > 0) {
        newTemp+=10;
        NSLog(@"increasing MAX temp to %d", newTemp);
    }
    
    if (maxAlarmStepper.value < 0) {
        newTemp-=10;
        NSLog(@"decreasing MAX temp to %d", newTemp);
    }
    
    // We're not interested in the actual VALUE of the stepper, just if it's increased or decreased, so reset it to 0 after a press
    [maxAlarmStepper setValue:0];
    
    // Disable the stepper so we don't send multiple requests to the peripheral
    [maxAlarmStepper setEnabled:NO];
    
    [currentlyDisplayingService writeHighAlarmTemperature:newTemp];
}


/** Increase or decrease the minimum alarm setting */
- (IBAction) minStepperChanged
{
    int newTemp = [currentlyDisplayingService minimumTemperature] * 10;
    
    if (minAlarmStepper.value > 0) {
        newTemp+=10;
        NSLog(@"increasing MIN temp to %d", newTemp);
    }
    
    if (minAlarmStepper.value < 0) {
        newTemp-=10;
        NSLog(@"decreasing MIN temp to %d", newTemp);
    }
    
    // We're not interested in the actual VALUE of the stepper, just if it's increased or decreased, so reset it to 0 after a press
    [minAlarmStepper setValue:0];    
    
    // Disable the stepper so we don't send multiple requests to the peripheral
    [minAlarmStepper setEnabled:NO];
    
    [currentlyDisplayingService writeLowAlarmTemperature:newTemp];
}
@end
