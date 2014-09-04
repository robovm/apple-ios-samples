/*
    File: MagazineViewController.m
Abstract: Main view controller
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

Copyright (C) 2012 Apple Inc. All Rights Reserved.

*/

#import "MagazineViewController.h"
#import "MagazinePage.h"

@interface MagazineViewController()

// Interstitial Management
- (void)cycleInterstitial;
- (void)insertInterstitialAtIndex:(NSInteger)indx;
- (void)removeInterstitial;

// View Layout
- (void)layout;
- (void)preparePages;

@end

#pragma mark -
@implementation MagazineViewController

@synthesize scrollView;

#pragma mark -
#pragma mark Lifetime Management

// Load the data needed to create our magazine pages
// We load the pages once, but each page manages memory usage
// with assistance from this view controller.
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self != nil) {
        pages = [[NSMutableArray alloc] init];
        NSArray *paths = [[NSBundle mainBundle] pathsForResourcesOfType:@"jpg" inDirectory:@"bunnies"];
        [paths enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop) {
            // Use imageWithContentsOfFile to avoid placing the image in the image cache
            MagazinePage *page = [[MagazinePage alloc] initWithContentsOfFile:obj];
            [pages addObject:page];
            [page release];
        }];
        // Setup the interstitial. Set the interstitialIndex to -1 to indicate that we haven't placed it yet.
        [self cycleInterstitial];
        interstitialIndex = -1;
        
        // Setup the pageIndex. Since its used often, keep the pageCount around too.
        pageIndex = 0;
        pageCount = [pages count];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Run layout for the magazine pages and prepare those pages that will be needed soon.
    [self layout];
    [self preparePages];
}

- (void)didReceiveMemoryWarning
{
    // Memory warning code here happens in two steps.
    // The first step is here, where we call purge on all pages
    // This will reduce memory usage on each page to its current minimum.
    // (continued in -viewDidUnload).
    for (MagazinePage *page in pages) {
        [page purge];
    }
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    // Clear the IBOutlet to the scroll view to release it.
    self.scrollView = nil;
    // (continued from -didReceiveMemoryWarning)
    // Here we go on to unprepare each page in the magazine.
    // Since we aren't displaying them to the user, they can easy go away right now.
    // If we get another memory warning afterwards, then the pages that we've unprepared
    // will be further reduced in memory usage, but if we reload instead then
    // we'll have the images already available for use.
    for (MagazinePage *page in pages) {
        [page unprepare];
    }
}

- (void)dealloc
{
    interstitial.delegate = nil;
    [scrollView release];
    [pages release];
    [interstitial release];
    [super dealloc];
}

#pragma mark -
#pragma mark Interstitial Management

- (void)cycleInterstitial
{
    // Release the old interstial and create a new one.
    interstitial.delegate = nil;
    [interstitial release];
    interstitial = [[ADInterstitialAd alloc] init];
    interstitial.delegate = self;
}

- (void)insertInterstitialAtIndex:(NSInteger)indx
{
    // When we insert the interstitial, we also need to relayout and reprepare the relevant magazine pages.
    
    // First try to generate the interstitial page.
    // If we are able to successfully insert the interstitial, then we
    // can do layout and add it into the pages array.
    interstitialIndex = indx;
    CGRect interstitialFrame = scrollView.bounds;
    interstitialFrame.origin = CGPointMake(interstitialFrame.size.width * indx, 0);
    MagazinePage *page = [[MagazinePage alloc] initWithInterstitialFrame:interstitialFrame];
    UIView *view = page.pageView;
    [scrollView addSubview:view]; // the view passed to -presentInView must already be in a view controller owned view hierarchy, so we place it in the scroll view now.
    if ([interstitial presentInView:view]) {
        // Success, insert the page and do layout.
        [pages insertObject:page atIndex:interstitialIndex];
        pageCount = [pages count];
        [self layout];
        [self preparePages];
    } else {
        // Failure, rip it all out cycle the interstitial.
        NSLog(@"failed to present interstitial in container %@", view);
        [view removeFromSuperview];
        [self cycleInterstitial]; // TODO: Reconsider this... esp since it probably won't make a difference.
    }
    [page release];
}

- (void)removeInterstitial
{
    if (interstitialIndex != -1) {
        if (interstitialIndex == pageIndex) {
            // the user is looking at the interstitial now.
            if (pageIndex == pageCount - 1) {
                // the interstitial ended up as the last page in the view.
                // In this case, we need to slip the pageIndex back by one.
                --pageIndex;
            }
            [pages removeObjectAtIndex:interstitialIndex];
            pageCount = [pages count];
            [UIView animateWithDuration:0.2 animations:^{
                [self layout];
                [self preparePages];
            }];
        } else {
            // The user isn't looking, so we can just quietly remove the interstitial
            [pages removeObjectAtIndex:interstitialIndex];
            pageCount = [pages count];
            [self layout];
            [self preparePages];
        }
        // If we're going to animate away, then we want to nil the delegate now.
        interstitial.delegate = nil;
        [self cycleInterstitial];
        interstitialIndex = -1;
    }
}

#pragma mark ADInterstitialViewDelegate methods

// The application should implement this method so that when the user dismisses the interstitial via
// the top left corner dismiss button (which will hide the content of the interstitial) the
// application can then move the view offscreen.
- (void)interstitialAdDidUnload:(ADInterstitialAd *)interstitialAd
{
    [self removeInterstitial];
}

// This method is invoked each time a interstitial loads a new advertisement. 
// The delegate should implement this method so that it knows when the interstitial is ready to be displayed.
- (void)interstitialAdDidLoad:(ADInterstitialAd *)interstitialAd
{
    [self removeInterstitial];
    if (interstitialIndex == -1) {
        [self insertInterstitialAtIndex:pageIndex+1];
    }
}

// This method will be invoked when an error has occurred attempting to get advertisement content. 
// The ADError enum lists the possible error codes.
- (void)interstitialAd:(ADInterstitialAd *)interstitialAd didFailWithError:(NSError *)error
{
    NSLog(@"interstitialAd <%@> recieved error <%@>", interstitialAd, error);
}

// This message will be sent when the user taps on the interstitial and some action is to be taken.
// The delegate may return NO to block the action from taking place, but this
// should be avoided if possible because most advertisements pay significantly more when 
// the action takes place and, over the longer term, repeatedly blocking actions will 
// decrease the ad inventory available to the application. Applications should reduce
// their own activity while the advertisement's action executes.
- (BOOL)interstitialAdActionShouldBegin:(ADInterstitialAd *)interstitialAd willLeaveApplication:(BOOL)willLeave
{
    return YES;
}

// This message is sent when a modal action has completed and control is returned to the application. 
// Games, media playback, and other activities that were paused in response to the beginning
// of the action should resume at this point.
- (void)interstitialAdActionDidFinish:(ADInterstitialAd *)interstitialAd
{
}

#pragma mark -
#pragma mark View Layout

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    pendingOrientationChange = YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self layout];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    pendingOrientationChange = NO;
}

- (void)viewDidLayoutSubviews
{
    [self layout];
}

// Layout is relatively simple, just iterate through the magazine pages and place each one back to back in the scroll view.
// At the same time, setup the scroll view's contentSize and contentOffset to display the current page.
- (void)layout
{
    CGRect placementRect = scrollView.bounds;
    scrollView.contentSize = CGSizeMake(placementRect.size.width * pageCount, placementRect.size.height);
    scrollView.contentOffset = CGPointMake(placementRect.size.width * pageIndex, 0.0);
    for (NSInteger i = 0; i < pageCount; ++i) {
        MagazinePage *page = [pages objectAtIndex:i];
        UIView *pageView = page.pageView;
        placementRect.origin.x = placementRect.size.width * i;
        pageView.frame = placementRect;
        [scrollView addSubview:pageView];
    }
}

// Preparation ensures that if the user pages to the previous/next page that the content for that page is ready to go.
// This method is called seperately of layout because there are times when the layout needs to change but available pages does not
// and vice versa.
// This version only prepares the page that the user sees and the page to the immediate left & right of that page.
- (void)preparePages
{
    NSInteger i = 0;
    for (; i < pageIndex - 1; ++i) {
        [[pages objectAtIndex:i] unprepare];
    }
    for (; (i <= pageIndex + 1) && (i < pageCount); ++i) {
        [[pages objectAtIndex:i] prepare];
    }
    for (; i < pageCount; ++i) {
        [[pages objectAtIndex:i] unprepare];
    }
}

#pragma mark -
#pragma mark Scrolling Support

- (void)scrollViewDidScroll:(UIScrollView *)sv
{
    // Because the orientation change may shrink the scroll view, which may send this message.
    // Basically ignore the message until the orientation change completes, and trust -layout
    // to place us correctly.
    if (pendingOrientationChange) {
        return;
    }
    
    // Infer the desired page from the new contentOffset.
    CGFloat offsetX = scrollView.contentOffset.x;
    CGFloat width = scrollView.bounds.size.width;
    NSInteger tmpIndex = trunc(offsetX / width);
    if (tmpIndex != pageIndex) {
        pageIndex = tmpIndex;
        [self preparePages];
    }
}

- (IBAction)nextImage
{
    if (pageIndex < pageCount - 1) {
        ++pageIndex;
    }
    [scrollView setContentOffset:CGPointMake(scrollView.bounds.size.width * pageIndex, 0.0) animated:YES];
    [self preparePages];
}

- (IBAction)prevImage
{
    if (pageIndex > 0) {
        --pageIndex;
    }
    [scrollView setContentOffset:CGPointMake(scrollView.bounds.size.width * pageIndex, 0.0) animated:YES];
    [self preparePages];
}

@end
