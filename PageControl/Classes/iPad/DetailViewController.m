/*
     File: DetailViewController.m 
 Abstract: A view controller used for displaying a grid of Tile views for the iPad. 
  Version: 1.6 
  
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

#import "DetailViewController.h"
#import "DetailPopoverViewController.h"
#import "PadContentController.h"
#import "Tile.h"

#define TILE_ROWS    2
#define TILE_COLUMNS 3
#define TILE_COUNT   (TILE_ROWS * TILE_COLUMNS)

#define TILE_WIDTH  225
#define TILE_HEIGHT 320
#define TILE_MARGIN 23


@interface DetailViewController ()
{
    CGRect savedPopoverRect;
    
    CGRect tileFrame[TILE_COUNT];
    Tile *tileForFrame[TILE_COUNT];
}

@property (nonatomic, weak) IBOutlet UINavigationBar *navBar;
@property (nonatomic, weak) IBOutlet UIView *contentView;

@property (nonatomic, strong) UIPopoverController *thePopoverController;
@property (nonatomic, strong) DetailPopoverViewController *popoverViewController;

@end


#pragma mark -

@implementation DetailViewController

// implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.popoverViewController = [[DetailPopoverViewController alloc]
                                  initWithNibName:@"DetailPopoverViewController" bundle:nil];
    
	self.thePopoverController.popoverContentSize = [self.popoverViewController.view
													sizeThatFits:CGSizeMake(512.0, 618.0)];
	
	[self createTiles];
}

- (void)viewDidUnload
{
    // release any retained subviews of the main view
    self.navBar = nil;
    self.popoverViewController = nil;
	
	[super viewDidUnload];
}


#pragma mark - Tile support

// creates the grid of page views each containing the individual number content
- (void)createTiles
{
	for (NSInteger row = 0; row < TILE_ROWS; ++row)
    {
        for (NSInteger col = 0; col < TILE_COLUMNS; ++col)
        {
            NSInteger index = (row * TILE_COLUMNS) + col;
            
            CGRect frame = CGRectMake(TILE_MARGIN + col * (TILE_MARGIN + TILE_WIDTH),
                                      TILE_MARGIN + row * (TILE_MARGIN + TILE_HEIGHT) + self.navBar.frame.size.height,
                                      TILE_WIDTH, TILE_HEIGHT);
            tileFrame[index] = frame;
            
            Tile *tile = [[Tile alloc] init];
            tile.tag = index + 1;
            tileForFrame[index] = tile;
            tile.frame = frame;
            tile.backgroundColor = [UIColor whiteColor];
			
			UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
			tapGesture.numberOfTapsRequired = 1;
			tapGesture.numberOfTouchesRequired = 1;
			[tile addGestureRecognizer:tapGesture];
			
            [self.contentView addSubview:tile];
        }
    }
}

- (void)tapAction:(UIGestureRecognizer *)gestureRecognizer
{
	// get the number data for the tapped view, and set the UI elements according
	// to what found in that NSDictionary:
	//
	NSDictionary *numberItem = [self.contentList objectAtIndex:gestureRecognizer.view.tag - 1];
	self.popoverViewController.numberImage.image = [UIImage imageNamed:[numberItem valueForKey:ImageKey]];
	self.popoverViewController.numberLabel.text = [numberItem valueForKey:NameKey];
	self.popoverViewController.numberDetail.text = [numberItem valueForKey:TranslationsKey];
	
	if (self.thePopoverController)
	{
		// dismiss the popover before releasing it
		[self.thePopoverController dismissPopoverAnimated:YES];
	}
    
	// create and present popover
	UIPopoverController *aPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.popoverViewController];
	self.thePopoverController = aPopoverController;
	self.thePopoverController.delegate = self;
	self.thePopoverController.popoverContentSize = self.popoverViewController.view.bounds.size;
	
	// setup the frame in which the popover can be presented slightly smaller its view frame
	CGRect rect = gestureRecognizer.view.frame;
	CGRect finalRect = CGRectInset(rect, 80.0, 80.0);
	
	savedPopoverRect = finalRect;
	[self.thePopoverController presentPopoverFromRect:finalRect
                                               inView:self.contentView
                             permittedArrowDirections:UIPopoverArrowDirectionAny
                                             animated:YES];
}


#pragma mark - Rotation support

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (self.thePopoverController.popoverVisible)
		[self.thePopoverController dismissPopoverAnimated:YES];	// as we rotate, dismiss the current popover
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	if (self.thePopoverController)
	{
		// we finished rotating, if a popover is allocated, show it again in the new orientation
		[self.thePopoverController presentPopoverFromRect:savedPopoverRect
                                                   inView:self.contentView
                                 permittedArrowDirections:UIPopoverArrowDirectionAny
                                                 animated:YES];
	}
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
	// the user dismissed the popover, so release it here
	self.thePopoverController = nil;
}

@end
