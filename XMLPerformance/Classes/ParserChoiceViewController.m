/*
     File: ParserChoiceViewController.m
 Abstract: Provides an interface for choosing and running one of the two available parsers.
  Version: 1.4
 
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

#import "ParserChoiceViewController.h"
#import "SongsViewController.h"
#import "LibXMLParser.h"
#import "CocoaXMLParser.h"

@interface ParserChoiceViewController ()

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UINavigationController *songsNavigationController;
@property (nonatomic, strong) SongsViewController *songsViewController;
@property (nonatomic, strong) NSIndexPath *parserSelection;

@end

#pragma mark -

@implementation ParserChoiceViewController

- (void)viewDidLoad {
    
    // set an initial parser selection
    self.parserSelection = [NSIndexPath indexPathForRow:0 inSection:0];
    
    _songsViewController = [[SongsViewController alloc] initWithStyle:UITableViewStylePlain];
    _songsNavigationController = [[UINavigationController alloc] initWithRootViewController:self.songsViewController];
    
    // place the start button in the table's footer view
    //
    // first create the header view
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectZero];
    footerView.backgroundColor = [UIColor clearColor];
    UIButton *startButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [startButton setTitle:@"Start" forState:UIControlStateNormal];
    [startButton addTarget:self action:@selector(startParser:) forControlEvents:UIControlEventTouchUpInside];
    [startButton sizeToFit];
    startButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [footerView addSubview:startButton];
    CGRect newFrame = footerView.frame;
    newFrame.size.height = startButton.frame.size.height;
    footerView.frame = newFrame;
    self.tableView.tableFooterView = footerView;
    
    // now center the button within the header view
    newFrame = startButton.frame;
    newFrame.origin.x = (footerView.frame.size.width - newFrame.size.width) / 2;
    newFrame.origin.y = 8.0;
    startButton.frame = newFrame;
}

- (IBAction)startParser:(id)sender {
    
    [self.navigationController presentModalViewController:self.songsNavigationController animated:YES];
    [self.songsViewController parseWithParserType:self.parserSelection.row];
}


#pragma mark - UITableViewDataSource

- (NSUInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSUInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString * const kCellIdentifier = @"MyCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
    }
    cell.textLabel.text = (indexPath.row == 0) ? [CocoaXMLParser parserName] : [LibXMLParser parserName];
    cell.accessoryType = ([indexPath isEqual:self.parserSelection]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    self.parserSelection = indexPath;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView reloadData];
}

@end
