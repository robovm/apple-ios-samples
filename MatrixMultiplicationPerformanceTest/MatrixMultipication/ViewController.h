/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 View Controller
 */

#import <UIKit/UIKit.h>


@interface ViewController : UIViewController<UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView*     texts;
@property (weak, nonatomic) IBOutlet UIProgressView* progress;
@property (weak, nonatomic) IBOutlet UITextField*    count;
@property (weak, nonatomic) IBOutlet UITextField*    percent;

@end
