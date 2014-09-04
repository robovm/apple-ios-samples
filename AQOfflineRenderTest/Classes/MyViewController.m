/*
     File: MyViewController.m
 Abstract: 
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
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */

#import "MyViewController.h"

#define kTransitionDuration	0.75

extern void DoAQOfflineRender(CFURLRef sourceURL, CFURLRef destinationURL);

@implementation MyViewController

@synthesize instructionsView, webView, contentView, startButton, activityIndicator, flipButton, doneButton;

- (void)dealloc
{
	[flipButton release];
	[doneButton release];
    
    [destinationFilePath release];
    CFRelease(sourceURL);
    CFRelease(destinationURL);
    
	[super dealloc];
}

- (void)viewDidLoad
{   
    // create the URLs we'll use for source and destination
    NSString *source = [[NSBundle mainBundle] pathForResource:@"soundalac" ofType:@"caf"];
    sourceURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)source, kCFURLPOSIXPathStyle, false);
    
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    destinationFilePath = [[NSString alloc] initWithFormat: @"%@/output.caf", documentsDirectory];
    destinationURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)destinationFilePath, kCFURLPOSIXPathStyle, false);

	// load up the info text
    NSString *infoSouceFile = [[NSBundle mainBundle] pathForResource:@"info" ofType:@"html"];
	NSString *infoText = [NSString stringWithContentsOfFile:infoSouceFile encoding:NSUTF8StringEncoding error:nil];
    [self.webView loadHTMLString:infoText baseURL:nil];
    
    // set up start button
    UIImage *greenImage = [[UIImage imageNamed:@"green_button.png"] stretchableImageWithLeftCapWidth:12.0 topCapHeight:0.0];
	UIImage *redImage = [[UIImage imageNamed:@"red_button.png"] stretchableImageWithLeftCapWidth:12.0 topCapHeight:0.0];
	
	[startButton setBackgroundImage:greenImage forState:UIControlStateNormal];
	[startButton setBackgroundImage:redImage forState:UIControlStateDisabled];
	[startButton setEnabled:YES];
    
    // add the subview
	[self.view addSubview:contentView];
	
	// add our custom flip buttons as the nav bars custom right view
	UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
	[infoButton addTarget:self action:@selector(flipAction:) forControlEvents:UIControlEventTouchUpInside];
	
    flipButton = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
    self.navigationItem.rightBarButtonItem = flipButton;
	
	// create our done button as the nav bar's custom right view for the flipped view (used later)
	doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(flipAction:)];
}

- (void)didReceiveMemoryWarning
{
	// Invoke super's implementation to do the Right Thing, but also release the input controller since we can do that	
	// In practice this is unlikely to be used in this application, and it would be of little benefit,
	// but the principle is the important thing.
	//
	[super didReceiveMemoryWarning];
}

#pragma mark- Actions

- (void)flipAction:(id)sender
{
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:animationIDfinished:finished:context:)];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration];
	
	[UIView setAnimationTransition:([self.contentView superview] ? UIViewAnimationTransitionFlipFromLeft : UIViewAnimationTransitionFlipFromRight)
                                    forView:self.view
                                    cache:YES];
                                    
	if ([self.instructionsView superview]) {
		[self.instructionsView removeFromSuperview];
		[self.view addSubview:contentView];
	} else {
		[self.contentView removeFromSuperview];
		[self.view addSubview:instructionsView];
	}
	
	[UIView commitAnimations];
	
	// adjust our done/info buttons accordingly
	if ([instructionsView superview]) {
		self.navigationItem.rightBarButtonItem = doneButton;
	} else {
		self.navigationItem.rightBarButtonItem = flipButton;
    }
}

- (IBAction)doSomethingAction:(id)sender
{
    [self.startButton setTitle:@"Rendering Audio..." forState:UIControlStateDisabled];
	[startButton setEnabled:NO];
    
    [self.activityIndicator startAnimating];
    
    // run AQ code in a background thread
    [self performSelectorInBackground:(@selector(renderAudio)) withObject:nil];
}

#pragma mark- AVAudioPlayer
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
	if (flag == NO) NSLog(@"Playback finished unsuccessfully!");
    
	[player setDelegate:nil];
    [player release];
    
    [startButton setEnabled:YES];
}

- (void)playAudio
{    
    // play the result
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:(NSURL *)destinationURL error:nil];
    
    [player setDelegate:self];
    [player play];
}

#pragma mark- AudioQueue

- (void)renderAudio
{    
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // delete the previous output file if it exists, not required but good for the test
    if ([[NSFileManager defaultManager] fileExistsAtPath:destinationFilePath]) {
    	[[NSFileManager defaultManager] removeItemAtPath:destinationFilePath error:nil];
    }
    
    DoAQOfflineRender(sourceURL, destinationURL);
    
    [self.activityIndicator stopAnimating];
    
    [self.startButton setTitle:@"Playing Rendered Audio..." forState:UIControlStateDisabled];
    
    [self performSelectorOnMainThread:(@selector(playAudio)) withObject:nil waitUntilDone:NO];
    
    [pool release];
}

@end