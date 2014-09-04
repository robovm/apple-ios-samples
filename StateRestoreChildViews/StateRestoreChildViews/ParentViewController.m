/*
     File: ParentViewController.m
 Abstract: The sample's primary/parent view controller
  Version: 1.1
 
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

#import "ParentViewController.h"
#import "Child1ViewController.h"
#import "Child2ViewController.h"

@interface ParentViewController ()

@property (nonatomic, strong) IBOutlet UIView *placeholderView;
@property (nonatomic, strong) IBOutlet UISegmentedControl *segControl;

@property (nonatomic, strong) Child1ViewController *child1;
@property (nonatomic, strong) Child2ViewController *child2;

@end

@implementation ParentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationController.navigationBar.translucent = NO;
    
    // create and add our two children view controllers from our storyboard
    self.child1 = [self.storyboard instantiateViewControllerWithIdentifier:@"child1"];
    [self addChildViewController:self.child1];
    [self.child1 didMoveToParentViewController:self];
    
    self.child2 = [self.storyboard instantiateViewControllerWithIdentifier:@"child2"];
    [self addChildViewController:self.child2];
    [self.child2 didMoveToParentViewController:self];
    
    // by default child1 should be visible
    // (note that later, UIStateRestoriation might change this)
    //
    [self addChild:self.child1 withChildToRemove:nil];
}

- (void)addChild:(UIViewController *)childToAdd withChildToRemove:(UIViewController *)childToRemove
{
    assert(childToAdd != nil);
    
    if (childToRemove != nil)
    {
        [childToRemove.view removeFromSuperview];
    }
    
    // match the child size to its parent
    CGRect frame = childToAdd.view.frame;
    frame.size.height = CGRectGetHeight(self.placeholderView.frame);
    frame.size.width = CGRectGetWidth(self.placeholderView.frame);
    childToAdd.view.frame = frame;
    
    [self.placeholderView addSubview:childToAdd.view];
}

// user tapped on the segmented control to choose which child is to be visible
- (IBAction)segmentControlAction:(id)sender
{
    UISegmentedControl *segControl = (UISegmentedControl *)sender;
    
    UIViewController *childToAdd, *childToRemove;
    
    childToAdd = (segControl.selectedSegmentIndex == 0) ? self.child1 : self.child2;
    childToRemove = (segControl.selectedSegmentIndex == 0) ? self.child2 : self.child1;
    
    [self addChild:childToAdd withChildToRemove:childToRemove];
}


#pragma mark - UIStateRestoration

// encodeRestorableStateWithCoder is called when the app is suspended to the background
- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    NSLog(@"ParentViewController: encodeRestorableStateWithCoder");
    
    // remember our children view controllers
    [coder encodeObject:self.child1 forKey:@"child1"];
    [coder encodeObject:self.child2 forKey:@"child2"];
    
    // remember the segmented control state
    [coder encodeInteger:self.segControl.selectedSegmentIndex forKey:@"selectedIndex"];
    
    [super encodeRestorableStateWithCoder:coder];
}

// decodeRestorableStateWithCoder is called when the app is re-launched
- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    NSLog(@"ParentViewController: decodeRestorableStateWithCoder");
    
    // find out which child was the current visible view controller
    self.segControl.selectedSegmentIndex = [coder decodeIntegerForKey:@"selectedIndex"];
    
    // call our segmented control to set the right visible child
    // (note that we already previously have already loaded both children view controllers in viewDidLoad)
    //
    [self segmentControlAction:self.segControl];
    
    [super decodeRestorableStateWithCoder:coder];
}

@end
