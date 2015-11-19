/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Provides an interface for choosing and running one of the two available parsers.
 */

#import "ParserChoiceViewController.h"
#import "SongsViewController.h"
#import "LibXMLParser.h"
#import "CocoaXMLParser.h"

@interface ParserChoiceViewController ()

@property (nonatomic, strong) UINavigationController *songsNavigationController;
@property (nonatomic, strong) SongsViewController *songsViewController;
@property (nonatomic, strong) NSIndexPath *parserSelection;

@end

#pragma mark -

@implementation ParserChoiceViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // Set the title
    self.title = @"Parsers";
    
    // set an initial parser selection
    self.parserSelection = [NSIndexPath indexPathForRow:0 inSection:0];
    
    _songsViewController = [[SongsViewController alloc] initWithStyle:UITableViewStylePlain];
    _songsNavigationController = [[UINavigationController alloc] initWithRootViewController:self.songsViewController];
}

- (IBAction)startParser:(id)sender {
    [self.navigationController presentViewController:self.songsNavigationController animated:YES completion:^{[self animationCompleted];}];
}

- (void)animationCompleted {
    [self.songsViewController parseWithParserType:(int)self.parserSelection.row];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
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
