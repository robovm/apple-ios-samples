/*
     File: ViewController.m 
 Abstract: The view controller used for transitioning between two UIViews. 
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

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) IBOutlet UIImageView *frontView;
@property (nonatomic, strong) IBOutlet UIImageView *backView;

@property (nonatomic, weak) IBOutlet UIBarButtonItem *fadeButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *flipButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *bounceButton;

@property (nonatomic, strong) NSArray *priorConstraints;

- (IBAction)flipAction:(id)sender;
- (IBAction)fadeAction:(id)sender;
- (IBAction)bounceAction:(id)sender;

@end


#pragma mark -

@implementation ViewController

// makes "subview" match the width and height of "superview" by adding the proper auto layout constraints
//
- (NSArray *)constrainSubview:(UIView *)subview toMatchWithSuperview:(UIView *)superview
{
    subview.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(subview);
    
    NSArray *constraints = [NSLayoutConstraint
                            constraintsWithVisualFormat:@"H:|[subview]|"
                            options:0
                            metrics:nil
                            views:viewsDictionary];
    constraints = [constraints arrayByAddingObjectsFromArray:
                   [NSLayoutConstraint
                    constraintsWithVisualFormat:@"V:|[subview]|"
                    options:0
                    metrics:nil
                    views:viewsDictionary]];
    [superview addConstraints:constraints];
    
    return constraints;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // start off by using the front view (Palm trees)
    [self.view addSubview:self.frontView];
    
    // since frontView has no constraints set to match it's superview, we set them here
    _priorConstraints = [self constrainSubview:self.frontView toMatchWithSuperview:self.view];
    
    // configure our toolbar with the appropriate transition effects
    // note: the bounce button only shows for iOS 7.0 or later
    //
    UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSMutableArray *toolbarButtons = [NSMutableArray arrayWithObjects:flexItem, self.fadeButton, self.flipButton, nil];

    if ([[UIView class] respondsToSelector:
         @selector(animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:)])
    {
        [toolbarButtons addObject:self.bounceButton];
    }
    [toolbarButtons addObject:flexItem];
    
    self.toolbarItems = toolbarButtons;
}

- (void)performTransition:(UIViewAnimationOptions)options
{
    UIView *fromView, *toView;
    
    if ([self.frontView superview] != nil)
    {
        fromView = self.frontView;
        toView = self.backView;
    }
    else
    {
        fromView = self.backView;
        toView = self.frontView;
    }
    
    NSArray *priorConstraints = self.priorConstraints;
    [UIView transitionFromView:fromView
                        toView:toView
                      duration:1.0
                       options:options
                    completion:^(BOOL finished) {
                        // animation completed
                        if (priorConstraints != nil)
                        {
                            [self.view removeConstraints:priorConstraints];
                        }
                    }];
    _priorConstraints = [self constrainSubview:toView toMatchWithSuperview:self.view];
}


#pragma mark - Actions

- (IBAction)fadeAction:(id)sender
{
    [self performTransition:UIViewAnimationOptionTransitionCrossDissolve];
}

- (IBAction)flipAction:(id)sender
{
    UIViewAnimationOptions transitionOptions = ([self.frontView superview] != nil) ?
    UIViewAnimationOptionTransitionFlipFromLeft : UIViewAnimationOptionTransitionFlipFromRight;
    
    [self performTransition:transitionOptions];
}

- (IBAction)bounceAction:(id)sender
{
    if ([[UIView class] respondsToSelector:
         @selector(animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:)])
    {
        // no other transitions are allowed until this one finishes
        self.navigationController.toolbar.userInteractionEnabled = NO;
        
        UIView *fromView, *toView;

        if ([self.frontView superview] != nil)
        {
            fromView = self.frontView;
            toView = self.backView;
        }
        else
        {
            fromView = self.backView;
            toView = self.frontView;
        }
        
        CGRect startFrame = self.view.frame;
        CGRect endFrame = self.view.frame;
        
        // the start position is below the bottom of the visible frame
        startFrame.origin.y = -startFrame.size.height;
        endFrame.origin.y = 0;
        
        toView.frame = startFrame;
        
        NSArray *priorConstraints = self.priorConstraints;
        [self.view addSubview:toView];
        [UIView animateWithDuration:1.0f
                              delay:0.0
             usingSpringWithDamping:0.5
              initialSpringVelocity:5.0
                            options:0
                         animations:^{ toView.frame = endFrame; }
                         completion:^(BOOL finished) {
                             // slide down animation finished, remove the older view and the constraints
                             //
                             if (priorConstraints != nil)
                                 [self.view removeConstraints:priorConstraints];
                             [fromView removeFromSuperview];
                             
                             self.navigationController.toolbar.userInteractionEnabled = YES;
                         }];
        
        // apply the new constraints to our newly added subview
        _priorConstraints = [self constrainSubview:toView toMatchWithSuperview:self.view];
    }
}

@end
