/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Controller that manages the full tile view of the atomic information, creating the reflection, and the flipping of the tile.
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
