/*
     File: RootViewController.m
 Abstract: The view controller displays what each icon does on iOS.
  Version: 1.2
 
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
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import "RootViewController.h"

#define kTopBottomMargins 20

NSString * const kIconName = @"IconName";
NSString * const kIconDescription = @"IconDescription";
NSString * const kIconCellHeight = @"kIconCellHeight";


@interface RootViewController ()
//! Icon information.
@property (nonatomic, strong) NSArray *icons;
@end


@implementation RootViewController

//| ----------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.icons = @[
                   @{kIconName: @"Icon-60@2x",
                     kIconDescription: @"Home screen on iPhone/iPod Touch with retina display (iOS 7)",
                     kIconCellHeight: @(60)},
                   
                   @{kIconName: @"Icon-76",
                     kIconDescription: @"Home screen on iPad (iOS 7)",
                     kIconCellHeight: @(76)},
                   
                   @{kIconName: @"Icon-76@2x",
                     kIconDescription: @"Home screen on iPad with retina display (iOS 7)",
                     kIconCellHeight: @(76)},
                   
                   @{kIconName: @"Icon-Small-40",
                     kIconDescription: @"Spotlight (iOS 7)",
                     kIconCellHeight: @(40)},
                   
                   @{kIconName: @"Icon-Small-40@2x",
                     kIconDescription: @"Spotlight on devices with retina display (iOS 7)",
                     kIconCellHeight: @(40)},
                   
                   @{kIconName: @"Icon-Small",
                     kIconDescription: @"Spotlight on iPhone/iPod Touch (iOS 6.1 and earlier) and Settings",
                     kIconCellHeight: @(40)},
                   
                   @{kIconName: @"Icon-Small@2x",
                     kIconDescription: @"Spotlight on iPhone/iPod Touch with retina display (iOS 6.1 and earlier) and Settings on devices with retina display",
                     kIconCellHeight: @(75)},
                   
                   @{kIconName: @"Icon",
                     kIconDescription: @"Home screen on iPhone/iPod touch (iOS 6.1 and earlier)",
                     kIconCellHeight: @(57)},
                   
                   @{kIconName: @"Icon@2x",
                     kIconDescription: @"Home screen on iPhone/iPod Touch with retina display (iOS 6.1 and earlier)",
                     kIconCellHeight: @(57)},
                   
                   @{kIconName: @"Icon-72",
                     kIconDescription: @"Home screen on iPad (iOS 6.1 and earlier)",
                     kIconCellHeight: @(72)},
                   
                   @{kIconName: @"Icon-72@2x",
                     kIconDescription: @"Home screen on iPad with retina display (iOS 6.1 and earlier)",
                     kIconCellHeight: @(72)},
                   
                   @{kIconName: @"Icon-Small-50",
                     kIconDescription: @"Spotlight on iPad (iOS 6.1 and earlier)",
                     kIconCellHeight: @(50)},
                   
                   @{kIconName: @"Icon-Small-50@2x",
                     kIconDescription: @"Spotlight on iPad with retina display (iOS 6.1 and earlier)",
                     kIconCellHeight: @(50)},
                   ];
}

#pragma mark -
#pragma mark UITableViewDelegate

//| ----------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.icons[indexPath.row][kIconCellHeight] floatValue] + kTopBottomMargins;
}

#pragma mark -
#pragma mark UITableViewDataSource

//| ----------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.icons.count;
}


//| ----------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellID" forIndexPath:indexPath];
    
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    NSString *iconName = self.icons[indexPath.row][kIconName];
    NSString *iconPath = [[NSBundle mainBundle] pathForResource:iconName ofType:@"png"];
    BOOL isRetina = [iconName rangeOfString:@"@2x"].location != NSNotFound;
    
    cell.imageView.image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfFile:iconPath] scale:(isRetina ? 2 : 1)];
    cell.textLabel.text = [iconName stringByAppendingString:@".png"];
	cell.detailTextLabel.text = self.icons[indexPath.row][kIconDescription];
    
	return cell;
}

@end
