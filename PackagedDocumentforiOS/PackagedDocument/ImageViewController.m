/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The view controller used for displaying the image portion of "NotesDocument".
 */

#import "ImageViewController.h"

@interface ImageViewController ()

@property (nonatomic, strong) IBOutlet UIImageView *imageView;

@end


#pragma mark -

@implementation ImageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.imageView.image = self.image;
}

@end
