/*
     File: NewMetadataViewController.m
 Abstract: Table view controller that manages adding new a new metadata item.
  Version: 1.0
 
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
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */


#import "CommonMetadata.h"
#import "NewMetadataViewController.h"

@interface NewMetadataViewController ()

@property(nonatomic, strong) CommonMetadata *commonMetadata;
@property(nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation NewMetadataViewController

@synthesize commonMetadata = _commonMetadata;
@synthesize locationManager = _locationManager;

@synthesize titleTextField = _titleTextField;
@synthesize locationTextField = _locationTextField;
@synthesize creationDateTextField = _creationDateTextField;
@synthesize languageTextField = _languageTextField;
@synthesize descriptionTextField = _descriptionTextField;
@synthesize delegate = _delegate;

#pragma mark - UIViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)viewDidLoad
{
	self.title = @"Add Metadata";
	
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneAction:)];
	self.navigationItem.leftBarButtonItem = doneButton;
	
	self.commonMetadata = [[CommonMetadata alloc] init];
	
	self.locationManager = [[CLLocationManager alloc] init];
	self.locationManager.delegate = self;
	[self.locationManager startUpdatingLocation];
	
	self.titleTextField.text = _commonMetadata.titleString;
	self.creationDateTextField.text = [_commonMetadata.copyrightDate description];
	self.languageTextField.text = [_commonMetadata.locale localeIdentifier];
	self.locationTextField.text = [_commonMetadata.location description];
	self.descriptionTextField.text = _commonMetadata.description;
	
	self.titleTextField.clearsOnBeginEditing = YES;
	self.titleTextField.delegate = self;
	
	[super viewDidLoad];
}

- (void)viewDidUnload
{
	self.delegate = nil;
	[super viewDidUnload];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	self.commonMetadata.location = newLocation;
	self.locationTextField.text = [self.commonMetadata.location description];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

#pragma mark - Callbacks

- (void)doneAction:(id)sender
{
	self.commonMetadata.titleString = self.titleTextField.text;
	NSArray *newMetadata = [self.commonMetadata metadataItems];
	[self.delegate performSelector:@selector(finishedCreatingMetadataItem:) withObject:newMetadata];
}

@end
