/*
     File: AtomicElementViewController.m
 Abstract: Controller that manages the full tile view of the atomic information,
 creating the reflection, and the flipping of the tile.
  Version: 1.12
 
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
 
#import "AtomicElementViewController.h"
#import "AtomicElementView.h"
#import "AtomicElementFlippedView.h"
#import "AtomicElement.h"


#define kFlipTransitionDuration 0.75
#define reflectionFraction 0.35
#define reflectionOpacity 0.5

@interface AtomicElementViewController ()

@property (assign) BOOL frontViewIsVisible;
@property (nonatomic, strong) AtomicElementView *atomicElementView;
@property (nonatomic, strong) UIImageView *reflectionView;
@property (nonatomic, strong) AtomicElementFlippedView *atomicElementFlippedView;
@property (nonatomic, strong) UIButton *flipIndicatorButton;

@end


#pragma mark -

@implementation AtomicElementViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.frontViewIsVisible = YES;
    
	CGSize preferredAtomicElementViewSize = [AtomicElementView preferredViewSize];
	
	CGRect viewRect = CGRectMake((CGRectGetWidth(self.view.bounds) - preferredAtomicElementViewSize.width)/2,
								 (CGRectGetHeight(self.view.bounds) - preferredAtomicElementViewSize.height)/2 - 40,
								 preferredAtomicElementViewSize.width,
                                 preferredAtomicElementViewSize.height);
	
	// create the atomic element view
	AtomicElementView *localAtomicElementView = [[AtomicElementView alloc] initWithFrame:viewRect];
	self.atomicElementView = localAtomicElementView;
	
	// add the atomic element view to the view controller's view
	self.atomicElementView.element = self.element;	
	[self.view addSubview:self.atomicElementView];
	
	self.atomicElementView.viewController = self;
	
	// create the atomic element flipped view
	
	AtomicElementFlippedView *localAtomicElementFlippedView = [[AtomicElementFlippedView alloc] initWithFrame:viewRect];
	self.atomicElementFlippedView = localAtomicElementFlippedView;
	
	self.atomicElementFlippedView.element = self.element;	
	self.atomicElementFlippedView.viewController = self;

	// create the reflection view
	CGRect reflectionRect = viewRect;

	// the reflection is a fraction of the size of the view being reflected
    reflectionRect.size.height = CGRectGetHeight(reflectionRect) * reflectionFraction;
	
	// and is offset to be at the bottom of the view being reflected
    reflectionRect = CGRectOffset(reflectionRect, 0, CGRectGetHeight(viewRect));
	
	UIImageView *localReflectionImageView = [[UIImageView alloc] initWithFrame:reflectionRect];
	self.reflectionView = localReflectionImageView;
	
	// determine the size of the reflection to create
	NSUInteger reflectionHeight = CGRectGetHeight(self.atomicElementView.bounds) * reflectionFraction;
    
	// create the reflection image, assign it to the UIImageView and add the image view to the view controller's view
	self.reflectionView.image = [self.atomicElementView reflectedImageRepresentationWithHeight:reflectionHeight];
	self.reflectionView.alpha = reflectionOpacity;
	
	[self.view addSubview:self.reflectionView];

	// setup our flip indicator button (placed as a nav bar item to the right)
    UIButton *localFlipIndicator = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 30.0, 30.0)];
	self.flipIndicatorButton = localFlipIndicator;
	
	// front view is always visible at first
	[self.flipIndicatorButton setBackgroundImage:[UIImage imageNamed:@"flipper_list_blue.png"] forState:UIControlStateNormal];
	
	UIBarButtonItem *flipButtonBarItem;
	flipButtonBarItem = [[UIBarButtonItem alloc] initWithCustomView:self.flipIndicatorButton];
	[self.flipIndicatorButton addTarget:self
                                 action:@selector(flipCurrentView)
                       forControlEvents:(UIControlEventTouchDown)];
    [self.navigationItem setRightBarButtonItem:flipButtonBarItem animated:YES];
}

- (void)flipCurrentView {
    
	NSUInteger reflectionHeight;
	UIImage *reflectedImage;
	
	// disable user interaction during the flip animation
	self.view.userInteractionEnabled = NO;
	self.flipIndicatorButton.userInteractionEnabled = NO;
	
	// setup the animation group
	[UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:kFlipTransitionDuration];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(myTransitionDidStop:finished:context:)];
	
	// swap the views and transition
    if (self.frontViewIsVisible == YES) {
        [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.view cache:YES];
        [self.atomicElementView removeFromSuperview];
        [self.view addSubview:self.atomicElementFlippedView];
		
		// update the reflection image for the new view
		reflectionHeight = CGRectGetHeight(self.atomicElementFlippedView.bounds) * reflectionFraction;
        reflectedImage = [self.atomicElementFlippedView reflectedImageRepresentationWithHeight:reflectionHeight];
		_reflectionView.image = reflectedImage;
    } else {
        [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.view cache:YES];
        [self.atomicElementFlippedView removeFromSuperview];
        [self.view addSubview:self.atomicElementView];
		// update the reflection image for the new view
		reflectionHeight = CGRectGetHeight(self.atomicElementView.bounds) * reflectionFraction;
        reflectedImage = [self.atomicElementView reflectedImageRepresentationWithHeight:reflectionHeight];
		self.reflectionView.image = reflectedImage;
    }
	[UIView commitAnimations];
	
	// swap the nav bar button views
	[UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:kFlipTransitionDuration];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(myTransitionDidStop:finished:context:)];

	if (self.frontViewIsVisible == YES) {
		[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.flipIndicatorButton cache:YES];
		[self.flipIndicatorButton setBackgroundImage:self.element.flipperImageForAtomicElementNavigationItem forState:UIControlStateNormal];
	}
	else {
		[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.flipIndicatorButton cache:YES];
		[self.flipIndicatorButton setBackgroundImage:[UIImage imageNamed:@"flipper_list_blue.png"] forState:UIControlStateNormal];
		
	}
	[UIView commitAnimations];
    
    // invert the front view state
    self.frontViewIsVisible =! self.frontViewIsVisible;
}

- (void)myTransitionDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    
	// re-enable user interaction when the flip animation is completed
	self.view.userInteractionEnabled = YES;
	self.flipIndicatorButton.userInteractionEnabled = YES;
}

@end
