/*
 
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A custom UITableViewCell that contains a Checkbox control in addition to its accessory control.
 
 */

#import "Checkbox.h"

@interface CustomCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *priority;
@property (weak, nonatomic) IBOutlet UILabel *dateAndFrequency;
@property (weak, nonatomic) IBOutlet Checkbox *checkBox;

@end
