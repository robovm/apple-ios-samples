/*
 File: PrintPhotoViewController.m
 Abstract: ViewController object to handle picking, viewing, and printing
 a photo.
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
 
 Copyright (C) 2010-2011 Apple Inc. All Rights Reserved.
 
 */

#import "PrintPhotoViewController.h"
#import "PrintPhotoPageRenderer.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation PrintPhotoViewController

@synthesize toolbar, printButton, pickerButton, imageURL, popover;

// Comment out to draw at print time rather than hand the image off to UIKit.
// When printing single images on a page, using "direct submission" is the preferred 
// approach unless you need custom placement and scaling of the image. 
#define DIRECT_SUBMISSION 1   

// Leave this line intact to use an ALAsset object to obtain a screen-size image and use 
// that instead of the original image. Doing this allows viewing of images of a very
// large size that would otherwise be prohibitively large on most
// iOS devices.
#define USE_SCREEN_IMAGE 1

#define kToolbarHeight 48

#pragma mark memory management methods

- (void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  // Release any cached data, images, etc that aren't in use.
  NSLog(@"didReceiveMemoryWarning message sent to PrintPhotoViewController"); 
}

- (void)dealloc {
   self.toolbar = nil;
   self.printButton = nil;
   self.pickerButton = nil;
   self.imageURL = nil;
   [super dealloc];
}

#pragma mark view controller override methods

- (void)setupToolbarItems {
  // Use the system camera icon as the toolbar icon for choosing to select a photo from the photo library.
  self.pickerButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(showImagePicker:)]autorelease];
  
  // Only add an icon for selecting printing if printing is available on this device.
  if([UIPrintInteractionController isPrintingAvailable]){
    UIBarButtonItem *spaceItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
    self.printButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(printImage:)]autorelease];
    self.toolbar.items = [NSArray arrayWithObjects: self.pickerButton, spaceItem, self.printButton, nil];
  }else
    self.toolbar.items = [NSArray arrayWithObjects: self.pickerButton, nil];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  CGRect toolbarFrame;
  NSString *path;
  [super viewDidLoad];
  
  CGRect bounds = [[UIScreen mainScreen] applicationFrame];
  // Set the properties on our image view.
  UIImageView *imageView = (UIImageView *)self.view;
  imageView.contentMode = UIViewContentModeScaleAspectFit;
  imageView.backgroundColor = [UIColor blackColor];

  // Obtain the starting image presented prior to the user choosing one.
  path = [[NSBundle mainBundle] pathForResource:@"FirstImage" ofType:@"jpg"];
  // Load the image at that path.
  imageView.image = [UIImage imageWithContentsOfFile:path];

  // Use that image as the image to print.
  if(imageView.image)
    self.imageURL = [NSURL fileURLWithPath:path isDirectory:NO];
   
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
    // For the iPad we'll put the toolbar at the top.
    toolbarFrame = CGRectMake(0, 0, bounds.size.width, kToolbarHeight);
  }else{
    toolbarFrame = CGRectMake(0, bounds.size.height - kToolbarHeight, bounds.size.width, kToolbarHeight);
  }
    
  UIToolbar *aToolbar = [[[UIToolbar alloc] initWithFrame:toolbarFrame] autorelease];
  aToolbar.barStyle = UIBarStyleBlack;

  // Allow the image view to size as the orientation changes.
  imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  self.toolbar = aToolbar;
  [self setupToolbarItems];
  
  // Allow the toolbar to size and float as the orientation changes. Because the toolbar is at the
  // top on the iPad, the mask is adjusted accordingly.
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    aToolbar.autoresizingMask =  UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
  else
    aToolbar.autoresizingMask =  UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
  
  [imageView addSubview:aToolbar];
}

- (void)viewDidUnload {
    self.toolbar = nil;
    self.printButton = nil;
    self.pickerButton = nil;
    self.imageURL = nil;
    [super viewDidUnload];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations; we support all.
    return YES;
}

#pragma mark target-action methods

// Invoked when the user chooses the action icon for printing.
- (void)printImage:(id)sender {
  // Obtain the shared UIPrintInteractionController
  UIPrintInteractionController *controller = [UIPrintInteractionController sharedPrintController];
  if(!controller){
    NSLog(@"Couldn't get shared UIPrintInteractionController!");
    return;
  }

  // We need a completion handler block for printing.
  UIPrintInteractionCompletionHandler completionHandler = ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
    if(completed && error)
      NSLog(@"FAILED! due to error in domain %@ with error code %u", error.domain, error.code);
  };
  
  // Obtain a printInfo so that we can set our printing defaults.
  UIPrintInfo *printInfo = [UIPrintInfo printInfo];
  UIImage *image = ((UIImageView *)self.view).image;

  // This application prints photos. UIKit will pick a paper size and print
  // quality appropriate for this content type.
  printInfo.outputType = UIPrintInfoOutputPhoto;
  // The path to the image may or may not be a good name for our print job
  // but that's all we've got.
  printInfo.jobName = [[self.imageURL path] lastPathComponent];
  
  // If we are performing drawing of our image for printing we will print
  // landscape photos in a landscape orientation.
  if(!controller.printingItem && image.size.width > image.size.height)
    printInfo.orientation = UIPrintInfoOrientationLandscape;
  
  // Use this printInfo for this print job.
  controller.printInfo = printInfo;
  
  //  Since the code below relies on printingItem being zero if it hasn't
  //  already been set, this code sets it to nil. 
  controller.printingItem = nil;
  
  
#if DIRECT_SUBMISSION
  // Use the URL of the image asset.
    if(self.imageURL && [UIPrintInteractionController canPrintURL:self.imageURL])
      controller.printingItem = self.imageURL;
#endif
  
  // If we aren't doing direct submission of the image or for some reason we don't
  // have an ALAsset or URL for our image, we'll draw it instead.
  if(!controller.printingItem){
    // Create an instance of our PrintPhotoPageRenderer class for use as the
    // printPageRenderer for the print job.
    PrintPhotoPageRenderer *pageRenderer = [[PrintPhotoPageRenderer alloc]init];
    // The PrintPhotoPageRenderer subclass needs the image to draw. If we were taking 
    // this path we use the original image and not the fullScreenImage we obtained from 
    // the ALAssetRepresentation.
    pageRenderer.imageToPrint = ((UIImageView *)self.view).image;
    controller.printPageRenderer = pageRenderer;
    [pageRenderer release];
  }
  
  // The method we use presenting the printing UI depends on the type of 
  // UI idiom that is currently executing. Once we invoke one of these methods
  // to present the printing UI, our application's direct involvement in printing
  // is complete. Our delegate methods (if any) and page renderer methods (if any)
  // are invoked by UIKit.
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    [controller presentFromBarButtonItem:self.printButton animated:YES completionHandler:completionHandler];  // iPad
  }else
    [controller presentAnimated:YES completionHandler:completionHandler];  // iPhone
  
}

// Show the image picker when the user wants to choose an image.
- (void)showImagePicker:(id)sender {
  // Dismiss any printing popover that might already be showing.
  if([UIPrintInteractionController isPrintingAvailable] && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    [[UIPrintInteractionController sharedPrintController] dismissAnimated:YES];

  // If a popover is already showing, dismiss it.
  if(self.popover){
    [self.popover dismissPopoverAnimated:YES];
    self.popover = nil;
    return;
  }

  // UIImagePickerController let's the user choose an image.
  UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
  imagePicker.delegate = self;
  // On the iPad we need to present the image picker in a popover.
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    // If a popover is already showing, dismiss it before presenting a new one.
    // We own this instance of the popover controller but will release it in popoverControllerDidDismissPopover.
    UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:imagePicker];
    popoverController.delegate = self;
    self.popover = popoverController;
    [popoverController presentPopoverFromBarButtonItem:self.pickerButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
  }else{
    [self presentModalViewController:imagePicker animated:YES];
  }
  [imagePicker release];
}

#pragma mark delegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  if(info){
  // Don't pay any attention if somehow someone picked something besides an image.
  if([[info objectForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString *)kUTTypeImage]){
    UIImageView *imageView = (UIImageView *)self.view;
    // Hand on to the asset URL for the picked photo..
    self.imageURL = [info objectForKey:UIImagePickerControllerReferenceURL];

#if USE_SCREEN_IMAGE      
   // To get an asset library reference we need an instance of the asset library.
    ALAssetsLibrary* assetsLibrary = [[ALAssetsLibrary alloc] init];
    NSString *osVersion = [[UIDevice currentDevice] systemVersion];
    NSString *versionWithoutRotation = @"5.0";
    BOOL noRotationNeeded = ([versionWithoutRotation compare:osVersion options:NSNumericSearch] 
                             != NSOrderedDescending);
    // The assetForURL: method of the assets library needs a block for success and
    // one for failure. The resultsBlock is used for the success case.
    ALAssetsLibraryAssetForURLResultBlock resultsBlock = ^(ALAsset *asset) {
      ALAssetRepresentation *representation = [asset defaultRepresentation];
      CGImageRef image = [representation fullScreenImage];
      if(noRotationNeeded){
        // Create a UIImage from the full screen image. The full screen image
        // is already scaled and oriented properly.
        imageView.image = [UIImage imageWithCGImage:image];
      }else{
        // prior to iOS 5.0, the screen image needed to be rotated so
        // make sure that the UIImage we create from the CG image has the appropriate
        // orientation, based on the EXIF data from the image.
        ALAssetOrientation orientation = [representation orientation];
        imageView.image = [UIImage imageWithCGImage:image scale:1.0 
                                        orientation:(UIImageOrientation)orientation];
      }
    };
    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error){
      /*  A failure here typically indicates that the user has not allowed this app access
	  to location data. In that case the error code is ALAssetsLibraryAccessUserDeniedError.
	  In principle you could alert the user to that effect, i.e. they have to allow this app
	  access to location services in Settings > General > Location Services and turn on access
	  for this application.
      */
      NSLog(@"FAILED! due to error in domain %@ with error code %d", error.domain, error.code);
      // This sample will abort since a shipping product MUST do something besides logging a
      // message. A real app needs to inform the user appropriately.
      abort();
    };

    // Get the asset for the asset URL to create a screen image.
    [assetsLibrary assetForURL:self.imageURL resultBlock:resultsBlock failureBlock:failureBlock];
    // Release the assets library now that we are done with it.
    [assetsLibrary release];
#else
    // If we aren't using a screen sized image we'll use the original one.
    imageView.image = [info objectForKey:UIImagePickerControllerOriginalImage];
#endif
    
    // If we were presented with a popover, dismiss it.
    if(self.popover){
      [self.popover dismissPopoverAnimated:YES];
      self.popover = nil;
    }else 
      // Dismiss the modal view controller if we weren't presented from a popover.
      [self dismissModalViewControllerAnimated:YES];
    }
  }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [self dismissModalViewControllerAnimated:YES];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
  self.popover = nil;
}
       
@end
