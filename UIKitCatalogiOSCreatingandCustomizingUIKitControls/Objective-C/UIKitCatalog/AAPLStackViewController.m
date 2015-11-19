/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A view controller that demonstrates how to use UIStackView.
*/

#import "AAPLStackViewController.h"

@interface AAPLStackViewController ()

@property (nonatomic, weak) IBOutlet UIStackView *furtherDetailStackView;
@property (nonatomic, weak) IBOutlet UIButton *plusButton;

@end


#pragma mark -

@implementation AAPLStackViewController

#pragma mark - View Life Cycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.furtherDetailStackView.hidden = YES;
    self.plusButton.hidden = NO;
}

#pragma mark - Actions

- (IBAction)showFurtherDetailTapped:(UIButton *)sender {
    // Animate the changes by performing them in a `UIView` animation block.
    [UIView animateWithDuration:0.25 animations:^{
        // Reveal the further details stack view and hide the plus button.
        self.furtherDetailStackView.hidden = NO;
        self.plusButton.hidden = YES;
    }];
}

- (IBAction)hideFurtherDetailTapped:(UIButton *)sender {
    // Animate the changes by performing them in a `UIView` animation block.
    [UIView animateWithDuration:0.25 animations:^{
        // Hide the further details stack view and reveal the plus button.
        self.furtherDetailStackView.hidden = YES;
        self.plusButton.hidden = NO;
    }];
}

@end
