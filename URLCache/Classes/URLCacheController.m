/*

 File: URLCacheController.m
 Abstract: The view controller for the URLCache sample.

 Version: 1.1

 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
 ("Apple") in consideration of your agreement to the following terms, and your
 use, installation, modification or redistribution of this Apple software
 constitutes acceptance of these terms.  If you do not agree with these terms,
 please do not use, install, modify or redistribute this Apple software.

 In consideration of your agreement to abide by the following terms, and subject
 to these terms, Apple grants you a personal, non-exclusive license, under
 Apple's copyrights in this original Apple software (the "Apple Software"), to
 use, reproduce, modify and redistribute the Apple Software, with or without
 modifications, in source and/or binary forms; provided that if you redistribute
 the Apple Software in its entirety and without modifications, you must retain
 this notice and the following text and disclaimers in all such redistributions
 of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may be used
 to endorse or promote products derived from the Apple Software without specific
 prior written permission from Apple.  Except as expressly stated in this notice,
 no other rights or licenses, express or implied, are granted by Apple herein,
 including but not limited to any patent rights that may be infringed by your
 derivative works or by other works in which the Apple Software may be
 incorporated.

 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
 WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
 WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
 COMBINATION WITH YOUR PRODUCTS.

 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
 DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
 CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
 APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 Copyright (C) 2008-2010 Apple Inc. All Rights Reserved.

 */

#import "URLCacheController.h"
#import "URLCacheAlert.h"

/* cache update interval in seconds */
const double URLCacheInterval = 86400.0;

@interface NSObject (PrivateMethods)

- (void) initUI;
- (void) startAnimation;
- (void) stopAnimation;
- (void) buttonsEnabled:(BOOL)flag;
- (void) getFileModificationDate;
- (void) displayImageWithURL:(NSURL *)theURL;
- (void) displayCachedImage;
- (void) initCache;
- (void) clearCache;

@end

@implementation URLCacheController

@synthesize dataPath;
@synthesize filePath;
@synthesize fileDate;
@synthesize urlArray;
@synthesize connection;

@synthesize imageView;
@synthesize activityIndicator;
@synthesize statusField;
@synthesize dateField;
@synthesize infoField;
@synthesize toolbarItem1;
@synthesize toolbarItem2;


- (void) viewDidLoad {

	[super viewDidLoad];

	/* By default, the Cocoa URL loading system uses a small shared memory cache.
	 We don't need this cache, so we set it to zero when the application launches. */

    /* turn off the NSURLCache shared cache */

    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0
                                                            diskCapacity:0
                                                                diskPath:nil];
    [NSURLCache setSharedURLCache:sharedCache];
    [sharedCache release];

    /* prepare to use our own on-disk cache */
	[self initCache];

    /* create and load the URL array using the strings stored in URLCache.plist */

    NSString *path = [[NSBundle mainBundle] pathForResource:@"URLCache" ofType:@"plist"];
    if (path) {
        NSArray *array = [[NSArray alloc] initWithContentsOfFile:path];
        self.urlArray = [NSMutableArray array];
        for (NSString *element in array) {
            [self.urlArray addObject:[NSURL URLWithString:element]];
        }
        [array release];
    }

	/* set the view's background to gray pinstripe */
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];

	/* set initial state of network activity indicators */
	[self stopAnimation];

	/* initialize the user interface */
	[self initUI];
}


- (void)dealloc {
	[dataPath release];
	[filePath release];
	[fileDate release];
	[urlArray release];
	[connection release];

	[imageView release];
	[activityIndicator release];
	[statusField release];
	[dateField release];
	[infoField release];
	[toolbarItem1 release];
	[toolbarItem2 release];

	[super dealloc];
}

/*
 ------------------------------------------------------------------------
 Action methods that respond to UI events or change the UI
 ------------------------------------------------------------------------
 */

#pragma mark -
#pragma mark IBAction methods

/* Action method for the Display Image button. */

- (IBAction) onDisplayImage:(id)sender
{
	[self initUI];
	[self displayImageWithURL:[urlArray objectAtIndex:0]];
}


/* Action method for the Clear Cache button. */

- (IBAction) onClearCache:(id)sender
{
	NSString *message = NSLocalizedString (@"Do you really want to clear the cache?",
										   @"Clear Cache alert message");

	URLCacheAlertWithMessageAndDelegate(message, self);

	/* We handle the user response to this alert in the UIAlertViewDelegate
	 method alertView:clickedButtonAtIndex: at the end of this file. */
}


/*
 ------------------------------------------------------------------------
 Private methods used only in this file
 ------------------------------------------------------------------------
 */

#pragma mark -
#pragma mark Private methods

/* initialize fields in the user interface */

- (void) initUI
{
	imageView.image = nil;
	statusField.text = @"";
	dateField.text = @"";
	infoField.text = @"";
}


/* show the user that loading activity has started */

- (void) startAnimation
{
	[self.activityIndicator startAnimating];
	UIApplication *application = [UIApplication sharedApplication];
	application.networkActivityIndicatorVisible = YES;
}


/* show the user that loading activity has stopped */

- (void) stopAnimation
{
	[self.activityIndicator stopAnimating];
	UIApplication *application = [UIApplication sharedApplication];
	application.networkActivityIndicatorVisible = NO;
}


/* enable or disable all toolbar buttons */

- (void) buttonsEnabled:(BOOL)flag
{
	toolbarItem1.enabled = flag;
	toolbarItem2.enabled = flag;
}


- (void) initCache
{
	/* create path to cache directory inside the application's Documents directory */
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    self.dataPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"URLCache"];

	/* check for existence of cache directory */
	if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
		return;
	}

	/* create a new cache directory */
	if (![[NSFileManager defaultManager] createDirectoryAtPath:dataPath
								   withIntermediateDirectories:NO
													attributes:nil
														 error:&error]) {
		URLCacheAlertWithError(error);
		return;
	}
}


/* removes every file in the cache directory */

- (void) clearCache
{
	/* remove the cache directory and its contents */
	if (![[NSFileManager defaultManager] removeItemAtPath:dataPath error:&error]) {
		URLCacheAlertWithError(error);
		return;
	}

	/* create a new cache directory */
	if (![[NSFileManager defaultManager] createDirectoryAtPath:dataPath
								   withIntermediateDirectories:NO
													attributes:nil
														 error:&error]) {
		URLCacheAlertWithError(error);
		return;
	}

	[self initUI];
}


/* get modification date of the current cached image */

- (void) getFileModificationDate
{
	/* default date if file doesn't exist (not an error) */
	self.fileDate = [NSDate dateWithTimeIntervalSinceReferenceDate:0];

	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
		/* retrieve file attributes */
		NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
		if (attributes != nil) {
			self.fileDate = [attributes fileModificationDate];
		}
		else {
			URLCacheAlertWithError(error);
		}
	}
}


/* display new or existing cached image */

- (void) displayImageWithURL:(NSURL *)theURL
{
	/* get the path to the cached image */

	[filePath release]; /* release previous instance */
	NSString *fileName = [[theURL path] lastPathComponent];
	filePath = [[dataPath stringByAppendingPathComponent:fileName] retain];

	/* apply daily time interval policy */

	/* In this program, "update" means to check the last modified date
	 of the image to see if we need to load a new version. */

	[self getFileModificationDate];
	/* get the elapsed time since last file update */
	NSTimeInterval time = fabs([fileDate timeIntervalSinceNow]);
	if (time > URLCacheInterval) {
		/* file doesn't exist or hasn't been updated for at least one day */
		[self initUI];
		[self buttonsEnabled:NO];
		[self startAnimation];
		self.connection = [[URLCacheConnection alloc] initWithURL:theURL delegate:self];
	}
	else {
		statusField.text = NSLocalizedString (@"Previously cached image",
											  @"Image found in cache and updated in last 24 hours.");
		[self displayCachedImage];
	}
}


/* display existing cached image */

- (void) displayCachedImage
{
	infoField.text = NSLocalizedString (@"The cached image is updated if 24 hours has elapsed since the last update and you press the Display Image button.", @"Information about updates.");

	/* retrieve file attributes */

	[self getFileModificationDate];

	/* format the file modification date for display in Updated field */
	/* NSDateFormatterStyle options give meaningful results in all locales */

	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	dateField.text = [@"Updated: " stringByAppendingString:[dateFormatter stringFromDate:fileDate]];
	[dateFormatter release];

	/* display the file as an image */

	UIImage *theImage = [[UIImage alloc] initWithContentsOfFile:filePath];
	if (theImage) {
		imageView.image = theImage;
		[theImage release];
	}
}


/*
 ------------------------------------------------------------------------
 URLCacheConnectionDelegate protocol methods
 ------------------------------------------------------------------------
 */

#pragma mark -
#pragma mark URLCacheConnectionDelegate methods

- (void) connectionDidFail:(URLCacheConnection *)theConnection
{
	[self stopAnimation];
	[self buttonsEnabled:YES];
}


- (void) connectionDidFinish:(URLCacheConnection *)theConnection
{
	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] == YES) {

		/* apply the modified date policy */

		[self getFileModificationDate];
		NSComparisonResult result = [theConnection.lastModified compare:fileDate];
		if (result == NSOrderedDescending) {
			/* file is outdated, so remove it */
			if (![[NSFileManager defaultManager] removeItemAtPath:filePath error:&error]) {
				URLCacheAlertWithError(error);
			}

		}
	}

	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] == NO) {
		/* file doesn't exist, so create it */
		[[NSFileManager defaultManager] createFileAtPath:filePath
												contents:theConnection.receivedData
											  attributes:nil];

		statusField.text = NSLocalizedString (@"Newly cached image",
											  @"Image not found in cache or new image available.");
	}
	else {
		statusField.text = NSLocalizedString (@"Cached image is up to date",
											  @"Image updated and no new image available.");
	}

	/* reset the file's modification date to indicate that the URL has been checked */

	NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:[NSDate date], NSFileModificationDate, nil];
	if (![[NSFileManager defaultManager] setAttributes:dict ofItemAtPath:filePath error:&error]) {
		URLCacheAlertWithError(error);
	}
	[dict release];

	[self stopAnimation];
	[self buttonsEnabled:YES];
	[self displayCachedImage];
}

/*
 ------------------------------------------------------------------------
 UIAlertViewDelegate protocol method
 ------------------------------------------------------------------------
 */

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 0) {
		/* the user clicked the Cancel button */
        return;
    }

	[self clearCache];
}

@end
