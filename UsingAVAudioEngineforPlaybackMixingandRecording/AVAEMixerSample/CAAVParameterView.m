/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This subclass of UIView holds the various UIElemets for interfacing with the AudioEngine. It also implements a gesture recognizer to dismiss the view
*/

#import "CAAVParameterView.h"

@implementation CAAVParameterView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRecognizer:)];
        swipe.direction = UISwipeGestureRecognizerDirectionDown;
        [self addGestureRecognizer:swipe];
    }
    
    return self;
}

//swipe down to dismiss the controller
- (void)swipeRecognizer:(UISwipeGestureRecognizer *)sender {
    if (self.presentedController) {
        [self.presentedController dismissViewControllerAnimated:YES completion:nil];
        self.presentedController = nil;
    }
}

@end
