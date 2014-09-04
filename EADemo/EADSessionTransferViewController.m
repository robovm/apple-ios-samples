/*
 
     File: EADSessionTransferViewController.m
 Abstract: n/a
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
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 
 */

#import "EADSessionTransferViewController.h"
#import "EADSessionController.h"

@implementation EADSessionTransferViewController

@synthesize
    receivedBytesLabel = _receivedBytesLabel,
    stringToSendTextField = _stringToSendTextField,
    hexToSendTextField = _hexToSendTextField;

// send test string to the accessory
- (IBAction)sendString:(id)sender;
{
    if ([_stringToSendTextField isFirstResponder]) {
        [_stringToSendTextField resignFirstResponder];
    }

    const char *buf = [[_stringToSendTextField text] UTF8String];
    if (buf)
    {
        uint32_t len = strlen(buf) + 1;
        [[EADSessionController sharedController] writeData:[NSData dataWithBytes:buf length:len]];
    }
}

// Interpret a UITextField's string at a sequence of hex bytes and send those bytes to the accessory
- (IBAction)sendHex:(id)sender;
{
    if ([_hexToSendTextField isFirstResponder]) {
        [_hexToSendTextField resignFirstResponder];
    }

    const char *buf = [[_hexToSendTextField text] UTF8String];
    NSMutableData *data = [NSMutableData data];
    if (buf)
    {
        uint32_t len = strlen(buf);

        char singleNumberString[3] = {'\0', '\0', '\0'};
        uint32_t singleNumber = 0;
        for(uint32_t i = 0 ; i < len; i+=2)
        {
            if ( ((i+1) < len) && isxdigit(buf[i]) && (isxdigit(buf[i+1])) )
            {
                singleNumberString[0] = buf[i];
                singleNumberString[1] = buf[i + 1];
                sscanf(singleNumberString, "%x", &singleNumber);
                uint8_t tmp = (uint8_t)(singleNumber & 0x000000FF);
                [data appendBytes:(void *)(&tmp) length:1];
            }
            else
            {
                break;
            }
        }

        [[EADSessionController sharedController] writeData:data];
    }
}

// send 10K of data to the accessory.
- (IBAction)send10K:(id)sender
{
#define STRESS_TEST_BYTE_COUNT 10000
    uint8_t buf[STRESS_TEST_BYTE_COUNT];
    for(int i = 0; i < STRESS_TEST_BYTE_COUNT; i++) {
        buf[i] = (i & 0xFF);  // fill buf with incrementing bytes;
    }

	[[EADSessionController sharedController] writeData:[NSData dataWithBytes:buf length:STRESS_TEST_BYTE_COUNT]];
}

#pragma mark UIViewController

- (void)viewWillAppear:(BOOL)animated
{
    // watch for the accessory being disconnected
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_accessoryDidDisconnect:) name:EAAccessoryDidDisconnectNotification object:nil];
    // watch for received data from the accessory
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_sessionDataReceived:) name:EADSessionDataReceivedNotification object:nil];

    EADSessionController *sessionController = [EADSessionController sharedController];

    _accessory = [[sessionController accessory] retain];
    [self setTitle:[sessionController protocolString]];
    [sessionController openSession];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // remove the observers
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EAAccessoryDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EADSessionDataReceivedNotification object:nil];

    EADSessionController *sessionController = [EADSessionController sharedController];

    [sessionController closeSession];
    [_accessory release];
    _accessory = nil;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.receivedBytesLabel = nil;
    self.stringToSendTextField = nil;
    self.hexToSendTextField = nil;
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark Internal

- (void)_accessoryDidDisconnect:(NSNotification *)notification
{
    if ([[self navigationController] topViewController] == self)
    {
        EAAccessory *disconnectedAccessory = [[notification userInfo] objectForKey:EAAccessoryKey];
        if ([disconnectedAccessory connectionID] == [_accessory connectionID])
        {
            [[self navigationController] popViewControllerAnimated:YES];

        }
    }
}

// Data was received from the accessory, real apps should do something with this data but currently:
//    1. bytes counter is incremented
//    2. bytes are read from the session controller and thrown away
- (void)_sessionDataReceived:(NSNotification *)notification
{
    EADSessionController *sessionController = (EADSessionController *)[notification object];
    uint32_t bytesAvailable = 0;

    while ((bytesAvailable = [sessionController readBytesAvailable]) > 0) {
        NSData *data = [sessionController readData:bytesAvailable];
        if (data) {
            _totalBytesRead += bytesAvailable;
        }
    }

    [_receivedBytesLabel setText:[NSString stringWithFormat:@"Bytes Received from Session: %d", _totalBytesRead]];
}

@end
