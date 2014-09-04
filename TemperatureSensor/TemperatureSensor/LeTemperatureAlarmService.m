/*

 File: LeTemperatureAlarmService.m
 
 Abstract: Temperature Alarm Service Code - Connect to a peripheral 
 get notified when the temperature changes and goes past settable
 maximum and minimum temperatures.
 
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



#import "LeTemperatureAlarmService.h"
#import "LeDiscovery.h"


NSString *kTemperatureServiceUUIDString = @"DEADF154-0000-0000-0000-0000DEADF154";
NSString *kCurrentTemperatureCharacteristicUUIDString = @"CCCCFFFF-DEAD-F154-1319-740381000000";
NSString *kMinimumTemperatureCharacteristicUUIDString = @"C0C0C0C0-DEAD-F154-1319-740381000000";
NSString *kMaximumTemperatureCharacteristicUUIDString = @"EDEDEDED-DEAD-F154-1319-740381000000";
NSString *kAlarmCharacteristicUUIDString = @"AAAAAAAA-DEAD-F154-1319-740381000000";

NSString *kAlarmServiceEnteredBackgroundNotification = @"kAlarmServiceEnteredBackgroundNotification";
NSString *kAlarmServiceEnteredForegroundNotification = @"kAlarmServiceEnteredForegroundNotification";

@interface LeTemperatureAlarmService() <CBPeripheralDelegate> {
@private
    CBPeripheral		*servicePeripheral;
    
    CBService			*temperatureAlarmService;
    
    CBCharacteristic    *tempCharacteristic;
    CBCharacteristic	*minTemperatureCharacteristic;
    CBCharacteristic    *maxTemperatureCharacteristic;
    CBCharacteristic    *alarmCharacteristic;
    
    CBUUID              *temperatureAlarmUUID;
    CBUUID              *minimumTemperatureUUID;
    CBUUID              *maximumTemperatureUUID;
    CBUUID              *currentTemperatureUUID;

    id<LeTemperatureAlarmProtocol>	peripheralDelegate;
}
@end



@implementation LeTemperatureAlarmService


@synthesize peripheral = servicePeripheral;


#pragma mark -
#pragma mark Init
/****************************************************************************/
/*								Init										*/
/****************************************************************************/
- (id) initWithPeripheral:(CBPeripheral *)peripheral controller:(id<LeTemperatureAlarmProtocol>)controller
{
    self = [super init];
    if (self) {
        servicePeripheral = [peripheral retain];
        [servicePeripheral setDelegate:self];
		peripheralDelegate = controller;
        
        minimumTemperatureUUID	= [[CBUUID UUIDWithString:kMinimumTemperatureCharacteristicUUIDString] retain];
        maximumTemperatureUUID	= [[CBUUID UUIDWithString:kMaximumTemperatureCharacteristicUUIDString] retain];
        currentTemperatureUUID	= [[CBUUID UUIDWithString:kCurrentTemperatureCharacteristicUUIDString] retain];
        temperatureAlarmUUID	= [[CBUUID UUIDWithString:kAlarmCharacteristicUUIDString] retain];
	}
    return self;
}


- (void) dealloc {
	if (servicePeripheral) {
		[servicePeripheral setDelegate:[LeDiscovery sharedInstance]];
		[servicePeripheral release];
		servicePeripheral = nil;
        
        [minimumTemperatureUUID release];
        [maximumTemperatureUUID release];
        [currentTemperatureUUID release];
        [temperatureAlarmUUID release];
    }
    [super dealloc];
}


- (void) reset
{
	if (servicePeripheral) {
		[servicePeripheral release];
		servicePeripheral = nil;
	}
}



#pragma mark -
#pragma mark Service interaction
/****************************************************************************/
/*							Service Interactions							*/
/****************************************************************************/
- (void) start
{
	CBUUID	*serviceUUID	= [CBUUID UUIDWithString:kTemperatureServiceUUIDString];
	NSArray	*serviceArray	= [NSArray arrayWithObjects:serviceUUID, nil];

    [servicePeripheral discoverServices:serviceArray];
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
	NSArray		*services	= nil;
	NSArray		*uuids	= [NSArray arrayWithObjects:currentTemperatureUUID, // Current Temp
								   minimumTemperatureUUID, // Min Temp
								   maximumTemperatureUUID, // Max Temp
								   temperatureAlarmUUID, // Alarm Characteristic
								   nil];

	if (peripheral != servicePeripheral) {
		NSLog(@"Wrong Peripheral.\n");
		return ;
	}
    
    if (error != nil) {
        NSLog(@"Error %@\n", error);
		return ;
	}

	services = [peripheral services];
	if (!services || ![services count]) {
		return ;
	}

	temperatureAlarmService = nil;
    
	for (CBService *service in services) {
		if ([[service UUID] isEqual:[CBUUID UUIDWithString:kTemperatureServiceUUIDString]]) {
			temperatureAlarmService = service;
			break;
		}
	}

	if (temperatureAlarmService) {
		[peripheral discoverCharacteristics:uuids forService:temperatureAlarmService];
	}
}


- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error;
{
	NSArray		*characteristics	= [service characteristics];
	CBCharacteristic *characteristic;
    
	if (peripheral != servicePeripheral) {
		NSLog(@"Wrong Peripheral.\n");
		return ;
	}
	
	if (service != temperatureAlarmService) {
		NSLog(@"Wrong Service.\n");
		return ;
	}
    
    if (error != nil) {
		NSLog(@"Error %@\n", error);
		return ;
	}
    
	for (characteristic in characteristics) {
        NSLog(@"discovered characteristic %@", [characteristic UUID]);
        
		if ([[characteristic UUID] isEqual:minimumTemperatureUUID]) { // Min Temperature.
            NSLog(@"Discovered Minimum Alarm Characteristic");
			minTemperatureCharacteristic = [characteristic retain];
			[peripheral readValueForCharacteristic:characteristic];
		}
        else if ([[characteristic UUID] isEqual:maximumTemperatureUUID]) { // Max Temperature.
            NSLog(@"Discovered Maximum Alarm Characteristic");
			maxTemperatureCharacteristic = [characteristic retain];
			[peripheral readValueForCharacteristic:characteristic];
		}
        else if ([[characteristic UUID] isEqual:temperatureAlarmUUID]) { // Alarm
            NSLog(@"Discovered Alarm Characteristic");
			alarmCharacteristic = [characteristic retain];
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
		}
        else if ([[characteristic UUID] isEqual:currentTemperatureUUID]) { // Current Temp
            NSLog(@"Discovered Temperature Characteristic");
			tempCharacteristic = [characteristic retain];
			[peripheral readValueForCharacteristic:tempCharacteristic];
			[peripheral setNotifyValue:YES forCharacteristic:characteristic];
		} 
	}
}



#pragma mark -
#pragma mark Characteristics interaction
/****************************************************************************/
/*						Characteristics Interactions						*/
/****************************************************************************/
- (void) writeLowAlarmTemperature:(int)low 
{
    NSData  *data	= nil;
    int16_t value	= (int16_t)low;
    
    if (!servicePeripheral) {
        NSLog(@"Not connected to a peripheral");
		return ;
    }

    if (!minTemperatureCharacteristic) {
        NSLog(@"No valid minTemp characteristic");
        return;
    }
    
    data = [NSData dataWithBytes:&value length:sizeof (value)];
    [servicePeripheral writeValue:data forCharacteristic:minTemperatureCharacteristic type:CBCharacteristicWriteWithResponse];
}


- (void) writeHighAlarmTemperature:(int)high
{
    NSData  *data	= nil;
    int16_t value	= (int16_t)high;

    if (!servicePeripheral) {
        NSLog(@"Not connected to a peripheral");
    }

    if (!maxTemperatureCharacteristic) {
        NSLog(@"No valid minTemp characteristic");
        return;
    }

    data = [NSData dataWithBytes:&value length:sizeof (value)];
    [servicePeripheral writeValue:data forCharacteristic:maxTemperatureCharacteristic type:CBCharacteristicWriteWithResponse];
}


/** If we're connected, we don't want to be getting temperature change notifications while we're in the background.
 We will want alarm notifications, so we don't turn those off.
 */
- (void)enteredBackground
{
    // Find the fishtank service
    for (CBService *service in [servicePeripheral services]) {
        if ([[service UUID] isEqual:[CBUUID UUIDWithString:kTemperatureServiceUUIDString]]) {
            
            // Find the temperature characteristic
            for (CBCharacteristic *characteristic in [service characteristics]) {
                if ( [[characteristic UUID] isEqual:[CBUUID UUIDWithString:kCurrentTemperatureCharacteristicUUIDString]] ) {
                    
                    // And STOP getting notifications from it
                    [servicePeripheral setNotifyValue:NO forCharacteristic:characteristic];
                }
            }
        }
    }
}

/** Coming back from the background, we want to register for notifications again for the temperature changes */
- (void)enteredForeground
{
    // Find the fishtank service
    for (CBService *service in [servicePeripheral services]) {
        if ([[service UUID] isEqual:[CBUUID UUIDWithString:kTemperatureServiceUUIDString]]) {
            
            // Find the temperature characteristic
            for (CBCharacteristic *characteristic in [service characteristics]) {
                if ( [[characteristic UUID] isEqual:[CBUUID UUIDWithString:kCurrentTemperatureCharacteristicUUIDString]] ) {
                    
                    // And START getting notifications from it
                    [servicePeripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
            }
        }
    }
}

- (CGFloat) minimumTemperature
{
    CGFloat result  = NAN;
    int16_t value	= 0;
	
    if (minTemperatureCharacteristic) {
        [[minTemperatureCharacteristic value] getBytes:&value length:sizeof (value)];
        result = (CGFloat)value / 10.0f;
    }
    return result;
}


- (CGFloat) maximumTemperature
{
    CGFloat result  = NAN;
    int16_t	value	= 0;
    
    if (maxTemperatureCharacteristic) {
        [[maxTemperatureCharacteristic value] getBytes:&value length:sizeof (value)];
        result = (CGFloat)value / 10.0f;
    }
    return result;
}


- (CGFloat) temperature
{
    CGFloat result  = NAN;
    int16_t	value	= 0;

	if (tempCharacteristic) {
        [[tempCharacteristic value] getBytes:&value length:sizeof (value)];
        result = (CGFloat)value / 10.0f;
    }
    return result;
}


- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    uint8_t alarmValue  = 0;
    
	if (peripheral != servicePeripheral) {
		NSLog(@"Wrong peripheral\n");
		return ;
	}

    if ([error code] != 0) {
		NSLog(@"Error %@\n", error);
		return ;
	}

    /* Temperature change */
    if ([[characteristic UUID] isEqual:currentTemperatureUUID]) {
        [peripheralDelegate alarmServiceDidChangeTemperature:self];
        return;
    }
    
    /* Alarm change */
    if ([[characteristic UUID] isEqual:temperatureAlarmUUID]) {

        /* get the value for the alarm */
        [[alarmCharacteristic value] getBytes:&alarmValue length:sizeof (alarmValue)];

        NSLog(@"alarm!  0x%x", alarmValue);
        if (alarmValue & 0x01) {
            /* Alarm is firing */
            if (alarmValue & 0x02) {
                [peripheralDelegate alarmService:self didSoundAlarmOfType:kAlarmLow];
			} else {
                [peripheralDelegate alarmService:self didSoundAlarmOfType:kAlarmHigh];
			}
        } else {
            [peripheralDelegate alarmServiceDidStopAlarm:self];
        }

        return;
    }

    /* Upper or lower bounds changed */
    if ([characteristic.UUID isEqual:minimumTemperatureUUID] || [characteristic.UUID isEqual:maximumTemperatureUUID]) {
        [peripheralDelegate alarmServiceDidChangeTemperatureBounds:self];
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    /* When a write occurs, need to set off a re-read of the local CBCharacteristic to update its value */
    [peripheral readValueForCharacteristic:characteristic];
    
    /* Upper or lower bounds changed */
    if ([characteristic.UUID isEqual:minimumTemperatureUUID] || [characteristic.UUID isEqual:maximumTemperatureUUID]) {
        [peripheralDelegate alarmServiceDidChangeTemperatureBounds:self];
    }
}
@end
