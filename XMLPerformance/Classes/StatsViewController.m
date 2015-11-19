/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Displays statistics about each parser, including its average time to download the XML data, parse it, and the total average time from beginning the download to completing the parse.
 */


#import "StatsViewController.h"
#import "Statistics.h"
#import "CocoaXMLParser.h"
#import "LibXMLParser.h"


#pragma mark -

@implementation StatsViewController


- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // We use a slightly shorter than usual row height so that all the statistics fit on the page without scrolling.
    // This should be used cautiously, as it can easily result in a user interface that provides a bad experience. It is
    // acceptable here partly because the table does not support any user interaction.
    // 
    // This could also be achieved using the UITableViewDelegate method tableView:heightForRowAtIndexPath:
    // However, this comes with a performance penalty, as it is called for each row in the table. Unless the rows
    // need to be of varying heights, the rowHeight property should be used.
    //
    self.tableView.allowsSelection = NO;
    self.tableView.rowHeight = 31;
    
    // Set the title
    self.title = @"Statistics";
}

- (void)viewDidUnload {
    
    self.tableView = nil;
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *kStatisticsCellID = @"StatisticsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kStatisticsCellID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kStatisticsCellID];
    }
    switch (indexPath.row) {
        case 0: {
            cell.textLabel.text = NSLocalizedString(@"Mean Download Time", @"Mean Download Time format");
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.4fs", MeanDownloadTimeForParserType((XMLParserType)indexPath.section)];
        } break;
        case 1: {
            cell.textLabel.text = NSLocalizedString(@"Mean Parse Time", @"Mean Parse Time format");
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.4fs", MeanParseTimeForParserType((XMLParserType)indexPath.section)];
        } break;
        case 2: {
            cell.textLabel.text = NSLocalizedString(@"Mean Total Time", @"Mean Total Time format");
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.4fs", MeanTotalTimeForParserType((XMLParserType)indexPath.section)];
        } break;
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section {
    
    NSUInteger numberOfRuns = NumberOfRunsForParserType((int)section);
    NSString *parserName = (section == 0) ? [CocoaXMLParser parserName] : [LibXMLParser parserName];
    NSString *format = (numberOfRuns == 1) ? NSLocalizedString(@"%@ (%d run):", @"One Run format") : NSLocalizedString(@"%@ (%d runs):", @"Multiple Runs format");
    return [NSString stringWithFormat:format, parserName, numberOfRuns];
}

// action method for the button that resets statistics
- (IBAction)resetStatistics:(id)sender {
    
    ResetStatisticsDatabase();
    [self.tableView reloadData];
}

@end
