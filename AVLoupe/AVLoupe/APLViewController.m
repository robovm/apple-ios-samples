/*
     File: APLViewController.m
 Abstract: The player's view controller class. 
 This controller manages the main view and a sublayer; the mainPlayerLayer. This controller also manages as a subview a UIImageView nammed loupeView. loupeView hosts a layer hirearchy that manages the zoomPlayerLayer.
 Users interact with the position of loupeView in respose to IBActions from a UIPanGestureRecognizer.
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
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */


#import "APLViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <CoreMedia/CoreMedia.h>

#define ZOOM_FACTOR 4.0
#define LOUPE_BEZEL_WIDTH 18.0


@interface APLViewController ()

{
	BOOL _haveSetupPlayerLayers;
}

@property AVPlayer *player;
@property AVPlayerLayer *zoomPlayerLayer;
@property AVPlayerLayer *mainPlayerLayer;
@property UIPopoverController *popover;
@property id notificationToken;

@property (weak) IBOutlet UINavigationBar *navigationBar;
@property (weak) IBOutlet UIImageView *loupeView;

@end

@implementation APLViewController

- (void)viewDidLoad
{
	_player = [[AVPlayer alloc] init];
	_player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
	_haveSetupPlayerLayers = NO;
}

- (IBAction)handleTapFrom:(UITapGestureRecognizer *)recognizer
{
	self.navigationBar.hidden = !self.navigationBar.hidden;
}

- (IBAction)handlePanFrom:(UIPanGestureRecognizer *)recognizer
{
	CGPoint translation = [recognizer translationInView:self.view];
    
	recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
	                                     recognizer.view.center.y + translation.y);
	[recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
    
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	self.zoomPlayerLayer.position = CGPointMake(self.zoomPlayerLayer.position.x - translation.x * ZOOM_FACTOR,
	                                        self.zoomPlayerLayer.position.y - translation.y * ZOOM_FACTOR);
	[CATransaction commit];
}

- (void)viewDidLayoutSubviews
{
	if (!_haveSetupPlayerLayers) {
		// Main PlayerLayer.
		self.mainPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
		[self.view.layer insertSublayer:self.mainPlayerLayer below:self.loupeView.layer];
		self.mainPlayerLayer.frame = self.view.layer.bounds;

		// Build the loupe.
		// Content layer serves two functions:
		//  - An opaque black backdrop, since our AVPlayerLayers have a finite edge.
		//  - Applies a sub-layers only mask on behalf of the loupe view
		CALayer *contentLayer = [CALayer layer];
		contentLayer.frame = self.loupeView.bounds;
		contentLayer.backgroundColor = [[UIColor blackColor] CGColor];
		
		// The content layer has a circular mask applied.
		CAShapeLayer *maskLayer = [CAShapeLayer layer];
		maskLayer.frame = contentLayer.bounds;
		
		CGMutablePathRef circlePath = CGPathCreateMutable();
		CGPathAddEllipseInRect(circlePath, NULL, CGRectInset(self.loupeView.layer.bounds, LOUPE_BEZEL_WIDTH , LOUPE_BEZEL_WIDTH));
		
		maskLayer.path = circlePath;
		CGPathRelease(circlePath);
		
		contentLayer.mask = maskLayer;
		
		// Set up the zoom AVPlayerLayer.
		self.zoomPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
		CGSize zoomSize = CGSizeMake(self.view.layer.bounds.size.width * ZOOM_FACTOR, self.view.layer.bounds.size.height * ZOOM_FACTOR);
		self.zoomPlayerLayer.frame = CGRectMake((contentLayer.bounds.size.width /2) - (zoomSize.width /2),
											(contentLayer.bounds.size.height /2) - (zoomSize.height /2),
											zoomSize.width,
											zoomSize.height);
					
		[contentLayer addSublayer:self.zoomPlayerLayer];
		[self.loupeView.layer addSublayer:contentLayer];
		
		_haveSetupPlayerLayers = YES;
	}
}

- (IBAction)loadMovieFromCameraRoll:(id)sender
{
    [self.player pause];
    
    if ([self.popover isPopoverVisible]) {
        [self.popover dismissPopoverAnimated:YES];
    }
    // Initialize UIImagePickerController to select a movie from the camera roll.
    UIImagePickerController *videoPicker = [[UIImagePickerController alloc] init];
    videoPicker.delegate = self;
    videoPicker.modalPresentationStyle = UIModalPresentationCurrentContext;
    videoPicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    videoPicker.mediaTypes = @[(NSString*)kUTTypeMovie];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:videoPicker];
        self.popover.delegate = self;
        [self.popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
    }
	else {
        [self presentViewController:videoPicker animated:YES completion:nil];
    }
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

#pragma mark Image Picker Controller Delegate 

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [self.popover dismissPopoverAnimated:YES];
    }
	else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    NSURL *url = info[UIImagePickerControllerReferenceURL];
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
	[self.player replaceCurrentItemWithPlayerItem:item];
	
	self.notificationToken = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:item queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		// Simple item playback rewind.
		[[self.player currentItem] seekToTime:kCMTimeZero];
	}];
	
	[self.player play];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
	
	// Make sure playback is resumed from any interruption.
    [self.player play];
}

# pragma mark Popover Controller Delegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    // Make sure playback is resumed from any interruption.
    [self.player play];
}

@end



@implementation UIImagePickerController (LandscapeOrientation)

- (BOOL)shouldAutorotate
{
    return NO;
}

@end
