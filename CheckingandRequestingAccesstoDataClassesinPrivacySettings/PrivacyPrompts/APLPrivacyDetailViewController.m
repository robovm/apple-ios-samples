/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 View controller that handles checking and requesting access to the users private data classes.
 */

#import "APLPrivacyDetailViewController.h"

@implementation APLPrivacyDetailViewController

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(self.checkBlock && self.requestBlock) {
        return 2;
    }
    
    if(self.checkBlock || self.requestBlock) {
        return 1;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActionCell" forIndexPath:indexPath];
    
    NSInteger num = [tableView numberOfRowsInSection:indexPath.section];
    if(num == 2) {
        if(indexPath.row == 0) {
            [[cell textLabel] setText:NSLocalizedString(@"CHECK_ACCESS", @"")];
        }
        if(indexPath.row == 1) {
            [[cell textLabel] setText:NSLocalizedString(@"REQUEST_ACCESS", @"")];
        }
    }
    else if(num == 1) {
        if(self.checkBlock) {
            [[cell textLabel] setText:NSLocalizedString(@"CHECK_ACCESS", @"")];
        }
        else if(self.requestBlock) {
            [[cell textLabel] setText:NSLocalizedString(@"REQUEST_ACCESS", @"")];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger rowsInSection = [tableView numberOfRowsInSection:indexPath.section];
    if(rowsInSection == 2) {
        if(indexPath.row == 0) {
            if(self.checkBlock) {
                self.checkBlock();
            }
        }
        if(indexPath.row == 1) {
            if(self.requestBlock) {
                self.requestBlock();
            }
        }
    }
    else if(rowsInSection == 1) {
        if(self.checkBlock) {
            if(self.checkBlock) {
                self.checkBlock();
            }
        }
        else if(self.requestBlock) {
            if(self.requestBlock) {
                self.requestBlock();
            }
        }
    }
}

@end
