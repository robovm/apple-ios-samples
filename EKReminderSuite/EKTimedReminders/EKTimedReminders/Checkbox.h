/*
 
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A UIControl subclass that implements a checkbox.
 
 */

@interface Checkbox : UIControl

// State of the checkbox
@property (nonatomic, readwrite, getter = isChecked) BOOL checked;

@end

