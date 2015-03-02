/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Test view controller parent for implementing test pages in the test application.
  
 */

@import UIKit;

@interface AAPLBasicTestViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic)  NSArray *tests;

-(void)printResult:(UITextView*)textView message:(NSString*)msg;

@end
