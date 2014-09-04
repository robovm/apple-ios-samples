/*
     File: APLViewController.m
 Abstract: Main table view controller for the application.
  Version: 1.0
 
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

#import "APLViewController.h"
#import "APLProduct.h"
#import "APLDetailViewController.h"

@interface APLViewController ()

// the searchResults array contains the content filtered as a result of a search
@property (nonatomic) NSMutableArray *searchResults;

@end

#pragma mark -

@implementation APLViewController

#pragma mark - Lifecycle methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // create a mutable array to contain products for the search results table
    self.searchResults = [NSMutableArray arrayWithCapacity:[self.products count]];

    // set up the search scope buttons with titles using products' localized display names
    NSMutableArray *scopeButtonTitles = [[NSMutableArray alloc] init];
    [scopeButtonTitles addObject:NSLocalizedString(@"All", @"Title for the All button in the search display controller.")];

    for (NSString *deviceType in [APLProduct deviceTypeNames])
    {
        NSString *displayName = [APLProduct displayNameForType:deviceType];
        [scopeButtonTitles addObject:displayName];
    }

    self.searchDisplayController.searchBar.scopeButtonTitles = scopeButtonTitles;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // check for our segue identifier
    if ([segue.identifier isEqualToString:@"pushDetailView"])
    {
        // sender is the table view cell
        NSArray *sourceArray;
        NSIndexPath *indexPath = [self.searchDisplayController.searchResultsTableView indexPathForCell:(UITableViewCell *)sender];
        if (indexPath != nil)
        {
            sourceArray = self.searchResults;
        }
        else
        {
            indexPath = [self.tableView indexPathForCell:(UITableViewCell *)sender];
            sourceArray = self.products;
        }

        // prepare our detail view controller with new content
        APLDetailViewController *destinationController = segue.destinationViewController;
        
        APLProduct *product = sourceArray[indexPath.row];
        destinationController.title = product.name;
        
        // pass the price and year as a formatted string
        NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
        [numFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        NSString *priceStr = [numFormatter stringFromNumber:product.introPrice];
        NSString *productInfo = [NSString stringWithFormat:@"%@ - %@", priceStr, [product.yearIntroduced stringValue]];
        destinationController.productInfo = productInfo;
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// If the requesting table view is the search display controller's table view,
    // return the count of the filtered list, otherwise return the count of the main list/
    //
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
        return [self.searchResults count];
    }
	else
	{
        return [self.products count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *kCellID = @"CellIdentifier";

    // dequeue a cell from self's table view
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kCellID];

    // If the requesting table view is the search display controller's table view, configure
    // the cell using the search results array, otherwise use the product array.
    //
	APLProduct *product;
    
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
        product = [self.searchResults objectAtIndex:indexPath.row];
    }
	else
	{
        product = [self.products objectAtIndex:indexPath.row];
    }

    cell.textLabel.text = product.name;
    
    // build the price and year string
    //
    // use NSNumberFormatter to get the currency format out of this NSNumber (product.introPrice)
    NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
    [numFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    NSString *priceStr = [numFormatter stringFromNumber:product.introPrice];
    
    NSString *detailedStr = [NSString stringWithFormat:@"%@ | %@", priceStr, [product.yearIntroduced stringValue]];
    NSMutableAttributedString *attribStr = [[NSMutableAttributedString alloc] initWithString:detailedStr];
    // make the vertical separator line light gray
    NSRange foundRange = [detailedStr rangeOfString:@"|"];
    [attribStr addAttribute:NSForegroundColorAttributeName
                      value:[UIColor lightGrayColor]
                      range:NSMakeRange(foundRange.location, 1)];
    cell.detailTextLabel.attributedText = attribStr;
    
	return cell;
}


#pragma mark - Content Filtering

- (void)updateFilteredContentForSearchString:(NSString *)searchString productType:(NSString *)type
{
    // start out with the entire list
    self.searchResults = [self.products mutableCopy];
    
    // strip out all the leading and trailing spaces
    NSString *strippedStr = [searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // break up the search terms (separated by spaces)
    NSArray *searchItems = nil;
    if (strippedStr.length > 0)
    {
        searchItems = [strippedStr componentsSeparatedByString:@" "];
    }
    
    // build all the "AND" expressions for each value in the searchString
    //
    NSMutableArray *andMatchPredicates = [NSMutableArray array];
    
    for (NSString *searchString in searchItems)
    {
        // each searchString creates an OR predicate for: name, yearIntroduced, introPrice
        //
        // example if searchItems contains "iphone 599 2007":
        //      name CONTAINS[c] "iphone"
        //      name CONTAINS[c] "599", yearIntroduced ==[c] 599, introPrice ==[c] 599
        //      name CONTAINS[c] "2007", yearIntroduced ==[c] 2007, introPrice ==[c] 2007
        //
        NSMutableArray *searchItemsPredicate = [NSMutableArray array];
        
        // name field matching
        NSExpression *lhs = [NSExpression expressionForKeyPath:@"name"];
        NSExpression *rhs = [NSExpression expressionForConstantValue:searchString];
        NSPredicate *finalPredicate = [NSComparisonPredicate
                                       predicateWithLeftExpression:lhs
                                       rightExpression:rhs
                                       modifier:NSDirectPredicateModifier
                                       type:NSContainsPredicateOperatorType
                                       options:NSCaseInsensitivePredicateOption];
        [searchItemsPredicate addObject:finalPredicate];
        
        // yearIntroduced field matching
        NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
        [numFormatter setNumberStyle:NSNumberFormatterNoStyle];
        NSNumber *targetNumber = [numFormatter numberFromString:searchString];
        if (targetNumber != nil)    // (searchString may not convert to a number)
        {
            lhs = [NSExpression expressionForKeyPath:@"yearIntroduced"];
            rhs = [NSExpression expressionForConstantValue:targetNumber];
            finalPredicate = [NSComparisonPredicate
                              predicateWithLeftExpression:lhs
                              rightExpression:rhs
                              modifier:NSDirectPredicateModifier
                              type:NSEqualToPredicateOperatorType
                              options:NSCaseInsensitivePredicateOption];
            [searchItemsPredicate addObject:finalPredicate];
            
            // price field matching
            lhs = [NSExpression expressionForKeyPath:@"introPrice"];
            rhs = [NSExpression expressionForConstantValue:targetNumber];
            finalPredicate = [NSComparisonPredicate
                              predicateWithLeftExpression:lhs
                              rightExpression:rhs
                              modifier:NSDirectPredicateModifier
                              type:NSEqualToPredicateOperatorType
                              options:NSCaseInsensitivePredicateOption];
            [searchItemsPredicate addObject:finalPredicate];
        }
        
        // at this OR predicate to our master AND predicate
        NSCompoundPredicate *orMatchPredicates = (NSCompoundPredicate *)[NSCompoundPredicate orPredicateWithSubpredicates:searchItemsPredicate];
        [andMatchPredicates addObject:orMatchPredicates];
    }
    
    NSCompoundPredicate *finalCompoundPredicate = nil;
    
    if (type != nil)
    {
        // we have a scope type to narrow our search further
        //
        if (andMatchPredicates.count > 0)
        {
            // we have a scope type and other fields to search on -
            // so match up the fields of the Product object AND its product type
            //
            NSCompoundPredicate *compPredicate1 =
                (NSCompoundPredicate *)[NSCompoundPredicate andPredicateWithSubpredicates:andMatchPredicates];
            NSPredicate *compPredicate2 = [NSPredicate predicateWithFormat:@"(SELF.type == %@)", type];
            
            finalCompoundPredicate =
                (NSCompoundPredicate *)[NSCompoundPredicate andPredicateWithSubpredicates:@[compPredicate1, compPredicate2]];
        }
        else
        {
            // match up by product scope type only
            finalCompoundPredicate =
                (NSCompoundPredicate *)[NSPredicate predicateWithFormat:@"(SELF.type == %@)", type];
        }
    }
    else
    {
        // no scope type specified, just match up the fields of the Product object
        finalCompoundPredicate =
            (NSCompoundPredicate *)[NSCompoundPredicate andPredicateWithSubpredicates:andMatchPredicates];
    }
    
    self.searchResults = [[self.searchResults filteredArrayUsingPredicate:finalCompoundPredicate] mutableCopy];
}


#pragma mark - UISearchDisplayDelegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    NSString *scope;

    NSInteger selectedScopeButtonIndex = [self.searchDisplayController.searchBar selectedScopeButtonIndex];
    if (selectedScopeButtonIndex > 0)
    {
        scope = [[APLProduct deviceTypeNames] objectAtIndex:(selectedScopeButtonIndex - 1)];
    }

    [self updateFilteredContentForSearchString:searchString productType:scope];

    // return YES to cause the search result table view to be reloaded
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    NSString *searchString = [self.searchDisplayController.searchBar text];
    NSString *scope;

    if (searchOption > 0)
    {
        scope = [[APLProduct deviceTypeNames] objectAtIndex:(searchOption - 1)];
    }

    [self updateFilteredContentForSearchString:searchString productType:scope];

    // return YES to cause the search result table view to be reloaded
    return YES;
}


#pragma mark - State restoration

// Note:
// UITableView itself supports current scroll position and selected row if its data source
// supports UIDataSourceModeAssociation protocol.
//
// To make things simpler here, we choose to manually preserve/restore the table view selection
// and not support scroll position.

static NSString *SearchDisplayControllerIsActiveKey = @"SearchDisplayControllerIsActiveKey";
static NSString *SearchBarScopeIndexKey = @"SearchBarScopeIndexKey";
static NSString *SearchBarTextKey = @"SearchBarTextKey";
static NSString *SearchBarIsFirstResponderKey = @"SearchBarIsFirstResponderKey";

static NSString *SearchDisplayControllerSelectedRowKey = @"SearchDisplayControllerSelectedRowKey";
static NSString *TableViewSelectedRowKey = @"TableViewSelectedRowKey";


- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];

    UISearchDisplayController *searchDisplayController = self.searchDisplayController;
    
    BOOL searchDisplayControllerIsActive = [searchDisplayController isActive];
    [coder encodeBool:searchDisplayControllerIsActive forKey:SearchDisplayControllerIsActiveKey];
    
    if (searchDisplayControllerIsActive)
    {
        [coder encodeObject:[searchDisplayController.searchBar text] forKey:SearchBarTextKey];
        [coder encodeInteger:[searchDisplayController.searchBar selectedScopeButtonIndex] forKey:SearchBarScopeIndexKey];

        NSIndexPath *selectedIndexPath = [searchDisplayController.searchResultsTableView indexPathForSelectedRow];
        if (selectedIndexPath != nil)
        {
            [coder encodeObject:selectedIndexPath forKey:SearchDisplayControllerSelectedRowKey];
        }

        BOOL searchFieldIsFirstResponder = [searchDisplayController.searchBar isFirstResponder];
        [coder encodeBool:searchFieldIsFirstResponder forKey:SearchBarIsFirstResponderKey];
    }

    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath != nil)
    {
        [coder encodeObject:selectedIndexPath forKey:TableViewSelectedRowKey];
    }
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];

    BOOL searchDisplayControllerIsActive = [coder decodeBoolForKey:SearchDisplayControllerIsActiveKey];

    if (searchDisplayControllerIsActive)
    {
        [self.searchDisplayController setActive:YES];

        // order is important here. Setting the search bar text causes
        // searchDisplayController:shouldReloadTableForSearchString: to be invoked.
        //
        NSInteger searchBarScopeIndex = [coder decodeIntegerForKey:SearchBarScopeIndexKey];
        [self.searchDisplayController.searchBar setSelectedScopeButtonIndex:searchBarScopeIndex];

        NSString *searchBarText = [coder decodeObjectForKey:SearchBarTextKey];
        if (searchBarText != nil)
        {
            [self.searchDisplayController.searchBar setText:searchBarText];
        }

        NSIndexPath *selectedIndexPath = [coder decodeObjectForKey:SearchDisplayControllerSelectedRowKey];
        if (selectedIndexPath != nil)
        {
            [self.searchDisplayController.searchResultsTableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
        }

        BOOL searchFieldIsFirstResponder = [coder decodeBoolForKey:SearchBarIsFirstResponderKey];
        if (searchFieldIsFirstResponder)
        {
            [self.searchDisplayController.searchBar becomeFirstResponder];
        }
    }
    
    NSIndexPath *selectedIndexPath = [coder decodeObjectForKey:TableViewSelectedRowKey];
    if (selectedIndexPath != nil)
    {
        [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
    }
}

@end

