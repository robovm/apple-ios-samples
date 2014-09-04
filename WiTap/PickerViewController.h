/*
     File: PickerViewController.h
 Abstract: Displays a table of services that the user can pick.
  Version: 2.1
 
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

@import UIKit;

@protocol PickerDelegate;

@interface PickerViewController : UITableViewController

// properties you must set before starting and must not change while started

@property (nonatomic, copy,   readwrite) NSString *             type;

// properties you mustn't set while started

@property (nonatomic, weak,   readwrite) id<PickerDelegate>     delegate;

// properties you can set at any time

@property (nonatomic, strong, readwrite) NSNetService *         localService;
    // Setting this shows the service name to the user at the top of the picker 
    // and prevents that service from showing up in the list.

- (void)start;
    // Called to start the picker.  It's not legal to start it when it's already started.
- (void)stop;
    // Called to stop the picker.  It's OK to stop a picker that's not started.

- (void)cancelConnect;
    // Call this to tell the picker that you've cancelled a connection attempt.  In 
    // response it dismisses the connection-in-progress UI.  See the discussion associated 
    // with the PickerDelegate protocol below.

@end

@protocol PickerDelegate <NSObject>

@required

- (void)pickerViewController:(PickerViewController *)controller connectToService:(NSNetService *)service;
    // Called when the user selects a service to connect to.  The picker has already put up 
    // the connection-in-progress UI.  The delegate should start the connection and, when it's 
    // finished, either dismiss the picker (if the connection was a success) or call 
    // -cancelConnection (if something went wrong).
    
- (void)pickerViewControllerDidCancelConnect:(PickerViewController *)controller;
    // Called when the picker itself wants to cancel the connection.  It does this when the user 
    // taps the Cancel button in the connection-in-progress UI.  At the time this is called the 
    // connection-in-progress UI has been dismissed; there's no need to call -cancelConnect.

@end
