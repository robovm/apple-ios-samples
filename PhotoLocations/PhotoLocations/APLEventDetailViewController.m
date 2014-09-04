
/*
     File: APLEventDetailViewController.m
 Abstract: The table view controller responsible for displaying the time, coordinates, and photo of an event, and allowing the user to select a photo for the event, or delete the existing photo.
 
  Version: 2.0
 
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

#import "APLEventDetailViewController.h"
#import "APLEvent.h"
#import "APLPhoto.h"


@interface APLEventDetailViewController ()

@property (nonatomic, weak) IBOutlet UILabel *timeLabel;
@property (nonatomic, weak) IBOutlet UILabel *coordinatesLabel;
@property (nonatomic, weak) IBOutlet UIButton *deletePhotoButton;
@property (nonatomic, weak) IBOutlet UIImageView *photoImageView;

@end


@implementation APLEventDetailViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// A date formatter for the creation date.
    static NSDateFormatter *dateFormatter = nil;
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	}
	
	// A date formatter for the coordinates.
	static NSNumberFormatter *numberFormatter;
	if (numberFormatter == nil) {
		numberFormatter = [[NSNumberFormatter alloc] init];
		[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[numberFormatter setMaximumFractionDigits:3];
	}
	
	self.timeLabel.text = [dateFormatter stringFromDate:[self.event creationDate]];
	
    NSString *formatString = NSLocalizedString(@"latitude:%@, longitude%@", @"coordinates string in detail view");
	NSString *coordinatesString = [[NSString alloc] initWithFormat:formatString,
							 [numberFormatter stringFromNumber:[self.event latitude]],
							 [numberFormatter stringFromNumber:[self.event longitude]]];
	self.coordinatesLabel.text = coordinatesString;
	
	[self updatePhotoInfo];
}


#pragma mark - Editing the photo

- (IBAction)deletePhoto:(id)sender
{
	/*
	 If the event already has a photo, delete the Photo object and dispose of the thumbnail.
	 Because the relationship was modeled in both directions, the event's relationship to the photo will automatically be set to nil.
	 */
	
	NSManagedObjectContext *context = self.event.managedObjectContext;
	[context deleteObject:self.event.photo];
	self.event.thumbnail = nil;
	
	// Commit the change.
	NSError *error ;
	if (![self.event.managedObjectContext save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
	}

	// Update the user interface appropriately.
	[self updatePhotoInfo];
}


- (IBAction)choosePhoto:(id)sender
{
	// Show an image picker to allow the user to choose a new photo.
	
	UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
	imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:NULL];
}



- (void)updatePhotoInfo
{
	// Synchronize the photo image view and the text on the photo button with the event's photo.
	UIImage *image = self.event.photo.image;

	self.photoImageView.image = image;
	if (image) {
		self.deletePhotoButton.enabled = YES;
	}
	else {
		self.deletePhotoButton.enabled = NO;
	}
}


#pragma mark - Image picker delegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)selectedImage editingInfo:(NSDictionary *)editingInfo
{
    APLEvent *event = self.event;
	NSManagedObjectContext *context = event.managedObjectContext;

	// If the event already has a photo, delete it.
	if (event.photo) {
		[context deleteObject:event.photo];
	}
	
	// Create a new photo object and set the image.
	APLPhoto *photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:context];
	photo.image = selectedImage;
	
	// Associate the photo object with the event.
	event.photo = photo;	
	
	// Create a thumbnail version of the image for the event object.
	CGSize size = selectedImage.size;
	CGFloat ratio = 0;
	if (size.width > size.height) {
		ratio = 44.0 / size.width;
	}
	else {
		ratio = 44.0 / size.height;
	}
	CGRect rect = CGRectMake(0.0, 0.0, ratio * size.width, ratio * size.height);
	
	UIGraphicsBeginImageContext(rect.size);
	[selectedImage drawInRect:rect];
	event.thumbnail = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	// Commit the change.
	NSError *error = nil;
	if (![event.managedObjectContext save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
	}

	// Update the user interface appropriately.
	[self updatePhotoInfo];

	[self dismissViewControllerAnimated:YES completion:NULL];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	// The user canceled -- simply dismiss the image picker.
	[self dismissViewControllerAnimated:YES completion:NULL];
}


@end
