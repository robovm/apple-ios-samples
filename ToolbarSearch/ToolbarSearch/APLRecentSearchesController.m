/*
     File: APLRecentSearchesController.m 
 Abstract: A table view controller to manage and display a list of recent search strings.
 The search strings are stored in user defaults to maintain the list between launches of the application.
 The view controller manages two arrays:
 * recentSearches is the array that corresponds to the full set of recent search strings stored in user defaults.
 * displayedRecentSearches is an array derived from recent searches, filtered by the current search string (if any).
 
 The recentSearches array is kept synchronized with user defaults, and avoids the need to query user defaults every time the search string is updated.
 
 The table view displays the contents of the displayedRecentSearches array.
 
 The view controller has a delegate that it notifies if row in the table view is selected.
 
 The view controller's size in the popover is set in the storyboard.
  
  Version: 2.3 
  
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

#import "APLRecentSearchesController.h"

NSString *RecentSearchesKey = @"RecentSearchesKey";

@interface APLRecentSearchesController ()

@property (nonatomic, weak) IBOutlet UIBarButtonItem *clearButtonItem;

@property (nonatomic) NSArray *recentSearches;
@property (nonatomic) NSArray *displayedRecentSearches;
@property (nonatomic, readwrite) UIActionSheet *confirmSheet;

@end

#pragma mark -

@implementation APLRecentSearchesController

#pragma mark - View lifecycle

- (void)viewDidLoad {
    
    [super viewDidLoad];

    // Set up the recent searches list, from user defaults or using an empty array.
    NSArray *recents = [[NSUserDefaults standardUserDefaults] objectForKey:RecentSearchesKey];
    if (recents) {
        self.recentSearches = recents;
        self.displayedRecentSearches = recents;
    }
    else {
        self.recentSearches = [NSArray array];
        self.displayedRecentSearches = [NSArray array];
    }

    // Disable the Clear button if there are no recents items.
    if ([self.recentSearches count] == 0) {
        self.clearButtonItem.enabled = NO;
    }    
}


- (void)viewWillAppear:(BOOL)animated {
 
    // Ensure the complete list of recents is shown on first display.
    [super viewWillAppear:animated];
    self.displayedRecentSearches = self.recentSearches;
}


#pragma mark - Managing the recents list

- (void)addToRecentSearches:(NSString *)searchString {
    
    // Filter out any strings that shouldn't be in the recents list.
    if ([searchString isEqualToString:@""]) {
        return;
    }
    
    // Create a mutable copy of recent searches and remove the search string if it's already there (it's added to the top of the list later).

    NSMutableArray *mutableRecents = [self.recentSearches mutableCopy];
    [mutableRecents removeObject:searchString];
    
    // Add the new string at the top of the list.
    [mutableRecents insertObject:searchString atIndex:0];
    
    // Update user defaults.
    [[NSUserDefaults standardUserDefaults] setObject:mutableRecents forKey:RecentSearchesKey];

    // Set self's recent searches to the new recents array, and reload the table view.
    self.recentSearches = mutableRecents;
    self.displayedRecentSearches = mutableRecents;
    [self.tableView reloadData];
    
    // Ensure the clear button is enabled.
    self.clearButtonItem.enabled = YES;
}


- (void)filterResultsUsingString:(NSString *)filterString {

    // If the search string is zero-length, then restore the recent searches, otherwise
    // create a predicate to filter the recent searches using the search string.
    //
    if ([filterString length] == 0) {
        self.displayedRecentSearches = self.recentSearches;
    }
    else {
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"self BEGINSWITH[cd] %@", filterString];
        NSArray *filteredRecentSearches = [self.recentSearches filteredArrayUsingPredicate:filterPredicate];
        self.displayedRecentSearches = filteredRecentSearches;
    }

    [self.tableView reloadData];
}

- (IBAction)showClearRecentsAlert:(id)sender {
    
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", @"Cancel button title");
    NSString *clearAllRecentsButtonTitle = NSLocalizedString(@"Clear All Recents", @"Clear All Recents button title");
    
    // If the user taps the Clear Recents button, present an action sheet to confirm.
    self.confirmSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:cancelButtonTitle destructiveButtonTitle:clearAllRecentsButtonTitle otherButtonTitles:nil];
    [self.confirmSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 0) {
        /*
         If the user chose to clear recents, remove the recents entry from user defaults, set the list to an empty array, and redisplay the table view.
         */
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:RecentSearchesKey];
        self.recentSearches = [NSArray array];
        self.displayedRecentSearches = [NSArray array];
        [self.tableView reloadData];
        self.clearButtonItem.enabled = NO;
    }
    self.confirmSheet = nil;
}


#pragma mark - Table view methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.displayedRecentSearches count];
}

// Display the strings in displayedRecentSearches.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    cell.textLabel.text = [self.displayedRecentSearches objectAtIndex:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Notify the delegate if a row is selected.
    [self.delegate recentSearchesController:self didSelectString:[self.displayedRecentSearches objectAtIndex:indexPath.row]];
}

@end

