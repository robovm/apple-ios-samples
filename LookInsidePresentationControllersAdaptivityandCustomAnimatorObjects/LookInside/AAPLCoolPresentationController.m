/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  AAPLCoolPresentationController implementation.
  
 */

#import "AAPLCoolPresentationController.h"

@implementation AAPLCoolPresentationController

- (instancetype)initWithPresentedViewController:(UIViewController *)presentedViewController presentingViewController:(UIViewController *)presentingViewController
{
    self = [super initWithPresentedViewController:presentedViewController presentingViewController:presentingViewController];
    if(self)
    {
        // Create our dimming view
        _dimmingView = [[UIView alloc] init];
        [[self dimmingView] setBackgroundColor:[[UIColor purpleColor] colorWithAlphaComponent:0.4]];
        
        // Create our other chrome
        _bigFlowerImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BigFlower"]];
        _carlImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Carl"]];
        [[self carlImageView] setFrame:CGRectMake(0,0,500,245)];
        
        _jaguarPrintImageH = [[UIImage imageNamed:@"JaguarH"] resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeTile];
        _jaguarPrintImageV = [[UIImage imageNamed:@"JaguarV"] resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeTile];

        _topJaguarPrintImageView = [[UIImageView alloc] initWithImage:[self jaguarPrintImageH]];
        _bottomJaguarPrintImageView = [[UIImageView alloc] initWithImage:[self jaguarPrintImageH]];

        _leftJaguarPrintImageView = [[UIImageView alloc] initWithImage:[self jaguarPrintImageV]];
        _rightJaguarPrintImageView = [[UIImageView alloc] initWithImage:[self jaguarPrintImageV]];
    }
    return self;
}

- (CGRect)frameOfPresentedViewInContainerView
{
    // Return a frame that's centered in the display, with a width of 300pt and a height which varies based on our vertical size class
    CGRect containerBounds = [[self containerView] bounds];
    
    CGRect presentedViewFrame = CGRectZero;
    CGFloat width = 300;
    CGFloat height = ([[self traitCollection] verticalSizeClass] == UIUserInterfaceSizeClassCompact) ? 300 : containerBounds.size.height - (2 * [self jaguarPrintImageH].size.height);
    
    presentedViewFrame.size = CGSizeMake(width, height);
    presentedViewFrame.origin = CGPointMake(containerBounds.size.width / 2.0, containerBounds.size.height / 2.0);
    presentedViewFrame.origin.x -= presentedViewFrame.size.width / 2.0;
    presentedViewFrame.origin.y -= presentedViewFrame.size.height / 2.0;
    
    return presentedViewFrame;
}

- (void)presentationTransitionWillBegin
{
    [super presentationTransitionWillBegin];
    
    // Add our chrome to the dimming view

    [self addViewsToDimmingView];

    // Before the presentation begins, we want to have our dimming view be totally transparent

    [[self dimmingView] setAlpha:0.0];
    
    // Alongside the view controller presentation animation, we want to fade the dimming view to
    // be opaque. We can do so by animating alongside the current transition on the presented
    // view controller
    
    [[[self presentedViewController] transitionCoordinator] animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [[self dimmingView] setAlpha:1.0];
    } completion:nil];

    // Using a custom animation, animate in our jaguar print

    [self moveJaguarPrintToPresentedPosition:NO];
    
    [UIView animateWithDuration:1.0 animations:^{
        [self moveJaguarPrintToPresentedPosition:YES];
    }];
}

- (void)containerViewWillLayoutSubviews
{
    [[self dimmingView] setFrame:[[self containerView] bounds]];
    [[self presentedView] setFrame:[self frameOfPresentedViewInContainerView]];
    [self moveJaguarPrintToPresentedPosition:YES];
}

- (void)containerViewDidLayoutSubviews
{
    CGPoint bigFlowerCenter = [[self dimmingView] frame].origin;
    bigFlowerCenter.x += [[[self bigFlowerImageView] image] size].width / 4.0;
    bigFlowerCenter.y += [[[self bigFlowerImageView] image] size].height / 4.0;
    
    [[self bigFlowerImageView] setCenter:bigFlowerCenter];
    
    CGRect carlFrame = [[self carlImageView] frame];
    carlFrame.origin.y = [[self dimmingView] bounds].size.height - carlFrame.size.height;
    
    [[self carlImageView] setFrame:carlFrame];
}

- (void)dismissalTransitionWillBegin
{
    [super dismissalTransitionWillBegin];

    // In -dismissalTransitionWillBegin, we want to undo what we did in
    // -presentationTransitionWillBegin. Fade our dimming view's alpha back to 0
    [[[self presentedViewController] transitionCoordinator] animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [[self dimmingView] setAlpha:0.0];
} completion:nil];
}

- (void)addViewsToDimmingView
{
    // We only want the flower and Carl if we have enough space. Only add them
    // if both of our size classes are Regular

    if(([[self traitCollection] horizontalSizeClass] == UIUserInterfaceSizeClassRegular) &&
       ([[self traitCollection] verticalSizeClass] == UIUserInterfaceSizeClassRegular))
    {
        [[self dimmingView] addSubview:[self bigFlowerImageView]];
        [[self dimmingView] addSubview:[self carlImageView]];
    }

    [[self dimmingView] addSubview:[self topJaguarPrintImageView]];
    [[self dimmingView] addSubview:[self bottomJaguarPrintImageView]];

    [[self dimmingView] addSubview:[self leftJaguarPrintImageView]];
    [[self dimmingView] addSubview:[self rightJaguarPrintImageView]];
    
    [[self containerView] addSubview:[self dimmingView]];
}

- (void)moveJaguarPrintToPresentedPosition:(BOOL)presentedPosition
{
    CGSize horizontalJaguarSize = [[self jaguarPrintImageH] size];
    CGSize verticalJaguarSize = [[self jaguarPrintImageV] size];
    CGRect frameOfView = [self frameOfPresentedViewInContainerView];
    CGRect containerFrame = [[self containerView] frame];

    CGRect topFrame, bottomFrame, leftFrame, rightFrame;
    topFrame.size.height = bottomFrame.size.height = horizontalJaguarSize.height;
    topFrame.size.width = bottomFrame.size.width = frameOfView.size.width;

    leftFrame.size.width = rightFrame.size.width = verticalJaguarSize.width;
    leftFrame.size.height = rightFrame.size.height = frameOfView.size.height;

    topFrame.origin.x = frameOfView.origin.x;
    bottomFrame.origin.x = frameOfView.origin.x;

    leftFrame.origin.y = frameOfView.origin.y;
    rightFrame.origin.y = frameOfView.origin.y;

    CGRect frameToAlignAround = presentedPosition ? frameOfView : containerFrame;

    topFrame.origin.y = CGRectGetMinY(frameToAlignAround) - horizontalJaguarSize.height;
    bottomFrame.origin.y = CGRectGetMaxY(frameToAlignAround);
    leftFrame.origin.x = CGRectGetMinX(frameToAlignAround) - verticalJaguarSize.width;
    rightFrame.origin.x = CGRectGetMaxX(frameToAlignAround);
    
    [[self topJaguarPrintImageView] setFrame:topFrame];
    [[self bottomJaguarPrintImageView] setFrame:bottomFrame];
    [[self leftJaguarPrintImageView] setFrame:leftFrame];
    [[self rightJaguarPrintImageView] setFrame:rightFrame];
}

@end
