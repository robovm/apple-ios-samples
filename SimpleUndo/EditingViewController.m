/*
     File: EditingViewController.m
 Abstract: A generic view controller responsible for editing a field 
 of data (text or date).  The controller defines a protocol to communicate 
 changes to the view controller that manages the object being edited.
 
  Version: 1.2
 
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

#import "EditingViewController.h"

@interface EditingViewController ()
/// Things for IB
@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, weak) IBOutlet UIDatePicker *datePicker;
@end


@implementation EditingViewController

#pragma mark - View lifecycle

// -------------------------------------------------------------------------------
//	viewWillAppear:
// -------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{	
	[super viewWillAppear:animated];
    
    // Set the title to the user-visible name of the field.
    self.title = self.editedPropertyDisplayName;
	
	// Update user interface according to state.
    if (self.editingDate)
    {
        // Display the date picker.
        self.textField.hidden = YES;
        self.datePicker.hidden = NO;
        
        // Use KVC to retrieve the current date associated with editedPropertyKey
        // of editedObject.
		NSDate *date = [self.editedObject valueForKey:self.editedPropertyKey];
        if (date == nil) date = [NSDate date];
        self.datePicker.date = date;
    }
	else
    {
        // Display the text field.
        self.textField.hidden = NO;
        self.datePicker.hidden = YES;
        
        // Use KVC to retrieve the current string associated with editedPropertyKey
        // of editedObject.
        self.textField.text = [self.editedObject valueForKey:self.editedPropertyKey];
		self.textField.placeholder = self.title;
        [self.textField becomeFirstResponder];
    }
}

#pragma mark - Rotation

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
// -------------------------------------------------------------------------------
//	shouldAutorotateToInterfaceOrientation:
//  Disable rotation on iOS 5.x and earlier.  Note, for iOS 6.0 and later all you
//  need is "UISupportedInterfaceOrientations" defined in your Info.plist
// -------------------------------------------------------------------------------
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);;
}
#endif

#pragma mark - IB Actions

// -------------------------------------------------------------------------------
//	save
//  IBAction for the Save bar button item.
// -------------------------------------------------------------------------------
- (IBAction)save
{
    // Pass the current value to the source controller, then pop.
    if (self.editingDate)
		[self.sourceController setValue:self.datePicker.date forEditedProperty:self.editedPropertyKey];
	else
		[self.sourceController setValue:self.textField.text forEditedProperty:self.editedPropertyKey];
	
    [self.navigationController popViewControllerAnimated:YES];
}

// -------------------------------------------------------------------------------
//	cancel
//  IBAction for the Cancel bar button item.
// -------------------------------------------------------------------------------
- (IBAction)cancel
{
    // Don't pass the current value to the edited object, just pop.
    [self.navigationController popViewControllerAnimated:YES];
}

@end

